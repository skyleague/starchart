import { fork } from 'node:child_process'
import { randomUUID } from 'node:crypto'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { IoT } from '@aws-sdk/client-iot'
import { fromNodeProviderChain } from '@aws-sdk/credential-providers'
import { memoize } from '@skyleague/axioms'
import { iot, mqtt } from 'aws-iot-device-sdk-v2'
import pinoPretty from 'pino-pretty'
import { rootDirectory } from '../../lib/constants.js'
import type { LambdaFunction } from './function.js'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

const endpoint = memoize(async () => {
    const _iot = new IoT({})
    const { endpointAddress } = await _iot.describeEndpoint({ endpointType: 'iot:Data-ATS' })
    // biome-ignore lint/style/noNonNullAssertion: This is a debug function, so we can assume the endpointAddress is present
    return endpointAddress!
})

const pretty = () =>
    pinoPretty({
        translateTime: 'SYS:standard',
        ignore: 'pid,hostname',
        messageKey: 'message',
        timestampKey: 'timestamp',
    })

export async function local(functions: LambdaFunction[]) {
    const clientId = randomUUID()
    const creds = await fromNodeProviderChain()()
    const config = iot.AwsIotMqttConnectionConfigBuilder.new_builder_for_websocket()
        .with_clean_session(true)
        .with_client_id(clientId)
        .with_endpoint(await endpoint())
        .with_credentials('eu-west-1', creds.accessKeyId, creds.secretAccessKey, creds.sessionToken)
        .build()

    const client = new mqtt.MqttClient()
    const connection = client.new_connection(config)

    connection.on('connect', async (_sessionPresent) => {
        // console.log({ sessionPresent }, 'Connected locally')

        await Promise.all(
            functions.map(async (f) => {
                const env = {
                    ...process.env,
                    ...f.configuration.Environment?.Variables,
                    IS_DEBUG: '1',
                    NODE_OPTIONS: `${process.env.NODE_OPTIONS} ${f.configuration.Environment?.Variables?.NODE_OPTIONS ?? ''}`,
                }

                const child = fork(path.resolve(__dirname, 'handler.js'), [], {
                    env,
                    stdio: 'pipe',
                })

                child.stdout?.pipe(pretty())
                child.stderr?.pipe(pretty())

                await connection.subscribe(`/lambda/${f.configuration.FunctionName ?? ''}/events`, 1, async (_topic, payload) => {
                    const { requestId, event, context } = JSON.parse(Buffer.from(payload).toString())

                    await connection.publish(
                        `/lambda/${f.configuration.FunctionName ?? ''}/${requestId}/ack`,
                        JSON.stringify({ ack: true }),
                        1,
                    )

                    child.send({ lambdaFn: f, event, context, rootDirectory })

                    child.on('message', (response) => {
                        connection.publish(
                            `/lambda/${f.configuration.FunctionName ?? ''}/${requestId}/result`,
                            JSON.stringify(response),
                            1,
                        )
                    })
                })

                // console.log({ functionName: f.configuration.FunctionName }, 'Subscribed to function events')
            }),
        )
    })

    connection.on('disconnect', () => {
        console.log('Disconnected locally')
    })

    connection.connect()
}
