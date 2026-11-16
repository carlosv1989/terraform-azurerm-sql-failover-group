# Ejemplo mínimo del módulo, solo para `init -backend=false` y `validate`.
#
# Los IDs son ficticios (suscripción en ceros, nombres "contoso"): nunca se
# ejecuta `plan` ni `apply` sobre este ejemplo.

terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Una configuración raíz fija la versión exacta; el módulo acepta un rango
      # (ver ../../versions.tf). 4.81.0 es la última 4.x.
      version = "4.81.0"
    }
  }
}

# `validate` no configura el provider, pero azurerm exige el bloque `features`
# y así el ejemplo también sirve de modelo para una raíz real.
provider "azurerm" {
  features {}
}

module "sql_failover_group" {
  source = "../.."

  name              = "sql-fog-contoso-dr"
  server_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-contoso-primary/providers/Microsoft.Sql/servers/sql-contoso-eastus2"
  partner_server_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-contoso-dr/providers/Microsoft.Sql/servers/sql-contoso-centralus"
  database_ids = [
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-contoso-primary/providers/Microsoft.Sql/servers/sql-contoso-eastus2/databases/sqldb-orders",
  ]

  read_write_endpoint_failover_policy = {
    mode          = "Automatic"
    grace_minutes = 60
  }

  tags = {
    environment = "dr"
  }
}
