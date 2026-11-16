# Failover group de Azure SQL entre el servidor primario y el de la región DR.
#
# Por qué existe este módulo: avm-res-sql-server dejó de incluir el failover
# group a partir de la 0.2.0, y el caso de DR lo necesita. Es a propósito un
# envoltorio mínimo de un solo recurso: no crea servidores ni bases de datos
# (eso lo hace el AVM) y solo expone lo que el editor necesita configurar.

resource "azurerm_mssql_failover_group" "this" {
  name      = var.name
  server_id = var.server_id
  # El provider espera un set; la entrada es una lista porque es más simple de
  # llenar en el formulario y de conectar desde otros nodos.
  databases = toset(var.database_ids)

  partner_server {
    id = var.partner_server_id
  }

  read_write_endpoint_failover_policy {
    mode          = var.read_write_endpoint_failover_policy.mode
    grace_minutes = var.read_write_endpoint_failover_policy.grace_minutes
  }

  readonly_endpoint_failover_policy_enabled = var.readonly_endpoint_failover_policy_enabled

  tags = var.tags

  # Estas reglas cruzan dos variables, así que van aquí y no en `validation`
  # (validar contra otra variable no está disponible en todas las versiones que
  # acepta versions.tf). Si los IDs vienen de otros módulos y aún no se conocen,
  # tofu y terraform las comprueban en el plan.
  lifecycle {
    precondition {
      condition     = lower(var.server_id) != lower(var.partner_server_id)
      error_message = "server_id and partner_server_id point to the same server. The partner must be the secondary server in the disaster recovery region."
    }

    precondition {
      condition = alltrue([
        for database_id in var.database_ids :
        startswith(lower(database_id), "${lower(var.server_id)}/databases/")
      ])
      error_message = "Every database in database_ids must belong to the primary server (server_id). Use the IDs of the databases on the primary, not on the partner."
    }
  }
}
