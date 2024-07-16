import { IoT } from '@aws-sdk/client-iot'
import { fromNodeProviderChain } from '@aws-sdk/credential-providers'
import { type Either, isLeft, memoize } from '@skyleague/axioms'
import { iot, mqtt } from 'aws-iot-device-sdk-v2'
import type { Handler } from 'aws-lambda'

const endpoint = memoize(async () => {
    const _iot = new IoT({})
    const { endpointAddress } = await _iot.describeEndpoint({ endpointType: 'iot:Data-ATS' })
    // biome-ignore lint/style/noNonNullAssertion: This is a debug function, so we can assume the endpointAddress is present
    return endpointAddress!
})

export const proxyHandler = () => {
    let client: mqtt.MqttClient | null = null
    let connection: mqtt.MqttClientConnection | null = null

    const setupConnection = async () => {
        if (client && connection) {
            return { client, connection }
        }

        const creds = await fromNodeProviderChain()()
        const config = iot.AwsIotMqttConnectionConfigBuilder.new_builder_for_websocket()
            .with_clean_session(true)
            .with_client_id(`lambda-${Date.now()}`)
            .with_endpoint(await endpoint())
            .with_credentials('eu-west-1', creds.accessKeyId, creds.secretAccessKey, creds.sessionToken)
            .build()

        client = new mqtt.MqttClient()
        connection = client.new_connection(config)

        connection.on('connect', () => {
            console.log('MQTT connection established')
        })

        connection.on('disconnect', () => {
            console.log('MQTT connection disconnected')
        })

        await connection.connect()
        return { client, connection }
    }

    const handler: Handler = async (event, context) => {
        const { connection } = await setupConnection()
        const requestId = context.awsRequestId

        const ackPromise = new Promise<boolean>((resolve) => {
            connection.subscribe(`/lambda/${context.functionName}/${requestId}/ack`, 1, (_topic, _payload) => {
                console.log('Received ACK')
                resolve(true)
            })
        })

        const resultPromise = new Promise<Either<unknown, unknown>>((resolve) => {
            connection.subscribe(`/lambda/${context.functionName}/${requestId}/result`, 1, (_topic, payload) => {
                console.log('Received result', { payload })
                const _payload = JSON.parse(Buffer.from(payload).toString())
                resolve(_payload)
            })
        })

        await connection.publish(`/lambda/${context.functionName}/events`, JSON.stringify({ requestId, event, context }), 1, true)
        console.log('Published event')

        const ackTimeout = new Promise<boolean>((resolve) => setTimeout(() => resolve(false), 3000))
        const hasLocalConnection = await Promise.race([ackPromise, ackTimeout])

        if (!hasLocalConnection) {
            console.log('No local connection available, proceeding with normal Lambda execution')
            return {}
        }

        const resultTimeout = new Promise<Either<unknown, unknown>>((resolve) =>
            setTimeout(() => resolve({ left: 'Timeout waiting for result' }), 60000),
        )
        const _result = await Promise.race([resultPromise, resultTimeout])

        console.log('Result', { _result })

        await connection.unsubscribe(`/lambda/${context.functionName}/${requestId}/ack`)
        await connection.unsubscribe(`/lambda/${context.functionName}/${requestId}/result`)

        if (isLeft(_result)) {
            throw _result.left
        }
        return _result.right
    }

    return handler
}
