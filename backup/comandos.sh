## Exportar las configuraciones completas
/export file=mi_respaldo

## Exportar solo los valores diferentes por defecto
/export compact file=mi_respaldo_compact

## Exportar ocultando contraseñas y claves sensibles
/export hide-sensitive file=mi_respaldo_hide_sensitive

## Exportar una sección
/ip firewall export file=mi_respaldo_firewall

## Exportar archivo de configuracion por defecto
/system default-configuration print file=config_defecto