Description:
This repository builds a production-ready GCP landing zone using Terraform.

State file:
For access to the state file contact: sohailsmd3131@gmail.com

Monitoring overview:
- Monitoring Groups
  - All VMs Group: automatically includes all VMs in the project (excluding GKE nodes). New VMs are added automatically.
- Uptime & Downtime Monitoring
  - HTTP uptime check (port 80)
    - Monitors web servers listening on port 80 (nginx, apache).
    - Frequency: 60s, timeout: 10s.
    - Regions: Singapore, Belgium, Brazil, Iowa, Oregon, Virginia.
    - Note: If a VM does not run a web server, the check will fail by design.
  - VM instance down alert (infrastructure-level)
    - Uses metric compute.googleapis.com/instance/uptime.
    - Triggers if uptime drops below 60s for 5 minutes (detects stopped/crashed/terminated VMs).
- Recovery and auto-close
  - Alerts auto-close after 30 minutes (1800s) if resolved.
  - Recovery notifications are sent when resources return to healthy state.

Notification channels:
- Emails: abc.com, xyz.com
- All alert policies deliver to both addresses. Ensure var.email_address and var.channel_type_mode are set to "email" to enable delivery.

Detailed components (Terraform resources)
- google_monitoring_group: groups VM instances for collective checks and alerts.
- google_monitoring_uptime_check_config: HTTP GET on port 80 for all VMs in the group.
- google_monitoring_alert_policy.vm_instance_down_alert: infrastructure-level uptime alert.
- google_monitoring_alert_policy.downtime_alert: tied to the HTTP uptime check (fires only if HTTP check fails).
- google_monitoring_alert_policy.uptime_recovery_alert: fires when HTTP check succeeds again.
- CPU/Memory/Disk alerts:
  - CPU: compute.googleapis.com/instance/cpu/utilization
  - Memory: agent.googleapis.com/memory/percent_used (requires Ops Agent)
  - Disk: agent.googleapis.com/disk/percent_used (requires Ops Agent)

Automatic features
- Auto-discovery: new VMs are added to monitoring automatically.
- Auto-close: alerts close automatically after 30 minutes.
- Multi-region uptime checks: checks from six regions.
- Recovery notifications when services/VMs come back online.

Operational notes and requirements
- Ops Agent required for memory & disk metrics.
- Ensure var.email_address and var.channel_type_mode are configured to enable notifications.
- Uptime checks on port 80 assume a web server is present; they will fail otherwise.
- For state access/contact: sohailsmd3131@gmail.com
