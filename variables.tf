variable "compartment_id" {
  description = "OCID of the compartment in which to create the DevOps project."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID (starting with \"ocid1.compartment.\" or \"ocid1.tenancy.\")."
  }
}

variable "name" {
  description = "Name of the DevOps project (unique within the compartment)."
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 255
    error_message = "name must be between 1 and 255 characters."
  }
}

variable "description" {
  description = "Description of the DevOps project."
  type        = string
  default     = null
}

variable "notification_topic_id" {
  description = "OCID of the Notifications (ONS) topic the project publishes events to."
  type        = string

  # A DevOps project accepts any string here at plan time, so an empty or
  # placeholder value applies cleanly and then silently notifies nobody.
  # Require a real ONS topic OCID so the mistake fails at plan.
  validation {
    condition     = can(regex("^ocid1\\.onstopic\\.", var.notification_topic_id))
    error_message = "notification_topic_id must be an ONS topic OCID (starting with \"ocid1.onstopic.\"). DevOps project events are published to this topic; an empty or non-topic OCID leaves the project with no working notification target."
  }
}

variable "freeform_tags" {
  description = "Free-form tags applied to the DevOps project."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the DevOps project, keyed as \"namespace.key\"."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k in keys(var.defined_tags) : can(regex("^[^.]+\\.[^.]+$", k))])
    error_message = "defined_tags keys must be of the form \"namespace.key\" (exactly one period)."
  }
}
