# Migraciones de Base de Datos con Flyway

## Convención de nombres
Los archivos de migración deben seguir el formato:
```
V{version}__{descripcion}.sql
```

Ejemplos:
- `V1__initial_schema.sql`
- `V2__add_usuarios_table.sql`
- `V3__add_pacientes_table.sql`

## Orden de ejecución
Flyway ejecuta las migraciones en orden numérico (V1 → V2 → V3...).

## Reglas importantes
1. **NUNCA** modificar una migración ya aplicada
2. **NUNCA** borrar una migración ya aplicada
3. Si hay error, crear nueva migración para corregir
4. Probar migraciones en entorno dev antes de prod

## Primera migración
`V1__initial_schema.sql` contendrá:
- Creación de todas las tablas base
- Índices
- Constraints (FK, UNIQUE, CHECK)
- Datos iniciales (roles, permisos)