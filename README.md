# terraform-oci-devops

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
DevOps project, the top-level container for code repositories, build and deployment
pipelines, and artifacts. Project events are published to a Notifications topic.

## Usage

```hcl
module "devops_project" {
  source = "github.com/moveeeax/terraform-oci-devops"

  compartment_id        = var.compartment_id
  name                  = "prod-devops"
  description           = "Production delivery pipelines"
  notification_topic_id = var.topic_id

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

## Input validation

| Input                   | Rule                                                            |
|-------------------------|------------------------------------------------------------------|
| `compartment_id`        | must start with `ocid1.compartment.` or `ocid1.tenancy.`         |
| `name`                  | 1–255 characters                                                 |
| `notification_topic_id` | must start with `ocid1.onstopic.`                                |
| `defined_tags`          | keys must be `namespace.key` (exactly one period)                |

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

## Outputs

| Name        | Description                              |
|-------------|------------------------------------------|
| `id`        | OCID of the DevOps project.              |
| `name`      | Name of the DevOps project.              |
| `namespace` | Namespace associated with the project.   |
| `state`     | Lifecycle state of the DevOps project.   |

## License

[MIT](LICENSE)
