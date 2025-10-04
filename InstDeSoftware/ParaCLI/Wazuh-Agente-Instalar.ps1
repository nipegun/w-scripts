#!/usr/bin/env pwsh

$vVersWazuh     = '4.x'
$vArchivoMSI    = 'wazuh-agent_4.13.1-1.msi'
$vWazuhServerIP = '192.168.1.147'

# Descargar el archivo
Invoke-WebRequest -Uri "https://packages.wazuh.com/$vVersWazuh/windows/$vArchivoMSI" -OutFile "$env:TEMP\$vArchivoMSI"

# Ejecutar el instalador
msiexec /i "$env:TEMP\$vArchivoMSI" /q WAZUH_MANAGER=$vWazuhServerIP

# Lanzar el agente
net start Wazuh

