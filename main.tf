terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

data "google_compute_zones" "available" {
}

##------------------------------------------------ Monitoring Group for All VMs (Excluding GKE Nodes) ------------------------------------------------
# resource "google_monitoring_group" "all_vms_group" {
#   display_name = "All VMs Uptime Check Group (Excluding GKE)"
#   filter       = "resource.type = \"gce_instance\" AND resource.labels.project_id = \"${var.project_id}\""
#   is_cluster   = false
# }

##---------------------------------------------- Universal Uptime Check (HTTP Port 80) ----------------------------------------------
## This works for VMs with web servers (nginx, apache, etc.) -> Note: VMs without web servers won't pass this check

# resource "google_monitoring_uptime_check_config" "http_uptime_check" {
#   display_name = "VMs HTTP Uptime Check (Port 80)"
#   timeout      = "10s"                            #Each request must respond within 10 seconds or it's considered failed.
#   period       = var.uptime_check_time_period     #How often to check (every 60 seconds in this example)
#   checker_type = "STATIC_IP_CHECKERS"

#   resource_group {
#     resource_type = "INSTANCE"                    #Targets a group of VM instances (defined elsewhere as all_vms_group).
#     group_id      = google_monitoring_group.all_vms_group.id   #Ensures the uptime check applies to all VMs in that group.
#   }

#   http_check {
#     path           = "/"
#     port           = 80
#     use_ssl        = false
#     validate_ssl   = false
#     request_method = "GET"
#   }

#   lifecycle {
#     create_before_destroy = true            #Terraform creates a new uptime check before destroying the old one
#   }

# }


##---------------------------------------- Instance-Level VM Monitoring (Works for ALL VMs) ---------------------------------------
## This monitors if the VM is running at the GCP infrastructure level no installation or web server needed - works automatically
## The alert condition checks: Is uptime < 60 seconds?  Yes -> Has this lasted for at more than 5 minutes (duration = 300s)? Yes

resource "google_monitoring_alert_policy" "vm_instance_down_alert" {
  display_name = "VM Instance Down Alert"
  combiner     = "OR"

  notification_channels = [
    for channel in google_monitoring_notification_channel.email_notification : channel.id
  ]

  conditions {
    display_name = "VM Down Condition"

    condition_absent {
      filter   = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/uptime\""
      duration = "120s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
      }
    }
  }

  documentation {
    content   = "This alert triggers when a VM stops publishing uptime metrics, meaning the VM is STOPPED or unreachable."
    mime_type = "text/markdown"
  }
}



#---------------- Notification Channels ----------------
resource "google_monitoring_notification_channel" "email_notification" {
  for_each     = toset(var.email_address)
  display_name = "Email Alert Notification for ${each.value}"
  type         = var.channel_type_mode
  labels = {
    email_address = each.value
  }
  force_delete = false
}

##---------------- VM Downtime Alert ----------------
# resource "google_monitoring_alert_policy" "downtime_alert" {
#   display_name = "VM Downtime Alert (All VMs)"
#   combiner     = "OR"
#   enabled      = true
#   project      = var.project_id

#   conditions {
#     display_name = "HTTP Uptime Check Failed"
#     condition_threshold {
#       filter = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\" AND metric.label.check_id=\"${google_monitoring_uptime_check_config.http_uptime_check.uptime_check_id}\""

#       duration        = "120s"
#       comparison      = "COMPARISON_LT"
#       threshold_value = 1

#       trigger {
#         count = 1
#       }

#       aggregations {
#         alignment_period     = "60s"
#         per_series_aligner   = "ALIGN_FRACTION_TRUE"
#         cross_series_reducer = "REDUCE_MEAN"
#       }
#     }
#   }

#   notification_channels = [
#     for channel in google_monitoring_notification_channel.email_notification : channel.id
#   ]

#   alert_strategy {
#     auto_close = "1800s"
#   }

#   documentation {
#     content = "VM is not responding to HTTP health checks on port 80 and may be down or web server is not running."
#   }
# }

##Google Monitoring alert policy for the VM INSTANCE STARTED AGAIN
resource "google_monitoring_alert_policy" "vm_instance_up_recovery" {
  display_name = "VM Instance Up / Recovery Alert"
  combiner     = "OR"
  enabled      = true
  project      = var.project_id

  conditions {
    display_name = "VM is Running Again"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/uptime\" AND resource.type=\"gce_instance\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0 # uptime > 0 means VM has started
      trigger {
        count = 1
      }
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [
    for channel in google_monitoring_notification_channel.email_notification : channel.id
  ]

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content = "VM has started and uptime metric is available again."
  }
}


##---------------- VM Uptime/Recovery Alert ----------------
# resource "google_monitoring_alert_policy" "uptime_recovery_alert" {
#   display_name = "VM Uptime Recovery Alert (All VMs)"
#   combiner     = "OR"
#   enabled      = true
#   project      = var.project_id

#   conditions {
#     display_name = "HTTP Uptime Check Recovered"
#     condition_threshold {
#       filter = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\" AND metric.label.check_id=\"${google_monitoring_uptime_check_config.http_uptime_check.uptime_check_id}\""

#       duration        = "60s"
#       comparison      = "COMPARISON_GT"
#       threshold_value = 0

#       trigger {
#         count = 1
#       }

#       aggregations {
#         alignment_period     = "60s"
#         per_series_aligner   = "ALIGN_FRACTION_TRUE"
#         cross_series_reducer = "REDUCE_MEAN"
#       }
#     }
#   }

#   notification_channels = [
#     for channel in google_monitoring_notification_channel.email_notification : channel.id
#   ]

#   alert_strategy {
#     auto_close = "1800s"
#   }

#   documentation {
#     content = "VM has recovered and is now responding to HTTP health checks on port 80."
#   }
# }

#---------------- CPU Utilization Alert ----------------
resource "google_monitoring_alert_policy" "vm_cpu_utilization_alert" {
  display_name = "VM High CPU Utilization Alert"
  combiner     = "OR"
  enabled      = true
  project      = var.project_id

  conditions {
    display_name = "High CPU Usage"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.high_cpu_threshold

      trigger {
        count = 1
      }

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [for channel in google_monitoring_notification_channel.email_notification : channel.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

#---------------- Memory Utilization Alert ----------------
resource "google_monitoring_alert_policy" "vm_memory_utilization_alert" {
  display_name = "VM High Memory Utilization Alert"
  combiner     = "OR"
  enabled      = true
  project      = var.project_id

  conditions {
    display_name = "High Memory Usage"
    condition_threshold {
      filter          = "metric.type=\"agent.googleapis.com/memory/percent_used\" AND resource.type=\"gce_instance\" AND metric.label.state=\"used\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.high_memory_threshold

      trigger {
        count = 1
      }

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [for channel in google_monitoring_notification_channel.email_notification : channel.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

#---------------- Disk Utilization Alert ----------------
resource "google_monitoring_alert_policy" "vm_disk_utilization_alert" {
  display_name = "VM High Disk Utilization Alert"
  combiner     = "OR"
  enabled      = true
  project      = var.project_id

  conditions {
    display_name = "High Disk Usage"
    condition_threshold {
      filter          = "metric.type=\"agent.googleapis.com/disk/percent_used\" AND resource.type=\"gce_instance\" AND metric.label.state=\"used\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.high_disk_threshold

      trigger {
        count = 1
      }

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [for channel in google_monitoring_notification_channel.email_notification : channel.id]

  alert_strategy {
    auto_close = "1800s"
  }
}