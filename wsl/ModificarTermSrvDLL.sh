#!/bin/bash

# Pongo a disposición pública este script bajo el término de "software de dominio público".
# Puedes hacer lo que quieras con él porque es libre de verdad; no libre con condiciones como las licencias GNU y otras patrañas similares.
# Si se te llena la boca hablando de libertad entonces hazlo realmente libre.
# No tienes que aceptar ningún tipo de términos de uso o licencia para utilizarlo o modificarlo porque va sin CopyLeft.

#-------------------------------------------------------------------------------------------
#  Script de NiPeGun para modificar la librería de conexión a escritorio remoto de Windows
#
#  Ejecución remota:
#  curl -s x | bash
#-------------------------------------------------------------------------------------------

vCadenaCorrecta=B80001000089813806000090
vPrincipioDeCadenaABuscar=39813C0600000F84
vUbicArchivo="/mnt/c/Windows/System32/termsrv.dll"
vCadenaCompletaABuscar=$(xxd -plain -c 5000 -u $vUbicArchivo | sed "s|$vPrincipioDeCadenaABuscar|\n$vPrincipioDeCadenaABuscar|g" | grep $vPrincipioDeCadenaABuscar | head --bytes 24)
echo ""
echo "  Se reemplazará la cadena $vCadenaCompletaABuscar por la cadena $vCadenaCorrecta"
echo ""


