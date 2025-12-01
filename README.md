# terraform-gcp-infra


Monitoring Setup

1. Monitoring Groups

All VMs Group: Automatically includes ALL VMs in your project (including new ones)
Dynamically filters VMs based on project ID
No manual updates needed when you add new VMs



2. Uptime & Downtime Monitoring
A. HTTP Uptime Check (Port 80)

What it monitors: Web servers running on port 80 (nginx, apache, etc.)
Check frequency: Every 60 seconds
Timeout: 10 seconds
Regions: Checks from 6 global locations (Singapore, Belgium, Brazil, Iowa, Oregon, Virginia)
Works for: VMs with web servers installed

B. VM Instance Down Alert (Infrastructure Level)

What it monitors: If the VM is running at the GCP hypervisor level
Duration: Alerts after 5 minutes of low uptime
Works for: ALL VMs (no installation needed!)
Detects: VM stopped, crashed, or terminated



Notification Channels

Email addresses:

sohail@wetranscloud.com
vijayasharma@wetranscloud.com


Delivery: All 6 alert policies send to both email addresses
Auto-close: Alerts automatically close after 30 minutes (1800s) if resolved




6. Automatic Features
✅ Auto-discovery: New VMs automatically included in monitoring
✅ Auto-close: Resolved alerts close automatically after 30 minutes
✅ Multi-region checks: Uptime checks from 6 global regions
✅ Recovery notifications: You get notified when VMs come back online



How it works

New VM Created
    ↓
Automatically added to monitoring group (within 5-10 min)
    ↓
HTTP uptime check starts (every 60 seconds)
    ↓
Instance monitoring starts (tracks if VM is running)
    ↓
CPU/Memory/Disk monitoring starts (built-in + Ops Agent)
    ↓
IF issue detected → Email alert sent
    ↓
IF issue resolved → Recovery email sent
    ↓
Alert auto-closes after 30 minutes




































Monitoring Group (google_monitoring_group) Groups all VM instances in your project (excluding GKE nodes) so you can apply uptime checks and alerts to them collectively.

HTTP Uptime Check (google_monitoring_uptime_check_config) Runs an HTTP GET request on port 80 for all VMs in the group. ⚠️ Important: if a VM doesn’t run a web server (nginx, apache, etc.), this check will fail by design.

VM Instance Down Alert (google_monitoring_alert_policy.vm_instance_down_alert) Uses the metric compute.googleapis.com/instance/uptime.

If uptime drops below 60 seconds for 5 minutes, it triggers.

This is infrastructure-level monitoring (no agent/web server required).

Should fire when a VM is stopped or terminated.

Downtime Alert (google_monitoring_alert_policy.downtime_alert) Tied to the HTTP uptime check.

Only fires if the VM fails the HTTP probe on port 80.

If your VM doesn’t have a web server, this alert won’t trigger.

Recovery Alert (google_monitoring_alert_policy.uptime_recovery_alert) Fires when the HTTP uptime check passes again (VM responds on port 80).

CPU, Memory, Disk Utilization Alerts

CPU: compute.googleapis.com/instance/cpu/utilization

Memory: agent.googleapis.com/memory/percent_used (requires Ops Agent installed)

Disk: agent.googleapis.com/disk/percent_used (requires Ops Agent installed)

Notification Channels (google_monitoring_notification_channel) Configures email alerts for all policies.

Uses var.email_address and var.channel_type_mode (should be "email").

If this isn’t set correctly, alerts won’t be delivered.