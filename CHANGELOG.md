# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Project logging: setting the new `log_group_id` input creates an OCI Logging
  service log for the project (service `devops`, category `all`) in that log
  group, with `log_retention_days` (30-day steps, 30 to 180, default 30) and an
  optional `log_display_name` (default `<name>_devops`). Off by default; new
  output `log_id` (null when off). Existing inputs and outputs are unchanged.

[Unreleased]: https://github.com/moveeeax/terraform-oci-devops/compare/v1.1.0...HEAD
