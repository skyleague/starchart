locals {
  statistic_mapping = {
    "average" = "Average"
    "sum" = "Sum"
    "minimum" = "Minimum"
    "maximum" = "Maximum"
    "samplecount" = "SampleCount"
  }

  aws_metric_name_mapping = {
    "numberofmessagessent" = "NumberOfMessagesSent"
    "approximatenumberofmessagesvisible"   = "ApproximateNumberOfMessagesVisible"
    "approximatenumberofmessagesdelayed" = "ApproximateNumberOfMessagesDelayed"
    "approximateageofoldestmessage" = "ApproximateAgeOfOldestMessage"
    "approximatenumberofmessagesnotvisible"   = "ApproximateNumberOfMessagesNotVisible"
    "numberofmessagesdeleted"   = "NumberOfMessagesDeleted"
    "numberofmessagesreceived"   = "NumberOfMessagesReceived"
    "numberofemptyreceives"   = "NumberOfEmptyReceives"
  }

  unit_mapping = {
  }

  default_static_values = {
    dlq = {
      "approximatenumberofmessagesvisible" = {
        minimum = { threshold = 0, period = 60, evaluation_periods = 1, datapoints_to_alarm = 1 }
      }
    }
    queue = {}
  }
  default_static_value = {
    threshold = 1000,
    period = 60,
    evaluation_periods = 5
    datapoints_to_alarm = 5,
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