locals {
  statistic_mapping = {
    "average" = "Average"
    "sum" = "Sum"
    "minimum" = "Minimum"
    "maximum" = "Maximum"
    "samplecount" = "SampleCount"
  }

  aws_metric_name_mapping = {
    "latency" = "Latency"
    "count"   = "Count"
    "4xx" = "4xx"
    "5xx" = "5xx"
    "dataprocessed"   = "DataProcessed"
  }

  unit_mapping = {
    latency   = "Milliseconds"
    count     = "Count"
    "4xx" = "Count"
    "5xx" = "Count"
  }

  default_static_values = {
    "latency" = {
      "p90" = { threshold = 700, period = 60, evaluation_periods = 5 }
      "p95" = { threshold = 850, period = 60, evaluation_periods = 5 }
      "p99" = { threshold = 1000, period = 60, evaluation_periods = 5 }
      "average" = { threshold = 500, period = 60, evaluation_periods = 5 }
      "max" = { threshold = 1500, period = 60, evaluation_periods = 5 }
    }
    "4xx" = {
      "average" = { threshold = 5, period = 60, evaluation_periods = 5 }
      "sum" = { threshold = 20, period = 60, evaluation_periods = 5 }
    }
    "5xx" = {
      "average" = { threshold = 1, period = 60, evaluation_periods = 5 }
      "sum" = { threshold = 5, period = 60, evaluation_periods = 5 }
    }
    "slo" = {
      "success_rate" = { threshold = 99.9, period = 300, evaluation_periods = 1 }
    }
  }
  default_static_value = {
    threshold = 1000,
    period = 60,
    datapoints_to_alarm = 5,
    evaluation_periods = 5
  }

  default_anomaly_values = {
    "slo" = {
      "success_rate" = {
        evaluation_periods = 3,
        datapoints_to_alarm = 2,
        band_width_standard_deviations = 2,
        metric_period = 300
      }
    }
  }

  default_anomaly_value = {
    evaluation_periods = 5,
    datapoints_to_alarm = 5,
    band_width_standard_deviations = 2,
    metric_period = 300
  }
}