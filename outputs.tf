# Salidas del módulo.
#
# No hay `listener_fqdn`: azurerm_mssql_failover_group no expone ningún
# atributo con el nombre DNS del listener (se revisó el schema de azurerm 4.0.0
# y 4.81.0). El README explica cómo se forma.

output "resource_id" {
  description = "Resource ID of the failover group."
  value       = azurerm_mssql_failover_group.this.id
}

output "name" {
  description = "Name of the failover group, which is also the first label of the listener DNS names."
  value       = azurerm_mssql_failover_group.this.name
}
