#!/bin/bash



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
          --iso-volume "ITAD OS" \
          --iso-publisher "Michael Knudsen" \
          --iso-application "ITAD Platform (Debian 12)" \
          --debootstrap-options "--variant=minbase" \
          --bootappend-live "boot=live components hostname=live-host username=root toram" \
          --binary-images "iso-hybrid" \
          --bootloaders "syslinux,grub-efi"
}

add_packages(){
    echo "live-boot
    live-config
    live-config-systemd
    systemd-sysv
    wpasupplicant
    network-manager
    lshw
    python3
    python3-pyqt5
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
    lftp" > config/package-lists/live.list.chroot 
}
create_new_build(){
    mkdir ./live-build/
    cd live-build
    run_config
    add_apt_sources
    add_packages
    sudo lb build
}
clean(){
    #echo "deleting live build folder"
    #sudo rm -rf live-build
    cd live-build
    sudo lb clean --purge
    cd ..
}

help(){
    echo "No option provided"
    echo "options: 
    build (make live-build folder, lb config, copy packages and apt sources, then build)
    rebuild (rm -rf live-build folder, then calls build)"
}

#mkdir ./live_build_$RANDOM

case $1 in
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
