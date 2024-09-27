locals {
  statistic_mapping = {
    "average" = "Average"
    "sum" = "Sum"
    "minimum" = "Minimum"
    "maximum" = "Maximum"
    "samplecount" = "SampleCount"
  }

  aws_metric_name_mapping = {
    asynceventage = "AsyncEventAge"
    asynceventsdropped = "AsyncEventsDropped"
    asynceventsreceived = "AsyncEventsReceived"
    claimedaccountconcurrency = "ClaimedAccountConcurrency"
    concurrentexecutions = "ConcurrentExecutions"
    duration = "Duration"
    errors = "Errors"
    invocations = "Invocations"
    throttles = "Throttles"
    unreservedconcurrentexecutions = "UnreservedConcurrentExecutions"
  }

  unit_mapping = {
  }

  default_static_values = {
  }
  default_static_value = {
    threshold = 1000,
    period = 60,
    datapoints_to_alarm = 5,
    evaluation_periods = 5
  }

  default_anomaly_values = {
  }

  default_anomaly_value = {
    evaluation_periods = 5,
    datapoints_to_alarm = 5,
    band_width_standard_deviations = 2,
    metric_period = 300
  }
}