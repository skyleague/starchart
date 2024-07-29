import type { IAM } from '@aws-sdk/client-iam'
import type { FunctionConfiguration, Lambda } from '@aws-sdk/client-lambda'

export interface LambdaFunction {
    configuration: FunctionConfiguration
    tags: { [key: string]: string }
}
export async function patchDebugFunction({
    fn,
    lambda,
    iam,
    debugZip,
    codeSha256,
}: { fn: LambdaFunction; lambda: Lambda; iam: IAM; debugZip: Uint8Array; codeSha256: string }) {
    if (codeSha256 !== fn.configuration.CodeSha256) {
        await lambda.updateFunctionCode({
            // biome-ignore lint/style/noNonNullAssertion: This is a debug function, so we can assume the configuration is present
            FunctionName: fn.configuration.FunctionName!,
            ZipFile: debugZip,
        })
    }

    await iam.putRolePolicy({
        // biome-ignore lint/style/noNonNullAssertion: <explanation>
        RoleName: fn.configuration.Role!.split('/').pop()!,
        PolicyName: '.localdebug',
        PolicyDocument: JSON.stringify({
            Version: '2012-10-17',
            Statement: [
                {
                    Effect: 'Allow',
                    Action: [
                        'iot:DescribeEndpoint',
                        'iot:Connect',
                        'iot:Subscribe',
                        'iot:Publish',
                        'iot:RetainPublish',
                        'iot:Receive',
                    ],
                    Resource: '*',
                },
            ],
        }),
    })
}
