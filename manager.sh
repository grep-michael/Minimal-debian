#!/bin/bash

ACTION=$1
shift
FOLDER="live-build"    

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f) FOLDER="$2"; shift ;;
        -l) LUXURY=1 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

isovolume="ITAD OS" 
isopublisher="Michael Knudsen" 
isoapplication="ITAD Platform (Debian 12)" 

build_mkgriso_file(){
    OUTPUT_SCRIPT="config/includes.binary/mkgriso"
    cat > "$OUTPUT_SCRIPT" << 'EOF'
#!/bin/sh
VOLUME="VOLUME_PLACEHOLDER"
APP="APP_PLACEHOLDER"
DIR=$(readlink -f $(dirname $0))
echo $DIR
ISO=$DIR/../$1
echo $ISO
xorriso -as mkisofs \
 -isohybrid-mbr isohdpfx.bin \
 -hide-rr-moved \
 -f \
 -r \
 -J \
 -l \
 -V "$VOLUME" \
 -A "$APP" \
 -b isolinux/isolinux.bin \
 -c isolinux/boot.cat \
 -no-emul-boot \
 -boot-load-size 4 \
 -boot-info-table \
 -eltorito-alt-boot \
 -isohybrid-gpt-basdat \
 -e EFI/boot/grubx64.efi \
 -no-emul-boot \
 -o $ISO \
 $DIR
EOF
    sed -i "s/VOLUME_PLACEHOLDER/$isovolume/" "$OUTPUT_SCRIPT"
    sed -i "s/APP_PLACEHOLDER/$isoapplication/" "$OUTPUT_SCRIPT"
    sudo chmod +x "$OUTPUT_SCRIPT"
    if [ ! -f "/usr/lib/ISOLINUX/isohdpfx.bin" ]; then 
        sudo apt install isolinux -y 
    fi
    cp /usr/lib/ISOLINUX/isohdpfx.bin config/includes.binary/isohdpfx.bin
}

add_custom_python_packages(){
    echo "#!/bin/bash

echo "[+] Installing Python packages via pip inside chroot..."

# Optional: Upgrade pip itself
python3 -m pip install --upgrade pip --break-system-packages

# Install desired packages
python3 -m pip install qt-material --break-system-packages" > config/hooks/live/0999-python-pip-install.chroot
}



add_apt_sources() {
    echo "deb http://deb.debian.org/debian/ bookworm main non-free-firmware
        deb-src http://deb.debian.org/debian/ bookworm main non-free-firmware
        deb http://security.debian.org/debian-security bookworm-security main non-free-firmware
        deb-src http://security.debian.org/debian-security bookworm-security main non-free-firmware
        deb http://deb.debian.org/debian/ bookworm-updates main non-free-firmware
        deb-src http://deb.debian.org/debian/ bookworm-updates main non-free-firmware
        " > config/archives/custom.list.chroot
}

run_config(){
    lb config --apt apt \
          --cache true \
          --cache-packages true \
          --cache-stages "bootstrap,chroot" \
          --archive-areas "main contrib non-free non-free-firmware" \
          --apt-options "--no-install-recommends --yes" \
          --iso-volume "$isovolume" \
          --iso-publisher "$isopublisher" \
          --iso-application "$isoapplication" \
          --debootstrap-options "--variant=minbase" \
          --bootappend-live "boot=live components hostname=live-host username=root toram" \
          --binary-images "iso-hybrid" \
          --bootloaders "syslinux,grub-efi"
}

add_luxury_packages(){
    echo "live-task-lxqt
lxqt-about
lxqt-admin
lxqt-branding-debian
lxqt-config
lxqt-core
lxqt-globalkeys
lxqt-notificationd
lxqt-openssh-askpass
lxqt-panel
lxqt-policykit
lxqt-powermanagement
lxqt-qtplugin
lxqt-runner
lxqt-session
lxqt-sudo
adwaita-icon-theme
lxqt-theme-debian
gdisk
hardinfo
konqueror" >> config/package-lists/live.list.chroot 
}
add_minimal_lxqt_packages(){
    echo "live-boot
live-config
live-config-systemd
systemd-sysv
wpasupplicant
network-manager
lshw
python3
python3-pyqt5
python3-pyqt5.qtsvg
python3-pip
firmware-amd-graphics
firmware-ast
firmware-ath9k-htc
firmware-atheros
firmware-bnx2
firmware-bnx2x
firmware-brcm80211
firmware-cavium
firmware-intel-sound
firmware-ipw2x00
firmware-ivtv
firmware-iwlwifi
firmware-libertas
firmware-linux
firmware-linux-free
firmware-linux-nonfree
firmware-misc-nonfree
firmware-myricom
firmware-netronome
firmware-netxen
firmware-nvidia-tesla-535-gsp
firmware-qlogic
firmware-realtek
firmware-realtek-rtl8723cs-bt
firmware-siano
firmware-sof-signed
firmware-tomu
firmware-zd1211
qtbase5-dev
qtchooser
qt5-qmake
qtbase5-dev-tools
task-lxqt-desktop
sddm
iputils-ping
nvme-cli
hdparm
fswebcam
hwinfo
pciutils
sudo
ntpdate
lftp
pulseaudio
pulseaudio-utils
alsa-utils
smartmontools
sg3-utils
util-linux
isolinux" > config/package-lists/live.list.chroot 
}

add_usb_root_identifier(){
    echo "UsbRootIdentifier" > config/includes.binary/UsbRootIdentifier
}

create_new_build(){
    mkdir $FOLDER
    cd $FOLDER
    run_config
    add_apt_sources
    add_minimal_lxqt_packages
    if [ -n "$LUXURY" ]; then
        echo "adding luxury packages"
        add_luxury_packages  
    fi
    add_custom_python_packages
    add_usb_root_identifier
    build_mkgriso_file
    sudo lb build
}
clean(){
    cd $FOLDER
    sudo lb clean --purge
    cd ..
}

help(){
    echo "./script.sh action <options>"
    echo "actions: 
    build (make live-build folder, lb config, copy packages and apt sources, then build)
    rebuild (rm -rf live-build folder, then calls build)"
    echo "options:
    -l add luxury packages
    -f folder name (default:live-build)
    "
}

#mkdir ./live_build_$RANDOM


case $ACTION in
    build)
    create_new_build
    ;;
    rebuild)
    clean
    create_new_build
    ;;
    *)
    help
    ;;
esac
