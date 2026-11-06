output "id" {
  description = "OCID of the DevOps project."
  value       = oci_devops_project.this.id
}

output "name" {
  description = "Name of the DevOps project."
  value       = oci_devops_project.this.name
}

output "namespace" {
  description = "Namespace associated with the DevOps project."
  value       = oci_devops_project.this.namespace
}

output "state" {
  description = "Lifecycle state of the DevOps project."
  value       = oci_devops_project.this.state
}

output "log_id" {
  description = "OCID of the project log; null when log_group_id is not set."
  value       = one(oci_logging_log.project[*].id)
}
