#!/usr/bin/env pwsh

# Pongo a disposición pública este script bajo el término de "software de dominio público".
# Puedes hacer lo que quieras con él porque es libre de verdad; no libre con condiciones como las licencias GNU y otras patrañas similares.
# Si se te llena la boca hablando de libertad entonces hazlo realmente libre.
# No tienes que aceptar ningún tipo de términos de uso o licencia para utilizarlo o modificarlo porque va sin CopyLeft.

# ----------
# Script de NiPeGun para preparar un Windows Portable a partir de un archivo .iso de instalacioón (requiere la versión Version 5.1 de PowerShell)
#
# Ejecución remota en Debian:
#   curl -sL https://raw.githubusercontent.com/nipegun/w-scripts/refs/heads/main/Scripts/CrearPendriveDeWindowsPortable.ps1 | bash
# Ejecución remota en Windows:
#   # Ejecución remota en Windows desde PowerShell o CMD abiertos como administrador:
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& ([ScriptBlock]::Create((Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/nipegun/w-scripts/refs/heads/main/Scripts/CrearPendriveDeWindowsPortable.ps1'))) -ISO 'C:\ISOs\Windows11.iso'"
# ----------

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)]
  [Alias('ISO')]
  [ValidateNotNullOrEmpty()]
  [string]$pRutaISO
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$cTamanoEFI = 260MB
$cTamanoMSR = 16MB
$cTamanoMinimo = 32GB
$cMargenLibre = 20GB
$cGptEFI = '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'
$cGptMSR = '{e3c9e316-0b5c-4db8-817d-f92df00215ae}'
$cGptDatos = '{ebd0a0a2-b9e5-4433-87c0-68b6b72699c7}'
$cDism = Join-Path $env:SystemRoot 'System32\dism.exe'
$cBcdBoot = Join-Path $env:SystemRoot 'System32\bcdboot.exe'

function fEsAdministrador {
  $vIdentidad = [Security.Principal.WindowsIdentity]::GetCurrent()
  $vPrincipal = New-Object Security.Principal.WindowsPrincipal($vIdentidad)
  return $vPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function fTamano {
  param([double]$pBytes)

  if ($pBytes -ge 1TB) {
    return ('{0:N2} TiB' -f ($pBytes / 1TB))
  }

  if ($pBytes -ge 1GB) {
    return ('{0:N2} GiB' -f ($pBytes / 1GB))
  }

  return ('{0:N2} MiB' -f ($pBytes / 1MB))
}

function fSeleccion {
  param(
    [int]$pCantidad,
    [string]$pMensaje
  )

  while ($true) {
    $vEntrada = Read-Host $pMensaje
    $vNumero = 0

    if ([int]::TryParse($vEntrada, [ref]$vNumero) -and $vNumero -ge 1 -and $vNumero -le $pCantidad) {
      return ($vNumero - 1)
    }

    Write-Warning "Introduce un número entre 1 y $pCantidad."
  }
}

function fDiscoDeRuta {
  param([string]$pRuta)

  try {
    $vArchivo = Get-Item -LiteralPath $pRuta -ErrorAction Stop
    $vVolumen = Get-Volume -FilePath $vArchivo.FullName -ErrorAction Stop | Select-Object -First 1

    if ($null -eq $vVolumen -or [string]::IsNullOrWhiteSpace([string]$vVolumen.DriveLetter)) {
      return $null
    }

    $vParticion = Get-Partition -DriveLetter ([char]$vVolumen.DriveLetter) -ErrorAction Stop | Select-Object -First 1
    return [int]$vParticion.DiskNumber
  }
  catch {
    return $null
  }
}

function fLetrasLibres {
  $aUsadas = @(
    Get-Volume -ErrorAction SilentlyContinue |
      Where-Object { $null -ne $_.DriveLetter } |
      ForEach-Object { ([string]$_.DriveLetter).ToUpperInvariant() }
  )
  $aPreferidas = @('S', 'W', 'Z', 'Y', 'X', 'V', 'U', 'T', 'R', 'Q', 'P', 'N', 'M', 'L', 'K', 'J', 'H', 'G', 'F', 'E', 'D')
  $aLibres = @($aPreferidas | Where-Object { $aUsadas -notcontains $_ } | Select-Object -First 2)

  if ($aLibres.Count -lt 2) {
    throw 'No hay dos letras de unidad libres.'
  }

  return $aLibres
}

function fArquitectura {
  param([object]$pValor)

  switch (([string]$pValor).Trim().ToUpperInvariant()) {
    '0' { return 'x86' }
    'X86' { return 'x86' }
    '12' { return 'arm64' }
    'ARM64' { return 'arm64' }
    default { return 'amd64' }
  }
}

function fCrearPoliticaSAN {
  param(
    [string]$pRuta,
    [string]$pArquitectura
  )

  $aLineas = @(
    '<?xml version="1.0" encoding="utf-8" standalone="yes"?>',
    '<unattend xmlns="urn:schemas-microsoft-com:unattend">',
    '  <settings pass="offlineServicing">',
    ('    <component name="Microsoft-Windows-PartitionManager" processorArchitecture="{0}" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' -f $pArquitectura),
    '      <SanPolicy>4</SanPolicy>',
    '    </component>',
    '  </settings>',
    '</unattend>'
  )

  [IO.File]::WriteAllLines($pRuta, [string[]]$aLineas, [System.Text.UTF8Encoding]::new($false))
}

if (-not (fEsAdministrador)) {
  throw 'Ejecuta el script desde Windows PowerShell o PowerShell abierto como administrador.'
}

Import-Module Storage -ErrorAction Stop
Import-Module Dism -ErrorAction Stop

$vRutaISO = (Get-Item -LiteralPath $pRutaISO -ErrorAction Stop).FullName

if ([IO.Path]::GetExtension($vRutaISO) -ine '.iso') {
  throw "El archivo indicado no es una ISO: $vRutaISO"
}

$vNumeroDiscoISO = fDiscoDeRuta -pRuta $vRutaISO
$vNumeroDiscoScript = $null

if (-not [string]::IsNullOrWhiteSpace([string]$PSCommandPath)) {
  $vNumeroDiscoScript = fDiscoDeRuta -pRuta $PSCommandPath
}

$vIsoMontadaPorScript = $false
$vRutaSAN = $null
$vError = $null
$vCompletado = $false

try {
  Write-Host 'Montando la ISO...'
  $vDiscoISO = Get-DiskImage -ImagePath $vRutaISO -ErrorAction SilentlyContinue

  if ($null -eq $vDiscoISO -or -not $vDiscoISO.Attached) {
    $vDiscoISO = Mount-DiskImage -ImagePath $vRutaISO -PassThru -ErrorAction Stop
    $vIsoMontadaPorScript = $true
  }

  $aVolumenesISO = @()

  for ($vIntento = 0; $vIntento -lt 40; $vIntento++) {
    $vDiscoISO = Get-DiskImage -ImagePath $vRutaISO -ErrorAction Stop
    $aVolumenesISO = @(Get-Volume -DiskImage $vDiscoISO -ErrorAction SilentlyContinue | Where-Object { $null -ne $_.DriveLetter })

    if ($aVolumenesISO.Count -gt 0) {
      break
    }

    Start-Sleep -Milliseconds 250
  }

  if ($aVolumenesISO.Count -eq 0) {
    throw 'Windows no ha asignado una letra de unidad a la ISO.'
  }

  $vRutaImagen = $null

  foreach ($vVolumenISO in $aVolumenesISO) {
    $vRaizISO = '{0}:\' -f $vVolumenISO.DriveLetter

    foreach ($vNombreImagen in @('install.wim', 'install.esd')) {
      $vCandidata = Join-Path $vRaizISO (Join-Path 'sources' $vNombreImagen)

      if (Test-Path -LiteralPath $vCandidata -PathType Leaf) {
        $vRutaImagen = $vCandidata
        break
      }
    }

    if ($null -ne $vRutaImagen) {
      break
    }
  }

  if ($null -eq $vRutaImagen) {
    throw 'La ISO no contiene sources\install.wim ni sources\install.esd.'
  }

  $aImagenes = @(Get-WindowsImage -ImagePath $vRutaImagen -ErrorAction Stop)

  if ($aImagenes.Count -eq 0) {
    throw 'No se han encontrado ediciones de Windows dentro de la ISO.'
  }

  Write-Host ''
  Write-Host "Ediciones contenidas en $vRutaImagen:"

  for ($vIndice = 0; $vIndice -lt $aImagenes.Count; $vIndice++) {
    $vImagen = $aImagenes[$vIndice]
    Write-Host ('[{0}] {1} | índice {2} | {3}' -f ($vIndice + 1), $vImagen.ImageName, $vImagen.ImageIndex, (fTamano $vImagen.ImageSize))
  }

  $vPosicionImagen = fSeleccion -pCantidad $aImagenes.Count -pMensaje 'Selecciona la edición'
  $vImagenElegida = $aImagenes[$vPosicionImagen]
  $vIndiceImagen = [int]$vImagenElegida.ImageIndex
  $vDetallesImagen = Get-WindowsImage -ImagePath $vRutaImagen -Index $vIndiceImagen -ErrorAction Stop
  $vArquitectura = fArquitectura -pValor $vDetallesImagen.Architecture
  $vTamanoImagen = [uint64]$vDetallesImagen.ImageSize
  $vTamanoNecesario = [uint64][Math]::Max(
    [double]$cTamanoMinimo,
    [double]($vTamanoImagen + $cMargenLibre + $cTamanoEFI + $cTamanoMSR)
  )

  Write-Host ''
  Write-Host "Edición seleccionada: $($vImagenElegida.ImageName)"
  Write-Host "Arquitectura: $vArquitectura"
  Write-Host "Tamaño mínimo del USB: $(fTamano $vTamanoNecesario)"

  $aExcluidos = @(
    @($vNumeroDiscoISO, $vNumeroDiscoScript) |
      Where-Object { $null -ne $_ } |
      Select-Object -Unique
  )
  $aDiscosUSB = @(
    Get-Disk |
      Where-Object {
        ([string]$_.BusType -ieq 'USB' -or [string]$_.Path -match 'USBSTOR') -and
        -not $_.IsBoot -and
        -not $_.IsSystem -and
        ($aExcluidos -notcontains [int]$_.Number)
      } |
      Sort-Object Number
  )

  if ($aDiscosUSB.Count -eq 0) {
    throw 'No se ha encontrado ningún disco USB utilizable. El disco que contiene la ISO o el script se excluye por seguridad.'
  }

  Write-Host ''
  Write-Host 'Discos USB detectados:'

  for ($vIndice = 0; $vIndice -lt $aDiscosUSB.Count; $vIndice++) {
    $vDisco = $aDiscosUSB[$vIndice]
    $vEstado = if ([uint64]$vDisco.Size -ge $vTamanoNecesario) { 'APTO' } else { 'NO APTO POR TAMAÑO' }
    $vSerie = ([string]$vDisco.SerialNumber).Trim()

    if ([string]::IsNullOrWhiteSpace($vSerie)) {
      $vSerie = 'N/D'
    }

    Write-Host ('[{0}] Disco {1} | {2} | {3} | serie: {4} | {5}' -f ($vIndice + 1), $vDisco.Number, $vDisco.FriendlyName, (fTamano $vDisco.Size), $vSerie, $vEstado)
  }

  $aDiscosAptos = @($aDiscosUSB | Where-Object { [uint64]$_.Size -ge $vTamanoNecesario })

  if ($aDiscosAptos.Count -eq 0) {
    throw "Ningún disco USB tiene el tamaño mínimo requerido: $(fTamano $vTamanoNecesario)."
  }

  while ($true) {
    $vPosicionDisco = fSeleccion -pCantidad $aDiscosUSB.Count -pMensaje 'Selecciona el disco USB que se borrará'
    $vDiscoElegido = $aDiscosUSB[$vPosicionDisco]

    if ([uint64]$vDiscoElegido.Size -ge $vTamanoNecesario) {
      break
    }

    Write-Warning "Ese disco necesita al menos $(fTamano $vTamanoNecesario)."
  }

  $vTextoConfirmacion = 'BORRAR DISCO {0}' -f $vDiscoElegido.Number

  Write-Host ''
  Write-Warning "SE BORRARÁ COMPLETAMENTE EL DISCO $($vDiscoElegido.Number): $($vDiscoElegido.FriendlyName), $(fTamano $vDiscoElegido.Size)."
  $vConfirmacion = Read-Host "Escribe exactamente '$vTextoConfirmacion' para continuar"

  if ($vConfirmacion -cne $vTextoConfirmacion) {
    throw 'Operación cancelada por el usuario.'
  }

  $vDiscoActual = Get-Disk -Number $vDiscoElegido.Number -ErrorAction Stop

  $vIdentificadorElegido = ([string]$vDiscoElegido.UniqueId).Trim()
  $vIdentificadorActual = ([string]$vDiscoActual.UniqueId).Trim()

  if (
    -not ([string]$vDiscoActual.BusType -ieq 'USB' -or [string]$vDiscoActual.Path -match 'USBSTOR') -or
    $vDiscoActual.IsBoot -or
    $vDiscoActual.IsSystem -or
    [uint64]$vDiscoActual.Size -ne [uint64]$vDiscoElegido.Size -or
    (
      -not [string]::IsNullOrWhiteSpace($vIdentificadorElegido) -and
      -not [string]::IsNullOrWhiteSpace($vIdentificadorActual) -and
      $vIdentificadorActual -cne $vIdentificadorElegido
    )
  ) {
    throw 'El disco seleccionado ha cambiado. Operación cancelada.'
  }

  if ($vDiscoActual.IsOffline) {
    Set-Disk -Number $vDiscoActual.Number -IsOffline $false -ErrorAction Stop
  }

  if ((Get-Disk -Number $vDiscoActual.Number).IsReadOnly) {
    Set-Disk -Number $vDiscoActual.Number -IsReadOnly $false -ErrorAction Stop
  }

  $vDiscoActual = Get-Disk -Number $vDiscoActual.Number -ErrorAction Stop
  $aParticiones = @(Get-Partition -DiskNumber $vDiscoActual.Number -ErrorAction SilentlyContinue)

  Write-Host ''
  Write-Host 'Borrando y particionando el USB...'

  if ($vDiscoActual.PartitionStyle -ne 'RAW' -or $aParticiones.Count -gt 0) {
    Clear-Disk -Number $vDiscoActual.Number -RemoveData -RemoveOEM -Confirm:$false -ErrorAction Stop
  }

  Start-Sleep -Milliseconds 500
  $vDiscoActual = Get-Disk -Number $vDiscoActual.Number -ErrorAction Stop

  if ($vDiscoActual.PartitionStyle -ne 'RAW') {
    throw 'El disco no ha quedado en estado RAW después de borrarlo.'
  }

  Initialize-Disk -Number $vDiscoActual.Number -PartitionStyle GPT -ErrorAction Stop
  $aLetras = fLetrasLibres
  $vLetraEFI = $aLetras[0]
  $vLetraWindows = $aLetras[1]

  $vParticionEFI = New-Partition -DiskNumber $vDiscoActual.Number -Size $cTamanoEFI -GptType $cGptEFI -DriveLetter ([char]$vLetraEFI) -ErrorAction Stop
  $null = Format-Volume -Partition $vParticionEFI -FileSystem FAT32 -NewFileSystemLabel 'EFI' -Force -Confirm:$false -ErrorAction Stop
  $null = New-Partition -DiskNumber $vDiscoActual.Number -Size $cTamanoMSR -GptType $cGptMSR -ErrorAction Stop
  $vParticionWindows = New-Partition -DiskNumber $vDiscoActual.Number -UseMaximumSize -GptType $cGptDatos -DriveLetter ([char]$vLetraWindows) -ErrorAction Stop
  $null = Format-Volume -Partition $vParticionWindows -FileSystem NTFS -NewFileSystemLabel 'WindowsPortable' -Force -Confirm:$false -ErrorAction Stop

  $vRutaEFI = '{0}:\' -f $vLetraEFI
  $vRutaWindows = '{0}:\' -f $vLetraWindows

  Write-Host ''
  Write-Host "Aplicando $($vImagenElegida.ImageName). Esta es la fase más lenta..."

  $aDismAplicar = @(
    '/English',
    '/Apply-Image',
    ('/ImageFile:{0}' -f $vRutaImagen),
    ('/Index:{0}' -f $vIndiceImagen),
    ('/ApplyDir:{0}' -f $vRutaWindows),
    '/CheckIntegrity'
  )

  & $cDism @aDismAplicar
  $vCodigoDism = $LASTEXITCODE

  if ($vCodigoDism -ne 0) {
    throw "DISM no ha podido aplicar la imagen. Código: $vCodigoDism."
  }

  Write-Host ''
  Write-Host 'Aplicando la política SAN OFFLINE_INTERNAL...'

  $vRutaSAN = Join-Path $vRutaWindows 'san_policy.xml'
  fCrearPoliticaSAN -pRuta $vRutaSAN -pArquitectura $vArquitectura
  $aDismSAN = @(
    '/English',
    ('/Image:{0}' -f $vRutaWindows),
    ('/Apply-Unattend:{0}' -f $vRutaSAN)
  )

  & $cDism @aDismSAN
  $vCodigoDismSAN = $LASTEXITCODE

  if ($vCodigoDismSAN -ne 0) {
    throw "DISM no ha podido aplicar la política SAN. Código: $vCodigoDismSAN."
  }

  Remove-Item -LiteralPath $vRutaSAN -Force
  $vRutaSAN = $null

  Write-Host ''
  Write-Host 'Creando el cargador de arranque UEFI...'

  $aBcdBoot = @((Join-Path $vRutaWindows 'Windows'), '/s', ('{0}:' -f $vLetraEFI), '/f', 'UEFI')
  $vAyudaBcdBoot = (& $cBcdBoot '/?' 2>&1 | Out-String)

  if ($vAyudaBcdBoot -match '(?i)/bootex') {
    $aBcdBoot += '/bootex'
  }

  & $cBcdBoot @aBcdBoot
  $vCodigoBcdBoot = $LASTEXITCODE

  if ($vCodigoBcdBoot -ne 0) {
    throw "BCDBoot ha fallado. Código: $vCodigoBcdBoot."
  }

  if (-not (Test-Path -LiteralPath (Join-Path $vRutaEFI 'EFI\Microsoft\Boot\BCD') -PathType Leaf)) {
    throw 'No se ha creado el almacén BCD en la partición EFI.'
  }

  $vDirectorioFallback = Join-Path $vRutaEFI 'EFI\Boot'
  $aFallback = @(Get-ChildItem -LiteralPath $vDirectorioFallback -Filter 'boot*.efi' -File -ErrorAction SilentlyContinue)

  if ($aFallback.Count -eq 0) {
    $vBootMgfw = Join-Path $vRutaEFI 'EFI\Microsoft\Boot\bootmgfw.efi'

    if (-not (Test-Path -LiteralPath $vBootMgfw -PathType Leaf)) {
      throw 'No se ha encontrado bootmgfw.efi en la partición EFI.'
    }

    $null = New-Item -ItemType Directory -Path $vDirectorioFallback -Force
    $vNombreFallback = switch ($vArquitectura) {
      'x86' { 'bootia32.efi' }
      'arm64' { 'bootaa64.efi' }
      default { 'bootx64.efi' }
    }
    Copy-Item -LiteralPath $vBootMgfw -Destination (Join-Path $vDirectorioFallback $vNombreFallback) -Force
  }

  Set-Partition -DiskNumber $vDiscoActual.Number -PartitionNumber $vParticionWindows.PartitionNumber -NoDefaultDriveLetter $true -ErrorAction Stop
  Remove-PartitionAccessPath -DiskNumber $vDiscoActual.Number -PartitionNumber $vParticionEFI.PartitionNumber -AccessPath ('{0}:\' -f $vLetraEFI) -Confirm:$false -ErrorAction Stop

  $vCompletado = $true

  Write-Host ''
  Write-Host 'Windows portable creado correctamente.'
  Write-Host "Edición: $($vImagenElegida.ImageName)"
  Write-Host "Disco USB: $($vDiscoActual.Number) - $($vDiscoActual.FriendlyName)"
  Write-Host "Partición de Windows temporalmente montada como $vLetraWindows`:"
  Write-Host 'Expulsa el USB con "Quitar hardware con seguridad" y arráncalo desde el menú UEFI.'
}
catch {
  $vError = $_
}
finally {
  if ($null -ne $vRutaSAN -and (Test-Path -LiteralPath $vRutaSAN -PathType Leaf)) {
    Remove-Item -LiteralPath $vRutaSAN -Force -ErrorAction SilentlyContinue
  }

  if ($vIsoMontadaPorScript) {
    Dismount-DiskImage -ImagePath $vRutaISO -ErrorAction SilentlyContinue
  }
}

if (-not $vCompletado) {
  Write-Host ''
  Write-Host "ERROR: $($vError.Exception.Message)"
  Write-Host "Registro de DISM: $env:SystemRoot\Logs\DISM\dism.log"
  exit 1
}

exit 0
