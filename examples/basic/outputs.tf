# Salida del ejemplo: comprueba que el output del módulo se puede referenciar.

output "failover_group_id" {
  description = "Resource ID of the example failover group."
  value       = module.sql_failover_group.resource_id
}
