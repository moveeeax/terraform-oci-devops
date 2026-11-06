provider "oci" {}

module "devops_project" {
  source = "../.."

  compartment_id        = var.compartment_id
  name                  = "example-devops"
  description           = "Example DevOps project"
  notification_topic_id = var.topic_id

  # Keep build and deployment output in OCI Logging when a log group is supplied.
  log_group_id       = var.log_group_id
  log_retention_days = 30

  freeform_tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

variable "compartment_id" {
  description = "Compartment OCID to deploy the example project into."
  type        = string
}

variable "topic_id" {
  description = "OCID of the ONS topic the project publishes events to."
  type        = string
}

variable "log_group_id" {
  description = "Optional log group OCID that receives the project log."
  type        = string
  default     = null
}

output "devops_project_id" {
  value = module.devops_project.id
}
