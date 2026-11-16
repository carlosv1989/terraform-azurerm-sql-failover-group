# Entradas del módulo.
#
# Las descripciones van en inglés porque el editor de ciap las muestra tal cual
# en el formulario del nodo. Las validaciones atrapan los errores comunes antes
# de llegar a Azure, con un mensaje que dice cómo arreglarlos.
#
# Los `error_message` también van en inglés: no los muestra ciap sino tofu (o
# terraform) en el `plan` del pipeline del cliente, junto a los demás mensajes
# del binario y de los módulos de Azure, que están en inglés.
#
# Los defaults son literales a propósito: el lector del catálogo
# (scripts/generate_catalog_manifest.py) copia los defaults al manifiesto y no
# evalúa expresiones.

variable "name" {
  type        = string
  nullable    = false
  description = "Name of the failover group. It is also the DNS name of the listener (<name>.database.windows.net), so it must be globally unique. Lowercase letters, digits and hyphens; 1 to 63 characters; it cannot start or end with a hyphen."

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.name))
    error_message = "The failover group name must have 1 to 63 lowercase letters, digits or hyphens, and cannot start or end with a hyphen (for example: sql-fog-contoso-dr)."
  }
}

variable "server_id" {
  type        = string
  nullable    = false
  description = "Resource ID of the primary Azure SQL server (the one that owns the databases today)."

  validation {
    condition     = can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Sql/servers/[^/]+$", var.server_id))
    error_message = "server_id must be the resource ID of an Azure SQL server: /subscriptions/<subscription>/resourceGroups/<group>/providers/Microsoft.Sql/servers/<server>."
  }
}

variable "partner_server_id" {
  type        = string
  nullable    = false
  description = "Resource ID of the secondary Azure SQL server, in the disaster recovery region. Azure creates the replicas of the databases on this server."

  validation {
    condition     = can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Sql/servers/[^/]+$", var.partner_server_id))
    error_message = "partner_server_id must be the resource ID of an Azure SQL server: /subscriptions/<subscription>/resourceGroups/<group>/providers/Microsoft.Sql/servers/<server>."
  }
}

variable "database_ids" {
  type        = list(string)
  nullable    = false
  description = "Resource IDs of the databases on the primary server that the failover group replicates and fails over together."

  validation {
    condition = alltrue([
      for database_id in var.database_ids :
      can(regex("(?i)^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Sql/servers/[^/]+/databases/[^/]+$", database_id))
    ])
    error_message = "Each item of database_ids must be the resource ID of an Azure SQL database: /subscriptions/<subscription>/resourceGroups/<group>/providers/Microsoft.Sql/servers/<server>/databases/<database>."
  }

  validation {
    condition     = length(distinct([for database_id in var.database_ids : lower(database_id)])) == length(var.database_ids)
    error_message = "database_ids has repeated databases. List each database once."
  }
}

variable "read_write_endpoint_failover_policy" {
  type = object({
    mode          = string
    grace_minutes = optional(number)
  })
  nullable    = false
  description = "Failover policy of the read-write listener. mode = \"Automatic\" lets Azure fail over after grace_minutes (60 or more) without a response from the primary, accepting possible data loss. mode = \"Manual\" waits for an operator; leave grace_minutes empty."

  validation {
    condition     = contains(["Automatic", "Manual"], var.read_write_endpoint_failover_policy.mode)
    error_message = "read_write_endpoint_failover_policy.mode must be \"Automatic\" or \"Manual\" (with that exact capitalization)."
  }

  # No se compara grace_minutes directamente porque `||` y `&&` no cortan la
  # evaluación: con grace_minutes = null, `null >= 60` daría un error en vez del
  # mensaje de abajo. `try(..., false)` convierte ese caso en "no cumple".
  validation {
    condition = (
      var.read_write_endpoint_failover_policy.mode != "Automatic"
      || try(
        var.read_write_endpoint_failover_policy.grace_minutes >= 60
        && floor(var.read_write_endpoint_failover_policy.grace_minutes) == var.read_write_endpoint_failover_policy.grace_minutes,
        false
      )
    )
    error_message = "With mode = \"Automatic\", grace_minutes is required and must be a whole number of minutes, 60 or more (Azure does not accept a grace period under one hour)."
  }

  validation {
    condition     = var.read_write_endpoint_failover_policy.mode != "Manual" || var.read_write_endpoint_failover_policy.grace_minutes == null
    error_message = "With mode = \"Manual\" there is no automatic failover, so grace_minutes does not apply. Remove it or use mode = \"Automatic\"."
  }
}

variable "readonly_endpoint_failover_policy_enabled" {
  type        = bool
  nullable    = false
  default     = false
  description = "Whether the read-only listener fails over to the primary when the secondary is unavailable. Disabled by default, which is also the Azure default."
}

variable "tags" {
  type        = map(string)
  nullable    = false
  default     = {}
  description = "Tags for the failover group."
}
