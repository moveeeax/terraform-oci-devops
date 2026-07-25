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
