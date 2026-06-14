############### Alerta telegram para cada que un cliente solicita una IP al DCHP, clientes dinámicos o no ###############
:local botToken "x"
:local chatId "x"
:if ($leaseBound = 1) do={
    :local leaseMac $"leaseActMAC"
    :local leaseIp $"leaseActIP"
    # Obtener el nombre del host de forma segura
    :local hostName "Desconocido"
    :do {
        :set hostName [/ip dhcp-server lease get [find where active-mac-address=$leaseMac active-address=$leaseIp] host-name]
    } on-error={:set hostName "Desconocido"}
    # Si viene vacío, asegurar un texto plano sin espacios
    :if ([:len $hostName] = 0) do={:set hostName "Dispositivo-sin-nombre"}
    # Reemplazamos los espacios del hostName por guiones para proteger la URL
    :for i from=0 to=([:len $hostName] - 1) do={
        :local char [:pick $hostName $i ($i + 1)]
        :if ($char = " ") do={
            :set hostName ([:pick $hostName 0 $i] . "-" . [:pick $hostName ($i + 1) [:len $hostName]])
        }
    }
    # Extraemos fecha y hora por separado para evitar caracteres extraños
    :local date [/system clock get date]
    :local time [/system clock get time]
    # Construimos el mensaje usando %20 para espacios y %3A para los dos puntos de la hora
    :local mensaje "🟢%20ONLINE:%20$leaseIp%0A----------------------------------------%0A👤%20DTECT:%20$leaseComment%0A🔍%20MAC:%20$leaseMac%0A💻%20NAME:%20$hostName%0A⏱%20DATE:%20$date%20$time"
    # Ejecutamos la petición HTTP limpia
    /tool fetch url="https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=$mensaje" keep-result=no check-certificate=no
}




############### Alerta telegram para cada que un cliente solicita una IP al DCHP, clientes dinámicos o no, con comentarios###############
:local botToken "x"
:local chatId "x"

:if ($leaseBound = 1) do={
    :local leaseMac $"leaseActMAC"
    :local leaseIp $"leaseActIP"
    
    # Obtener el nombre del host de forma segura (Tu lógica exacta)
    :local hostName "Desconocido"
    :do {
        :set hostName [/ip dhcp-server lease get [find where active-mac-address=$leaseMac active-address=$leaseIp] host-name]
    } on-error={:set hostName "Desconocido"}
    
    # Obtener el comentario de forma segura usando la misma estructura anidada
    :local leaseComment "Sin-Comentario"
    :do {
        :set leaseComment [/ip dhcp-server lease get [find where active-mac-address=$leaseMac active-address=$leaseIp] comment]
    } on-error={:set leaseComment "Sin-Comentario"}
    
    # Si vienen vacíos, asegurar un texto plano sin espacios
    :if ([:len $hostName] = 0) do={:set hostName "Dispositivo-sin-nombre"}
    :if ([:len $leaseComment] = 0) do={:set leaseComment "Sin-Comentario"}
    
    # Reemplazamos los espacios del hostName por guiones para proteger la URL
    :for i from=0 to=([:len $hostName] - 1) do={
        :local char [:pick $hostName $i ($i + 1)]
        :if ($char = " ") do={
            :set hostName ([:pick $hostName 0 $i] . "-" . [:pick $hostName ($i + 1) [:len $hostName]])
        }
    }
    
    # Reemplazamos los espacios del leaseComment por guiones para proteger la URL
    :for i from=0 to=([:len $leaseComment] - 1) do={
        :local char [:pick $leaseComment $i ($i + 1)]
        :if ($char = " ") do={
            :set leaseComment ([:pick $leaseComment 0 $i] . "-" . [:pick $leaseComment ($i + 1) [:len $leaseComment]])
        }
    }

    # Extraemos fecha y hora por separado para evitar caracteres extraños
    :local date [/system clock get date]
    :local time [/system clock get time]
    
    # Construimos el mensaje incluyendo el campo del comentario (Alias)
    :local mensaje "🟢%20ONLINE:%20$leaseIp%0A----------------------------------------%0A👤%20DTECT:%20$leaseComment%0A🔍%20MAC:%20$leaseMac%0A💻%20NAME:%20$hostName%0A⏱%20DATE:%20$date%20$time"
    
    # Ejecutamos la petición HTTP limpia
    /tool fetch url="https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=$mensaje" keep-result=no check-certificate=no
}


















############### Alerta telegram para cuando el cliente no está el la lista static ###############
:local botToken "x"
:local chatId "x"

:if ($leaseBound = 1) do={
    :local leaseMac $"leaseActMAC"
    :local leaseIp $"leaseActIP"
    
    # Verificamos si el lease que se acaba de conectar es dinámico o estático
    :local isDynamic [/ip dhcp-server lease get [find where active-mac-address=$leaseMac active-address=$leaseIp] dynamic]
    
    # ¡SOLO si es dinámico (usuario nuevo o no registrado de forma fija) enviamos la alerta!
    :if ($isDynamic = true) do={
        :local hostName "Desconocido"
        :do {
            :set hostName [/ip dhcp-server lease get [find where active-mac-address=$leaseMac active-address=$leaseIp] host-name]
        } on-error={:set hostName "Desconocido"}
        
        :if ([:len $hostName] = 0) do={:set hostName "Dispositivo-sin-nombre"}
        
        :for i from=0 to=([:len $hostName] - 1) do={
            :local char [:pick $hostName $i ($i + 1)]
            :if ($char = " ") do={
                :set hostName ([:pick $hostName 0 $i] . "-" . [:pick $hostName ($i + 1) [:len $hostName]])
            }
        }
        :local date [/system clock get date]
        :local time [/system clock get time]
        
        :local mensaje "%F0%9F%93%A1%20NUEVO_DISPOSITIVO_DETECTADO%0A%0AIP:%20$leaseIp%0AMAC:%20$leaseMac%0ADispositivo:%20$hostName%0AFecha:%20$date%20$time"
        
        /tool fetch url="https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=$mensaje" keep-result=no check-certificate=no
    }
}