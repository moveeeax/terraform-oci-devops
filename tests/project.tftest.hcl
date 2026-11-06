# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (or OpenTofu >= 1.7).
# The module itself still supports >= 1.5 -- see versions.tf.
#
# Run with: terraform test

mock_provider "oci" {}

variables {
  compartment_id        = "ocid1.compartment.oc1..aaaaaaaaexamplecompartmentocid"
  name                  = "example-devops"
  notification_topic_id = "ocid1.onstopic.oc1.phx.aaaaaaaaexampletopicocid"
}

run "notification_topic_is_wired_to_the_project" {
  assert {
    condition     = oci_devops_project.this.notification_config[0].topic_id == var.notification_topic_id
    error_message = "The DevOps project must publish events to the supplied ONS topic."
  }
}

run "project_targets_the_supplied_compartment" {
  assert {
    condition     = oci_devops_project.this.compartment_id == var.compartment_id
    error_message = "The DevOps project must be created in the supplied compartment."
  }
}

run "tags_are_applied" {
  variables {
    freeform_tags = { Environment = "test" }
    defined_tags  = { "Operations.CostCenter" = "42" }
  }

  assert {
    condition     = oci_devops_project.this.freeform_tags["Environment"] == "test"
    error_message = "Free-form tags must be applied to the DevOps project."
  }

  assert {
    condition     = oci_devops_project.this.defined_tags["Operations.CostCenter"] == "42"
    error_message = "Defined tags must be applied to the DevOps project."
  }
}

run "rejects_empty_notification_topic" {
  command = plan

  variables {
    notification_topic_id = ""
  }

  expect_failures = [var.notification_topic_id]
}

run "rejects_placeholder_notification_topic" {
  command = plan

  variables {
    notification_topic_id = "REPLACE_ME"
  }

  expect_failures = [var.notification_topic_id]
}

run "rejects_non_topic_ocid_as_notification_topic" {
  command = plan

  # A compartment OCID pasted into the topic slot: valid-looking, notifies nobody.
  variables {
    notification_topic_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartmentocid"
  }

  expect_failures = [var.notification_topic_id]
}

run "rejects_non_compartment_ocid" {
  command = plan

  variables {
    compartment_id = "ocid1.onstopic.oc1.phx.aaaaaaaaexampletopicocid"
  }

  expect_failures = [var.compartment_id]
}

run "accepts_tenancy_ocid_as_compartment" {
  variables {
    compartment_id = "ocid1.tenancy.oc1..aaaaaaaaexampletenancyocid"
  }

  assert {
    condition     = oci_devops_project.this.compartment_id == "ocid1.tenancy.oc1..aaaaaaaaexampletenancyocid"
    error_message = "The root compartment (tenancy OCID) must be an accepted compartment_id."
  }
}

run "rejects_empty_name" {
  command = plan

  variables {
    name = ""
  }

  expect_failures = [var.name]
}

run "rejects_malformed_defined_tag_key" {
  command = plan

  variables {
    defined_tags = { CostCenter = "42" }
  }

  expect_failures = [var.defined_tags]
}

# --- project log --------------------------------------------------------------

run "no_log_by_default" {
  assert {
    condition     = length(oci_logging_log.project) == 0
    error_message = "No project log may be created unless log_group_id is set."
  }

  assert {
    condition     = output.log_id == null
    error_message = "log_id must be null when log_group_id is not set."
  }
}

run "log_is_attached_to_the_project" {
  variables {
    name         = "example devops"
    log_group_id = "ocid1.loggroup.oc1.phx.aaaaaaaaexampleloggroup"
  }

  assert {
    condition     = length(oci_logging_log.project) == 1
    error_message = "Setting log_group_id must create exactly one log."
  }

  assert {
    condition     = oci_logging_log.project[0].log_type == "SERVICE"
    error_message = "The project log must be a SERVICE log."
  }

  assert {
    condition     = one(one(oci_logging_log.project[0].configuration).source).service == "devops"
    error_message = "The project log source must be the devops service."
  }

  assert {
    condition     = one(one(oci_logging_log.project[0].configuration).source).category == "all"
    error_message = "The project log category must be all."
  }

  assert {
    condition     = one(one(oci_logging_log.project[0].configuration).source).resource == oci_devops_project.this.id
    error_message = "The project log must point at this project."
  }

  assert {
    condition     = one(oci_logging_log.project[0].configuration).compartment_id == var.compartment_id
    error_message = "The log source compartment must be the project's compartment."
  }

  assert {
    condition     = oci_logging_log.project[0].log_group_id == "ocid1.loggroup.oc1.phx.aaaaaaaaexampleloggroup"
    error_message = "log_group_id must be passed through."
  }

  assert {
    condition     = oci_logging_log.project[0].retention_duration == 30
    error_message = "Retention should default to 30 days."
  }

  assert {
    condition     = oci_logging_log.project[0].display_name == "example_devops_devops"
    error_message = "The default log name must be the sanitised project name plus _devops."
  }

  assert {
    condition     = output.log_id == oci_logging_log.project[0].id
    error_message = "log_id must expose the log OCID."
  }
}

run "log_overrides_are_passed_through" {
  variables {
    log_group_id       = "ocid1.loggroup.oc1.phx.aaaaaaaaexampleloggroup"
    log_retention_days = 180
    log_display_name   = "delivery-logs"
  }

  assert {
    condition     = oci_logging_log.project[0].retention_duration == 180
    error_message = "log_retention_days must be passed through."
  }

  assert {
    condition     = oci_logging_log.project[0].display_name == "delivery-logs"
    error_message = "log_display_name must override the default name."
  }
}

run "rejects_non_log_group_ocid" {
  command = plan

  variables {
    log_group_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartmentocid"
  }

  expect_failures = [var.log_group_id]
}

run "rejects_log_retention_outside_30_day_steps" {
  command = plan

  variables {
    log_group_id       = "ocid1.loggroup.oc1.phx.aaaaaaaaexampleloggroup"
    log_retention_days = 365
  }

  expect_failures = [var.log_retention_days]
}

run "rejects_blank_log_display_name" {
  command = plan

  variables {
    log_group_id     = "ocid1.loggroup.oc1.phx.aaaaaaaaexampleloggroup"
    log_display_name = ""
  }

  expect_failures = [var.log_display_name]
}
