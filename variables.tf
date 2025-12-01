variable "project_id" {
  type        = string
  description = "Your project id here"
  default     = "training-2024-batch"
}

variable "region" {
  type        = string
  description = "Your region here"
  default     = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-c"
}

variable "zones" {
  type        = list(string)
  description = "Your zone here"
  default     = ["us-central1-a", "us-central1-b", "asia-south1-a"]
}


variable "vm_name" {
  type        = string
  description = "Your vm name here"
  default     = "my-vm"
}


variable "machine_type" {
  type        = string
  description = "Your machine type here"
  default     = "e2-micro"
}

variable "image" {
  type        = string
  description = "Your image here"
  default     = "debian-12-bookworm-v20251111"
}

variable "tags" {
  type        = list(string)
  description = "Your tags here"
  default     = ["allow-http", "allow-https", "allow-ssh"]
}

variable "network" {
  type        = string
  description = "Your network here"
  default     = "default"
}

variable "sub_network" {
  type    = string
  default = "projects/training-2024-batch/regions/us-central1/subnetworks/default"

}


variable "email_address" {
  type        = list(string)
  description = "List of email who gonna receive the alert mails"
  default     = ["sohail@wetranscloud.com", "vijayasharma@wetranscloud.com", ]

  #   validation {
  #     condition     = alltrue([for addr in var.email_address : contains(["sohail@wetranscloud.com","vijayasharma@wetranscloud.com","karuppaiah@wetranscloud.com"], addr)])
  #     error_message = "One or more email addresses are not allowed to access this project"
  #   }
}


variable "channel_type_mode" {
  type        = string
  description = "Select your notification medium"
  default     = "email"

  validation {
    condition     = contains(["email", "sms", "phone", "slack", "telegram", "webhook"], var.channel_type_mode)
    error_message = "Sorry your notification medium is not supported"
  }
}


variable "severity" {
  type    = string
  default = "CRITICAL"
  validation {
    condition     = contains(["CRITICAL", "ERROR", "WARNING", "INFO"], var.severity)
    error_message = "Sorry Not from the severity list"
  }
}

variable "high_disk_threshold" {
  type        = number
  description = "80% threshold set"
  default     = 0.8
}
variable "high_memory_threshold" {
  type        = number
  description = "80% threshold set"
  default     = 0.8
}
variable "high_cpu_threshold" {
  type        = number
  description = "80% threshold set"
  default     = 0.8
}


variable "monitor_resource_type" {
  type    = string
  default = "gce_instance"
}

variable "uptime_targets" {
  description = "Existing Compute Engine instances to monitor (name + zone)."
  type = list(object({
    name = string
    zone = string
  }))
  default = []
}


variable "uptime_check_time_period" {
  type    = string
  default = "60s"
}


# variable "uptime_instances" {
#   description = "List of instances with id and zone"
#   type = list(object({
#     id   = string
#     zone = string
#   }))
# }

# variable "host_vm" {
#   description = "Host vm ip addresses"
#   type        = list(string)
#   default     = []
# }


# data "external" "all_vms" {
#   program = ["./all_vms.sh", var.project_id]
# }