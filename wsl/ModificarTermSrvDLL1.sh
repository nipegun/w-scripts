#!/bin/bash

# Pongo a disposición pública este script bajo el término de "software de dominio público".
# Puedes hacer lo que quieras con él porque es libre de verdad; no libre con condiciones como las licencias GNU y otras patrañas similares.
# Si se te llena la boca hablando de libertad entonces hazlo realmente libre.
# No tienes que aceptar ningún tipo de términos de uso o licencia para utilizarlo o modificarlo porque va sin CopyLeft.

#------------------------------------------------------------------------------------------------------
#  Script de NiPeGun para modificar la librería de conexión a escritorio remoto de Windows
#
#  Ejecución remota:
#  curl -s https://raw.githubusercontent.com/nipegun/w-scripts/main/wsl/ModificarTermSrvDLL.sh | bash
#------------------------------------------------------------------------------------------------------

vCadenaCorrecta=B80001000089813806000090
vPrincipioDeCadenaABuscar=39813C0600000F84
vUbicArchivo="/mnt/c/Windows/System32/termsrv.dll"
vCadenaCompletaABuscar=$(xxd -plain -c 5000 -u $vUbicArchivo | sed "s|$vPrincipioDeCadenaABuscar|\n$vPrincipioDeCadenaABuscar|g" | grep $vPrincipioDeCadenaABuscar | head --bytes 24)

echo ""
echo "  Creando la carpeta de trabajo"
echo ""
mkdir -p /mnt/c/Datos/EscritorioRemoto/ 2> /dev/null

echo ""
echo "  Haciendo copia de seguridad del archivo termsrv.dll"
echo ""
cp /mnt/c/Windows/System32/termsrv.dll /mnt/c/Datos/EscritorioRemoto/termsrv.dll_backup

echo ""
echo "  Creando el archivo por lotes ..."
echo ""
echo "@echo off"                                                                               > /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat
echo "echo."                                                                                  >> /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat
echo 'echo "  Tomando propiedad del archivo termsrv.dll"'                                     >> /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat
echo "echo."                                                                                  >> /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat
echo "takeown /F c:\Windows\System32\termsrv.dll /A"                                          >> /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat
echo ""                                                                                       >> /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat
echo "echo."                                                                                  >> /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat
echo 'echo "  Concediendo permisos de control total del archivo al grupo administradores..."' >> /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat
echo "echo."                                                                                  >> /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat
echo "icacls c:\Windows\System32\termsrv.dll /grant Administradores:F"                        >> /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat
echo ""                                                                                       >> /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat
echo "echo."                                                                                  >> /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat
echo 'echo "  Parando el servicio de escritorio remoto..."'                                   >> /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat
echo "echo."                                                                                  >> /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat
echo "net stop TermService"                                                                   >> /mnt/c/Datos/EscritorioRemoto/PrepararParaModificar.bat

echo ""
echo "  Reemplazando la cadena $vCadenaCompletaABuscar por la cadena $vCadenaCorrecta..."
echo ""
vCadenaEnHex=$vCadenaCompletaABuscar
#sed "s|$vCadenaEnHex|\xB8\x00\x01\x00\x00\x89\x81\x38\x06\x00\x00\x90|g" /mnt/c/Windows/System32/termsrv.dll

