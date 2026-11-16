# Versiones que acepta el módulo.
#
# Por qué un rango y no un valor fijo: un módulo no decide la versión del
# provider; la decide la configuración raíz que lo usa (el repo del cliente),
# que combina este módulo con los AVM del catálogo. Todos comparten una sola
# copia de azurerm, así que la versión final es la intersección de los rangos de
# todos. Si este módulo fijara una versión exacta, bastaría con que un AVM
# pidiera otra para que `init` no encontrara ninguna válida. La raíz, en cambio,
# sí fija un valor exacto (ver examples/basic) para que `plan` y `apply` usen
# siempre el mismo provider, junto con `.terraform.lock.hcl`.
#
# Cotas del rango de azurerm:
# - 4.0.0: el schema de azurerm_mssql_failover_group (atributos y bloques que
#   usa main.tf) es el mismo en 4.0.0 y en 4.81.0; se comparó con
#   `tofu providers schema -json`.
# - < 5.0.0: los AVM del catálogo piden azurerm 4.x (por ejemplo,
#   avm-res-sql-server 0.2.1 pide "~> 4.26"). Abrir el rango a 5.x no serviría
#   de nada hasta que ellos lo hagan, y la 5.x no se ha probado con este módulo.
#
# required_version: el módulo usa `optional()` en tipos de objeto (Terraform
# 1.3) y `precondition` (Terraform 1.2). La cota de 1.6.0 cubre ambos binarios
# (OpenTofu empezó en la 1.6) y < 2.0.0 evita adoptar sin probar una versión
# mayor con cambios incompatibles.
terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
  }
}
