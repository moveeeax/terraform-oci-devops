resource "oci_devops_project" "this" {
  compartment_id = var.compartment_id
  name           = var.name
  description    = var.description

  notification_config {
    topic_id = var.notification_topic_id
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Project log. OCI models it as a Logging service log whose source is the
# project (service "devops", category "all"); without one, build and deployment
# pipeline output is not kept anywhere.
resource "oci_logging_log" "project" {
  count = var.log_group_id == null ? 0 : 1

  display_name       = coalesce(var.log_display_name, "${replace(var.name, "/[^A-Za-z0-9_-]/", "_")}_devops")
  log_group_id       = var.log_group_id
  log_type           = "SERVICE"
  is_enabled         = true
  retention_duration = var.log_retention_days

  configuration {
    compartment_id = var.compartment_id

    source {
      category    = "all"
      resource    = oci_devops_project.this.id
      service     = "devops"
      source_type = "OCISERVICE"
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
