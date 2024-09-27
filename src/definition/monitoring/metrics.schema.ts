import { $boolean, $number, $object, type Node } from '@skyleague/therefore'

export const anomalyMetric = $object({
    enabled: $boolean(),
    evaluationPeriods: $number(),
    datapointsToAlarm: $number(),
    bandWidthStandardDeviations: $number(),
    metricPeriod: $number(),
}).partial()

export const staticMetric = $object({
    enabled: $boolean(),
    threshold: $number(),
    period: $number(),
    evaluationPeriods: $number(),
}).partial()

const toMetric = <T extends Node>(metric: T) =>
    $object({
        average: metric,
        sum: metric,
        minimum: metric,
        maximum: metric,
        sampleCount: metric,
        iqm: metric,

        p80: metric,
        tm80: metric,
        tc80: metric,
        wm80: metric,

        p90: metric,
        tm90: metric,
        tc90: metric,
        wm90: metric,

        p95: metric,
        tm95: metric,
        tc95: metric,
        wm95: metric,

        p99: metric,
        tm99: metric,
        tc99: metric,
        wm99: metric,
    }).partial()

export const defaultMetric = $object({
    static: toMetric(staticMetric),
    anomaly: toMetric(anomalyMetric),
}).partial()

export const apigatewayMonitoringMetric = $object({
    latency: defaultMetric,
    integrationLatency: defaultMetric,
    '5xx': defaultMetric,
    '4xx': defaultMetric,
    dataProcessed: defaultMetric,
    count: defaultMetric,
}).partial()

export const apigatewayMonitoring = $object({
    route: apigatewayMonitoringMetric,
    api: apigatewayMonitoringMetric,
}).partial()

export const sqsMonitoringMetric = $object({
    numberOfMessagesSent: defaultMetric,
    approximateNumberOfMessagesVisible: defaultMetric,
    approximateNumberOfMessagesDelayed: defaultMetric,
    approximateAgeOfOldestMessage: defaultMetric,
    approximateNumberOfMessagesNotVisible: defaultMetric,
    numberOfMessagesDeleted: defaultMetric,
    numberOfMessagesReceived: defaultMetric,
    numberOfEmptyReceives: defaultMetric,
}).partial()

export const sqsMonitoring = $object({
    queue: sqsMonitoringMetric,
    dlq: sqsMonitoringMetric,
}).partial()

export const lambdaMonitoringMetric = $object({
    asyncEventAge: defaultMetric,
    asyncEventsDropped: defaultMetric,
    asyncEventsReceived: defaultMetric,
    claimedAccountConcurrency: defaultMetric,
    concurrentExecutions: defaultMetric,
    duration: defaultMetric,
    errors: defaultMetric,
    invocations: defaultMetric,
    throttles: defaultMetric,
    unreservedConcurrentExecutions: defaultMetric,
}).partial()

export const lambdaMonitoring = $object({
    account: lambdaMonitoringMetric,
    function: lambdaMonitoringMetric,
}).partial()
