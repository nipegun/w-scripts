:: Crear máquina virtual de OpenWrt
   echo Creando máquina virtual de OpenWrt...
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" createvm --name "openwrtlab" --ostype "Linux_64" --register
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
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --nictype3 virtio
     "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "openwrtlab" --nic3 intnet --intnet3 "redintlab"
   :: Almacenamiento
      :: CD
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storagectl "openwrtlab" --name "SATA Controller" --add sata --controller IntelAhci --portcount 1
           "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storageattach "openwrtlab" --storagectl "SATA Controller" --port 0 --device 0 --type dvddrive --medium emptydrive
      :: Disco duro
         "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storagectl "openwrtlab" --name "VirtIO" --add scsi
                    cd "~/VirtualBox VMs/openwrtlab/"
                    wget http://hacks4geeks.com/_/decargas/packs/openwrtlab.vmdk
                    VBoxManage storageattach "openwrtlab" --storagectl "VirtIO" --port 0 --device 0 --type hdd --medium ~/"VirtualBox VMs/openwrtlab/openwrtlab.vmdk"
