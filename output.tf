# -------------------- General Project Outputs --------------------
output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "zone" {
  description = "The GCP zone"
  value       = var.zone
}

output "all_zones" {
  description = "All zone in the project"
  value       = data.google_compute_zones.available
}


# output "all_instances" {
#   description = "All Instances in the project"
#   value       = data.google_compute_instance.all_instances
# }


##-------------------- Notification Channel Outputs --------------------
output "notification_channel_ids" {
  value = { for k, v in google_monitoring_notification_channel.email_notification : k => v.id }
}

output "notification_channel_emails" {
  value = { for k, v in google_monitoring_notification_channel.email_notification : k => v.labels["email_address"] }
}


## -------------------- Alert Policy Outputs --------------------
# output "uptime_alert_policy_id" {
#   description = "The ID of the uptime alert policy"
#   value       = { for k, policy in google_monitoring_alert_policy.alert_policy : k => policy.id }
# }

output "cpu_alert_policy_id" {
  description = "The ID of the CPU utilization alert policy"
  value       = google_monitoring_alert_policy.vm_cpu_utilization_alert.id
}

output "memory_alert_policy_id" {
  description = "The ID of the memory utilization alert policy"
  value       = google_monitoring_alert_policy.vm_memory_utilization_alert.id
}

output "disk_alert_policy_id" {
  description = "The ID of the disk utilization alert policy"
  value       = google_monitoring_alert_policy.vm_disk_utilization_alert.id
}


