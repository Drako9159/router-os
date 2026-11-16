############### Alerta Telegram v5.1 (Optimizado sin bloqueos) via JSON POST (v7.x) — DHCP Lease Bound ###############
:local botToken "TU_NUEVO_TOKEN_AQUI"
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
    
    :local hostName "Sin-Nombre"
    :local leaseComment "Sin-Comentario"
    :local leaseType "Dinamico"
    :local serverName "Desconocido"
    :local leaseCfgLists ""
    
    # 1 sola búsqueda en la tabla DHCP para extraer todos los datos rápido
    :local leaseId [/ip dhcp-server lease find where active-mac-address=$leaseMac active-address=$leaseIp]
    
    :if ([:len $leaseId] > 0) do={
        :do { :set hostName [/ip dhcp-server lease get $leaseId host-name] } on-error={}
        :do { :set leaseComment [/ip dhcp-server lease get $leaseId comment] } on-error={}
        :do { :set serverName [/ip dhcp-server lease get $leaseId server] } on-error={}
        :do { :set leaseCfgLists [/ip dhcp-server lease get $leaseId address-lists] } on-error={}
        
        :local isDynamic [/ip dhcp-server lease get $leaseId dynamic]
        :if (!$isDynamic) do={ :set leaseType "Estatico" }
    }
    
    # Valores por defecto si vienen vacíos
    :if ([:len $hostName] = 0) do={ :set hostName "Sin-Nombre" }
    :if ([:len $leaseComment] = 0) do={ :set leaseComment "Sin-Comentario" }
    
    # Obtener todas las Address Lists activas del firewall para esta IP
    :local activeLists ""
    :foreach listEntry in=[/ip firewall address-list find where address=$leaseIp] do={
        :local listName [/ip firewall address-list get $listEntry list]
        :if ([:len $activeLists] = 0) do={
            :set activeLists $listName
        } else={
            :set activeLists ($activeLists . ", " . $listName)
        }
    }
    
    # Respaldo: Si el firewall aún no inyecta la lista dinámica por velocidad, usar la del Lease
    :if (([:len $activeLists] = 0) && ([:len $leaseCfgLists] > 0)) do={
        :set activeLists $leaseCfgLists
    }
    
    # Sanitizar campos dinámicos
    :local cleanHost [$sanitize $hostName]
    :local cleanComment [$sanitize $leaseComment]
    :local cleanServer [$sanitize $serverName]
    :local cleanLists "Ninguna"
    :if ([:len $activeLists] > 0) do={
        :set cleanLists [$sanitize $activeLists]
    }
    
    # Comprobar pertenencia a Address-Lists específicas para definir prioridad del color de alerta
    :local isLimited32k false
    :local isLimitedMbps false
    :local isDnsFamily false
    
    :if ([:find $activeLists "LMT-32KB"] >= 0) do={ :set isLimited32k true }
    :if (([:find $activeLists "LMT-2M"] >= 0) || ([:find $activeLists "LMT-4M"] >= 0)) do={ :set isLimitedMbps true }
    :if ([:find $activeLists "DNS-1113"] >= 0) do={ :set isDnsFamily true }
    
    # Obtener fecha y hora
    :local date [/system clock get date]
    :local time [/system clock get time]
    
    # Definir la cabecera del mensaje según prioridad de estados
    :local header "🟢 <b>DISPOSITIVO REGISTRADO</b>"
    :if ($isLimited32k) do={
        :set header "🔴 <b>ACCESO LIMITADO (LMT-32KB)</b>"
    } else={
        :if ($isLimitedMbps) do={
            :set header "🟠 <b>VELOCIDAD LIMITADA (LMT-2M/4M)</b>"
        } else={
            :if ($isDnsFamily) do={
                :set header "🔵 <b>FILTRO FAMILIAR (DNS-1113)</b>"
            } else={
                :if ($leaseType = "Dinamico") do={
                    :set header "🟡 <b>NUEVA CONEXIÓN (DINÁMICO)</b>"
                }
            }
        }
    }
    
    # Construir el mensaje formateado en HTML para el JSON
    :local mensaje "$header\\n───────────────────\\n👤 <b>Alias:</b> $cleanComment\\n💻 <b>Host:</b> $cleanHost\\n🌐 <b>IP:</b> <code>$leaseIp</code>\\n🔍 <b>MAC:</b> <code>$leaseMac</code>\\n📡 <b>Red/Servidor:</b> $cleanServer\\n🛡️ <b>Listas Activas:</b> $cleanLists\\n📅 <b>Fecha:</b> $date $time\\n───────────────────"
    
    # Armar el payload JSON
    :local payload "{\"chat_id\":\"$chatId\",\"parse_mode\":\"HTML\",\"text\":\"$mensaje\"}"
    
    # Envío directo (1 solo intento rápido para no congelar el servidor DHCP si no hay WAN)
    :do {
        /tool fetch http-method=post http-header-field="Content-Type: application/json" http-data=$payload url="https://api.telegram.org/bot$botToken/sendMessage" keep-result=no check-certificate=no
        :log info ("Telegram-Alert: Alerta enviada para $leaseIp ($leaseMac)")
    } on-error={
        :log error ("Telegram-Alert: Error al enviar alerta para $leaseIp (Sin conexión a Telegram)")
    }
}