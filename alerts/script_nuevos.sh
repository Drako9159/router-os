############### Alerta Telegram (Solo Dispositivos Nuevos) via JSON POST (v7.x) — DHCP Lease Bound ###############
:local botToken "x"
:local chatId "x"

# Función para sanitizar texto para JSON e HTML
:local sanitize do={
    :local result ""
    :for i from=0 to=([:len $1] - 1) do={
        :local char [:pick $1 $i ($i + 1)]
        :if ($char = "\"") do={ :set char "'" }
        :if ($char = "\\") do={ :set char "/" }
        :if ($char = "<") do={ :set char "&lt;" }
        :if ($char = ">") do={ :set char "&gt;" }
        :if ($char = "&") do={ :set char "&amp;" }
        :set result ($result . $char)
    }
    :return $result
}

:if ($leaseBound = 1) do={
    :local leaseMac $"leaseActMAC"
    :local leaseIp $"leaseActIP"
    
    # Buscar el ID del lease para obtener detalles del tipo
    :local leaseId [/ip dhcp-server lease find where active-mac-address=$leaseMac active-address=$leaseIp]
    :local leaseType "Dinamico"
    :local serverName "Desconocido"
    
    :if ([:len $leaseId] > 0) do={
        # Determinar si es estático (registrado/fijo) o dinámico
        :local isDynamic [/ip dhcp-server lease get $leaseId dynamic]
        :if (!$isDynamic) do={ :set leaseType "Estatico" }
        
        # Obtener el nombre del servidor DHCP asignado
        :do {
            :set serverName [/ip dhcp-server lease get $leaseId server]
        } on-error={}
    }
    
    # ¡SOLO enviar alerta si el dispositivo es DINÁMICO (no registrado)!
    :if ($leaseType = "Dinamico") do={
        # Obtener el nombre del host de forma segura
        :local hostName "Desconocido"
        :do {
            :set hostName [/ip dhcp-server lease get [find where active-mac-address=$leaseMac active-address=$leaseIp] host-name]
        } on-error={:set hostName "Desconocido"}
        
        # Obtener el comentario/alias de forma segura
        :local leaseComment "Sin-Comentario"
        :do {
            :set leaseComment [/ip dhcp-server lease get [find where active-mac-address=$leaseMac active-address=$leaseIp] comment]
        } on-error={:set leaseComment "Sin-Comentario"}
        
        # Valores por defecto si vienen vacíos
        :if ([:len $hostName] = 0) do={:set hostName "Sin-Nombre"}
        :if ([:len $leaseComment] = 0) do={:set leaseComment "Sin-Comentario"}
        
        # Sanitizar campos dinámicos
        :local cleanHost [$sanitize $hostName]
        :local cleanComment [$sanitize $leaseComment]
        :local cleanServer [$sanitize $serverName]
        
        # Obtener fecha y hora
        :local date [/system clock get date]
        :local time [/system clock get time]
        
        # Construir el mensaje formateado en HTML para el JSON
        :local mensaje "🟡 <b>NUEVA CONEXIÓN (DINÁMICO)</b>\\n───────────────────\\n👤 <b>Alias:</b> $cleanComment\\n💻 <b>Host:</b> $cleanHost\\n🌐 <b>IP:</b> <code>$leaseIp</code>\\n🔍 <b>MAC:</b> <code>$leaseMac</code>\\n📡 <b>Red/Servidor:</b> $cleanServer\\n📅 <b>Fecha:</b> $date $time\\n───────────────────"
        
        # Armar el payload JSON
        :local payload "{\"chat_id\":\"$chatId\",\"parse_mode\":\"HTML\",\"text\":\"$mensaje\"}"
        
        # Enviar con reintento (hasta 3 intentos) si falla usando la API de RouterOS v7.x
        :local sent false
        :local attempts 0
        :while (!$sent && $attempts < 3) do={
            :set attempts ($attempts + 1)
            :do {
                /tool fetch http-method=post http-header-field="Content-Type: application/json" http-data=$payload url="https://api.telegram.org/bot$botToken/sendMessage" keep-result=no check-certificate=no
                :set sent true
            } on-error={
                :if ($attempts < 3) do={ :delay 3s }
            }
        }
        
        # Registrar en el log del sistema
        :if ($sent) do={
            :log info ("Telegram-Alert: Alerta enviada para nuevo cliente $leaseIp ($leaseMac)")
        } else={
            :log error ("Telegram-Alert: Error al enviar alerta para $leaseIp tras $attempts intentos")
        }
    }
}
