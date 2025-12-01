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




#---------------- Notification Type Channels ----------------
resource "google_monitoring_notification_channel" "email_notification" {
  for_each     = toset(var.email_address)
  display_name = "Email Alert Notification for ${each.value}"
  type         = var.channel_type_mode
  labels = {
    email_address = each.value
  }
  force_delete = false
}

## Google Monitoring alert policy for the 'Vm Instance down alert'
#Down Alert → condition_absent (metric missing for 2 minutes).
resource "google_monitoring_alert_policy" "vm_instance_down_alert" {
  display_name = "VM Instance Down Alert"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "VM Instance Is down"

    condition_absent {
      filter   = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/uptime\""
      duration = "120s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
      }
    }
  }


  alert_strategy {
    notification_rate_limit {
      period = "180s"
    }
  }

  notification_channels = [
    for channel in google_monitoring_notification_channel.email_notification : channel.id
  ]

  documentation {
    content   = "This alert triggers when a VM stops publishing uptime metrics, meaning the VM is STOPPED or unreachable."
    mime_type = "text/markdown"
  }
}


##Google Monitoring alert policy for the 'VM INSTANCE STARTED AGAIN'
#Up Alert → condition_threshold (uptime > 0 for 1 minute).

# ABOUT: This alert policy is designed to notify you when a Google Compute Engine (GCE) VM instance has started again. 
#It uses the uptime metric (compute.googleapis.com/instance/uptime) to detect when the VM is running. 
#If uptime is greater than 0 for at least 1 minute, the alert triggers.

resource "google_monitoring_alert_policy" "vm_instance_up_recovery" {
  display_name = "VM Instance Up / Recovery Alert"
  combiner     = "OR"
  enabled      = true
  project      = var.project_id

  conditions {
    display_name = "VM is Running Again"
    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/uptime\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      trigger {
        count = 1
      }
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }


  alert_strategy {
    notification_rate_limit {
      period = "180s"
    }
  }

  notification_channels = [
    for channel in google_monitoring_notification_channel.email_notification : channel.id
  ]

  documentation {
    content   = "VM has started and uptime metric is available again."
    mime_type = "text/markdown"
  }
}



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