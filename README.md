# azurerm-sql-failover-group

Módulo de Terraform/OpenTofu que crea un **failover group de Azure SQL** entre el servidor primario y el servidor de la región de DR. Contiene un solo recurso, `azurerm_mssql_failover_group`.

Por qué existe: `avm-res-sql-server` dejó de incluir el failover group a partir de la 0.2.0 (lo tuvo hasta la 0.1.9) y el caso de DR lo necesita. En vez de fijar un AVM viejo se eligió un módulo propio mínimo: el AVM sigue creando servidores y bases de datos, y este módulo solo los une.

## Uso

```hcl
module "sql_failover_group" {
  source = "git::https://github.com/carlosv1989/terraform-azurerm-sql-failover-group.git?ref=<commit>"

  name              = "sql-fog-contoso-dr"
  server_id         = module.sql_primary.resource_id
  partner_server_id = module.sql_dr.resource_id
  database_ids      = [for database in module.sql_primary.resource_databases : database.resource_id]

  read_write_endpoint_failover_policy = {
    mode          = "Automatic"
    grace_minutes = 60
  }

  tags = {
    environment = "dr"
  }
}
```

`module.sql_primary` y `module.sql_dr` son instancias de `avm-res-sql-server` 0.2.1, que expone `resource_id` y `resource_databases` (un mapa cuyo valor tiene `resource_id`). Ese output está marcado `sensitive`, así que el plan muestra los IDs de las bases de datos como `(sensitive value)`. Hay un ejemplo con IDs ficticios en [`examples/basic`](examples/basic/main.tf).

## Entradas

| Nombre | Tipo | Default | Descripción |
|---|---|---|---|
| `name` | `string` | (obligatoria) | Nombre del failover group y del listener DNS. Único en todo Azure; minúsculas, dígitos y guiones, de 1 a 63 caracteres. |
| `server_id` | `string` | (obligatoria) | ID del servidor primario. |
| `partner_server_id` | `string` | (obligatoria) | ID del servidor secundario, en la región de DR. |
| `database_ids` | `list(string)` | (obligatoria) | IDs de las bases de datos **del primario** que se replican. Puede ser una lista vacía. |
| `read_write_endpoint_failover_policy` | `object({ mode = string, grace_minutes = optional(number) })` | (obligatoria) | `Automatic` con `grace_minutes` de 60 o más, o `Manual` sin `grace_minutes`. |
| `readonly_endpoint_failover_policy_enabled` | `bool` | `false` | Si el listener de solo lectura pasa al primario cuando el secundario no está disponible. |
| `tags` | `map(string)` | `{}` | Tags del failover group. |

La política de failover no tiene default a propósito: elegir entre `Automatic` (Azure conmuta solo y puede perder los datos que no alcanzaron a replicarse) y `Manual` (espera a una persona) es una decisión del diseño de DR, no algo que el módulo deba suponer.

Validaciones (fallan en `validate` o en el `plan`, antes de llegar a Azure):

- formato de `name` y de los IDs de servidores y bases de datos;
- `mode` es `Automatic` o `Manual`; `Automatic` exige `grace_minutes` entero de 60 o más y `Manual` no lo acepta;
- `database_ids` no repite bases de datos;
- el primario y el partner son servidores distintos, y todas las bases de datos son del primario (estas dos se comprueban en el `plan`, porque cruzan dos variables).

## Salidas

| Nombre | Descripción |
|---|---|
| `resource_id` | ID del failover group. |
| `name` | Nombre del failover group. |

No hay `listener_fqdn`: el recurso no expone ningún atributo con el nombre DNS del listener (se revisó el schema de azurerm 4.0.0 y 4.81.0 con `tofu providers schema -json`). En la nube pública de Azure, Microsoft documenta que el listener de lectura y escritura es `<name>.database.windows.net` y el de solo lectura `<name>.secondary.database.windows.net`; en otras nubes (Government, China) cambia el sufijo. Si lo necesitas, fórmalo en la raíz con el output `name`.

## Versiones

- `azurerm` `>= 4.0.0, < 5.0.0`. Es un rango porque la versión final la fija la configuración raíz, que combina este módulo con los AVM (hoy todos en 4.x). La raíz sí fija un valor exacto. El razonamiento completo está en [`versions.tf`](versions.tf).
- Terraform u OpenTofu `>= 1.6.0, < 2.0.0`. CI valida con los dos binarios.

## Cómo se prueba

En el repo de Moduloom, sin credenciales de Azure (nunca se ejecuta `plan` ni `apply`):

```bash
make validate-tf
```

Corre `init -backend=false` y `validate` con `tofu` y con `terraform` sobre `examples/basic`, `tflint` y `checkov`. Lo mismo corre el job `terraform` de CI del repo de Moduloom (`scripts/validate_terraform.sh`).

## Uso desde el repo publicado

El módulo se publica en `https://github.com/carlosv1989/terraform-azurerm-sql-failover-group` (Apache-2.0). Fíjalo por commit, no por tag, igual que hace el HCL que genera Moduloom:

```hcl
source = "git::https://github.com/carlosv1989/terraform-azurerm-sql-failover-group.git?ref=<commit>"
```

## Licencia

Apache-2.0 (ver `LICENSE` en el repo publicado).
