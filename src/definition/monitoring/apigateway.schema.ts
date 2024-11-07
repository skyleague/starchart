import { $object, type Node } from '@skyleague/therefore'
import { anomalyMetric, staticMetric } from './metrics.schema.js'

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

export const apigatewayMetric = $object({
    static: toMetric(staticMetric),
    anomaly: toMetric(anomalyMetric),
}).partial()

export const apigatewayMonitoringMetric = $object({
    latency: apigatewayMetric,
    integrationLatency: apigatewayMetric,
    '5xx': apigatewayMetric,
    '4xx': apigatewayMetric,
    dataProcessed: apigatewayMetric,
    count: apigatewayMetric,
}).partial()

export const apigatewayMonitoring = $object({
    route: apigatewayMonitoringMetric,
    api: apigatewayMonitoringMetric,
}).partial()

export const monitoring = $object({
    httpApi: apigatewayMonitoring,
    restApi: apigatewayMonitoring,
}).partial()
