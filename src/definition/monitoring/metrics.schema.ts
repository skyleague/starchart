import { $boolean, $number, $object } from '@skyleague/therefore'

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
