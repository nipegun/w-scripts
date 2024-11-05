:: Pongo a disposición pública este script bajo el término de "software de dominio público".
:: Puedes hacer lo que quieras con él porque es libre de verdad; no libre con condiciones como las licencias GNU y otras patrañas similares.
:: Si se te llena la boca hablando de libertad entonces hazlo realmente libre.
:: No tienes que aceptar ningún tipo de términos de uso o licencia para utilizarlo o modificarlo porque va sin CopyLeft.

:: ----------
:: Script de NiPeGun para descargar e importar el pack CyberSecLab para VirtualBox en Windows
::
:: Ejecución remota desde CMD.exe
::   curl -sL https://raw.githubusercontent.com/nipegun/w-scripts/refs/heads/main/SoftInst/Packs/CyberSecLab-DescargarEImportar.bat | cmd
:: ----------

@echo off

:: Crear máquina virtual de OpenWrt
   echo Creando máquina virtual de OpenWrt...
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" createvm --name "openwrtlab" --ostype "Linux_64" --register
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --firmware efi
   :: Procesador
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --cpus 2
   :: RAM
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --memory 2048
   :: Gráfica
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --graphicscontroller vmsvga --vram 16 
   :: Audio
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --audio none
   :: Red
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --nictype1 virtio
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --nic1 "NAT"
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --nictype2 virtio
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --nic2 intnet --intnet2 "redintlan"
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --macaddress2 00aabbccd101
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --nictype3 virtio
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --nic3 intnet --intnet3 "redintlab"
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --macaddress3 00aabbccd201
   :: Almacenamiento
      :: CD
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storagectl "openwrtlab" --name "SATA Controller" --add sata --controller IntelAhci --portcount 1
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storageattach "openwrtlab" --storagectl "SATA Controller" --port 0 --device 0 --type dvddrive --medium emptydrive
      :: Disco duro
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storagectl "openwrtlab" --name "VirtIO" --add "VirtIO" --bootable on --portcount 1
         cd "VirtualBox VMs\openwrtlab\"
         curl -L http://hacks4geeks.com/_/descargas/MVs/Discos/Packs/CyberSecLab/openwrtlab.vmdk -o openwrtlab.vmdk
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storageattach "openwrtlab" --storagectl "VirtIO" --port 0 --device 0 --type hdd --medium openwrtlab.vmdk
   :: Volver a la carpeta de usuario
      cd ..
      cd ..

:: Crear máquina virtual de Kali
   echo Creando máquina virtual de Kali...
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" createvm --name "kali" --ostype "Debian_64" --register
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "kali" --firmware efi
   :: Procesador
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "kali" --cpus 4
   :: RAM
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "kali" --memory 4096
   :: Gráfica
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "kali" --graphicscontroller vmsvga --vram 128 --accelerate3d on
   :: Red
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "kali" --nictype1 virtio
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "kali" --nic1 intnet --intnet1 "redintlan"
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "kali" --macaddress1 00aabbccd102
   :: Almacenamiento
      :: CD
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storagectl "kali" --name "SATA Controller" --add sata --controller IntelAhci --portcount 1
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storageattach "kali" --storagectl "SATA Controller" --port 0 --device 0 --type dvddrive --medium emptydrive
      :: Disco duro
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storagectl "kali" --name "VirtIO" --add "VirtIO" --bootable on --portcount 1
         cd "VirtualBox VMs\kali\"
         curl -L http://hacks4geeks.com/_/descargas/MVs/Discos/Packs/CyberSecLab/kali.vmdk -o kali.vmdk
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storageattach "kali" --storagectl "VirtIO" --port 0 --device 0 --type hdd --medium kali.vmdk
   :: Volver a la carpeta de usuario
      cd ..
      cd ..

:: Crear máquina virtual de sift
   echo Creando máquina virtual de sift...
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" createvm --name "sift" --ostype "Ubuntu_64" --register
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "sift" --firmware efi
   :: Procesador
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "sift" --cpus 4
   :: RAM
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "sift" --memory 4096
   :: Gráfica
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "sift" --graphicscontroller vmsvga --vram 128 --accelerate3d on
   :: Red
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "sift" --nictype1 virtio
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "sift" --nic1 intnet --intnet1 "redintlan"
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "sift" --macaddress1 00aabbccd103
   :: Almacenamiento
      :: CD
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storagectl "sift" --name "SATA Controller" --add sata --controller IntelAhci --portcount 1
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storageattach "sift" --storagectl "SATA Controller" --port 0 --device 0 --type dvddrive --medium emptydrive
      :: Disco duro
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storagectl "sift" --name "VirtIO" --add "VirtIO" --bootable on --portcount 1
         cd "VirtualBox VMs\sift\"
         curl -L http://hacks4geeks.com/_/descargas/MVs/Discos/Packs/CyberSecLab/sift.vmdk -o sift.vmdk
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storageattach "sift" --storagectl "VirtIO" --port 0 --device 0 --type hdd --medium sift.vmdk
   :: Volver a la carpeta de usuario
      cd ..
      cd ..

:: Crear máquina virtual de pruebas
   echo Creando máquina virtual de pruebas...
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" createvm --name "pruebas" --ostype "Other_64" --register
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "pruebas" --firmware efi
   :: Procesador
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "pruebas" --cpus 4
   :: RAM
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "pruebas" --memory 4096
   :: Gráfica
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "pruebas" --graphicscontroller vmsvga --vram 128 --accelerate3d on
   :: Red
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "pruebas" --nictype1 virtio
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "pruebas" --nic1 intnet --intnet1 "redintlab"
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "pruebas" --macaddress1 00aabbccd202
   :: Almacenamiento
      :: CD
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storagectl "pruebas" --name "SATA Controller" --add sata --controller IntelAhci --portcount 1
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storageattach "pruebas" --storagectl "SATA Controller" --port 0 --device 0 --type dvddrive --medium emptydrive
      :: Disco duro
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storagectl "pruebas" --name "VirtIO" --add "VirtIO" --bootable on --portcount 1
         cd "VirtualBox VMs\pruebas\"
       ::  curl -L http://hacks4geeks.com/_/descargas/MVs/Discos/Packs/CyberSecLab/pruebas.vmdk -o pruebas.vmdk
       ::  "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storageattach "pruebas" --storagectl "VirtIO" --port 0 --device 0 --type hdd --medium pruebas.vmdk
   :: Volver a la carpeta de usuario
      cd ..
      cd ..



:: Agrupar máquinas virtuales
   echo Agrupando máquinas virtuales...
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"  modifyvm "openwrtlab" --groups "/CyberSecLab"
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"  modifyvm "kali"       --groups "/CyberSecLab"
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"  modifyvm "sift"       --groups "/CyberSecLab"
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"  modifyvm "pruebas"    --groups "/CyberSecLab"
