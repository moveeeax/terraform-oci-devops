# terraform-oci-devops

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
DevOps project, the top-level container for code repositories, build and deployment
pipelines, and artifacts. Project events are published to a Notifications topic, and
build and deployment output can be kept in an OCI Logging log.

## Usage

```hcl
module "devops_project" {
  source = "github.com/moveeeax/terraform-oci-devops?ref=v1.0.0"

  compartment_id        = var.compartment_id
  name                  = "prod-devops"
  description           = "Production delivery pipelines"
  notification_topic_id = var.topic_id

  # Keep build and deployment logs.
  log_group_id       = var.log_group_id
  log_retention_days = 90

  freeform_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Notification wiring

A DevOps project's `notification_config.topic_id` is accepted as an opaque string,
so an empty or placeholder value applies cleanly and then silently notifies nobody.
This module therefore rejects, at plan time, any `notification_topic_id` that is not
an ONS topic OCID (`ocid1.onstopic.…`) — including an empty string, a placeholder,
or a compartment OCID pasted into the wrong slot.

The topic must already exist and be reachable from the project's compartment;
Terraform cannot check that, so create it with `oci_ons_notification_topic` (or look
it up with the matching data source) and pass its `id` rather than a literal string.

## Project logging

DevOps sends the logs of a project's resources, including build and deployment
runs, to a log attached to the project
([DevOps Logs](https://docs.oracle.com/en-us/iaas/Content/devops/using/devops_logs.htm)),
so a project without one has nowhere to show pipeline output. Set `log_group_id` to an existing log group and the module creates an OCI
Logging service log for the project (`service = "devops"`, `category = "all"`,
shown in the Console as "DevOps Logs"), which covers every build and deployment
pipeline in the project. Retention defaults to 30 days and accepts 30-day steps up
to 180 (`log_retention_days`). The log is named `<name>_devops` by default, with
characters other than letters, digits, `_` and `-` replaced by `_`; set
`log_display_name` to choose another name.

Without `log_group_id` nothing changes compared with earlier versions: no log is
created.

## Input validation

| Input                   | Rule                                                            |
|-------------------------|------------------------------------------------------------------|
| `compartment_id`        | must start with `ocid1.compartment.` or `ocid1.tenancy.`         |
| `name`                  | 1–255 characters                                                 |
| `notification_topic_id` | must start with `ocid1.onstopic.`                                |
| `defined_tags`          | keys must be `namespace.key` (exactly one period)                |
| `log_group_id`          | null or must start with `ocid1.loggroup.`                        |
| `log_retention_days`    | one of 30, 60, 90, 120, 150, 180                                 |
| `log_display_name`      | null or non-blank                                                |

This module takes no credentials, tokens, or connection secrets — authentication is
supplied entirely by the `oci` provider configuration, so nothing here needs
`sensitive = true`.

## Testing

```sh
terraform test
```

The suite in [`tests/`](tests) runs against a mocked `oci` provider, so it needs no
OCI credentials and no network access. It requires Terraform (or OpenTofu) >= 1.7 for
`mock_provider`; the module itself still supports >= 1.5.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| oci       | >= 5.0   |

## Inputs

| Name                    | Description                                                       | Type          | Default | Required |
|-------------------------|-------------------------------------------------------------------|---------------|---------|:--------:|
| `compartment_id`        | OCID of the compartment in which to create the project.           | `string`      | n/a     |   yes    |
| `name`                  | Name of the DevOps project (unique within the compartment).       | `string`      | n/a     |   yes    |
| `description`           | Description of the DevOps project.                                | `string`      | `null`  |    no    |
| `notification_topic_id` | OCID of the ONS topic the project publishes events to.            | `string`      | n/a     |   yes    |
| `freeform_tags`         | Free-form tags applied to the DevOps project.                     | `map(string)` | `{}`    |    no    |
| `defined_tags`          | Defined tags applied to the project, keyed `namespace.key`.       | `map(string)` | `{}`    |    no    |
| `log_group_id`          | Log group OCID for the project log. Null creates no log.          | `string`      | `null`  |    no    |
| `log_retention_days`    | Project log retention in days (30-day steps, 30 to 180).          | `number`      | `30`    |    no    |
| `log_display_name`      | Project log name. Null uses `<name>_devops`.                      | `string`      | `null`  |    no    |

## Outputs

| Name        | Description                              |
|-------------|------------------------------------------|
| `id`        | OCID of the DevOps project.              |
| `name`      | Name of the DevOps project.              |
| `namespace` | Namespace associated with the project.   |
| `state`     | Lifecycle state of the DevOps project.   |
| `log_id`    | OCID of the project log; null when off.  |

## License

[MIT](LICENSE)
