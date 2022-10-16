
#!/bin/bash
# https://wiki.archlinux.org/title/Installation_guide

# ----------------------------------------
# Define Variables
# ----------------------------------------

MYTMZ="Europe/Lisbon"   # List possible timezones from: /usr/share/zoneinfo/...
LCLST="pt_PT"
KEYMP="pt-latin1"
KEYMP_gz="pt-latin1.map.gz" 
USRNAME="et"
HSTNAME="et"
USER_PW="user_pw"
ROOT_PW="root_pw"


# disk

disk_boot='sda1'
disk_swap='sda2'
disk_root='sda3'
disk_home='sda4'



#disk_type_SATA_or_MVME="mvme"    # or sata.
disk_type_SATA_or_MVME="sata"    # or sata.
SWAP_SIZE=2GiB  #      SWAP_SIZE=4GiB SWAP_SIZE=8Gib
ROOT_SIZE=30GiB  #     ROOT_SIZE=40GiB .. ROOT_SIZE=60Gib


#desktop_environment="KDE"
desktop_environment="XFCE"
#desktop_environment="LXQt"
#desktop_environment="Mate"
#desktop_environment="Cinnamon"

accept_values="no"    # "yes"
#accept_values="yes"



key_yes_continue_or_leave(){
read -p "Continue ?   (y to continue)" AUX
case $AUX in
y|Y|yes|YES ) continue;;
* ) exit ;;
esac

}



clear
echo "==================================================="
echo "====================  NOTE ======================="
echo "==================================================="
echo "= Based : "
echo "Revision: 2022.01.20 -- by eznix (https://sourceforge.net/projects/ezarch/)"
echo "= "
echo "= "
echo "= "
echo "==================================================="
echo "===================  WARNING ======================"
echo "==================================================="
echo "= This Script doesn´t create partitions "
echo "= They most be already created"
echo "= It ask if you want to DELETE os just Mount it"
echo ""
echo "= If you Need Create Partitions use: fdisk /dev/sda"
echo "= or just live distro "
echo -e "\n"
echo -e "\n"
echo "==================================================="
echo "===============  DEFINED VARIABLES ================"
echo "==================================================="
echo -e "\n"
echo "USER : "${USRNAME}""
echo "USER PW : "${USER_PW}""
echo "ROOT PW : "${ROOT_PW}"..."
echo "HOST NAME : "${HSTNAME}""
echo "LOCATION  : "${LCLST}""
echo "TIME ZONE : "${MYTMZ}""
echo "KEY MAPS  : "${KEYMP}""
echo -e "\n"
echo "==================================================="
echo "/boot : "${disk_boot}""
echo "/swap : "${disk_swap}""
echo "/root : "${disk_root}""
echo "/home : "${disk_home}""

key_yes_continue_or_leave



if [[ "${accept_values}" = "yes" ]]; then
continue
clear
else
echo "ERROR : OPEN FILE AND EDIT/accept THE VARIABLES"
sleep 4
exit
fi

echo "LAODING KEY MAPS  : "${KEYMP}""
# keyboard language
loadkeys ${KEYMP}



echo "==================================================="
echo "===========  INTERNET CONNECTON CHECK ============="
echo "==================================================="
ping google.com
key_yes_continue_or_leave

echo "==================================================="
echo "= Sync repositories                               ="
echo "= Install Reflector                               ="
echo "= Create mirrorlist                               ="
echo "= install latest keyring                          ="
echo "==================================================="

pacman -Sy
pacman -S archlinux-keyring
pacman -S --needed reflector
reflector --latest 10 --protocol https --save /etc/pacman.d/mirrorlist


echo "==================================================="
echo "============  CHECK for UEFI or BIOS =============="
echo "==================================================="
echo "= Directory without error ->  UEFI mode"
echo "= Directory does not exist -> may be BIOS (or CSM)"
echo "==================================================="
read -p "Press any key to Continue " AUX
echo -e "\n"
echo -e "\n"

ls /sys/firmware/efi/efivars

echo -e "\n"
echo "==================================================="
echo "= Directory without error ->  UEFI mode"
echo "= Directory does not exist -> may be BIOS (or CSM)"
echo "==================================================="
key_yes_continue_or_leave


#Update the system clock
timedatectl set-ntp true
timedatectl status

echo "==================================================="
echo "===============  CHECK for DISCK =================="
echo "==================================================="
fdisk -l


echo "===============  FORMAT PARTITIONS =================="
echo "= Format BOOT / EUFI  :  mkfs.fat -F 32 /dev/"${disk_boot}"?"
echo "= If formated will  destroy the boot loaders of other installed operating systems."
read -p "= Format Boot / EUFI ?   (type: yes) : " AUX
  if [[ "${AUX}" = "yes" ]]; then
        key_yes_continue_or_leave
        mkfs.fat -F 32 /dev/"${disk_boot}" 
        echo "= BOOT / EUFI is formated"
  else
        echo "nothing was done to /dev/"${disk_boot}""
  fi
echo ""
echo "===============  FORMAT PARTITIONS =================="
echo "= Formating swap : mkswap /dev/"${disk_swap}""
mkswap /dev/"${disk_swap}"
echo "===============  FORMAT PARTITIONS =================="
echo "= Formating /root : mkfs.ext4 /dev/"${disk_root}" "
mkfs.ext4 /dev/"${disk_root}"   #root
echo "===============  FORMAT PARTITIONS =================="
echo "= Format /home : mkfs.ext4 /dev/"${disk_home}"  ?"
echo "= If formated will destroy /home files."
read -p "= Format /home ?   (type: yes) : " AUX
  if [[ "${AUX}" = "yes" ]]; then
        key_yes_continue_or_leave
        mkfs.ext4 /dev/"${disk_home}"  #home 
        echo "= /home is formated"
  else
        echo "nothing was done to /dev/"${disk_home}""
  fi
echo ""

clear
echo "===============  MOUNT PARTITIONS =================="
mount /dev/"${disk_root}" /mnt
mkdir -p /mnt/boot
mount /dev/"${disk_boot}" /mnt/boot
mkdir /mnt/home
mount /dev/"${disk_home}" /home
swapon /dev/"${disk_swap}"

echo ""
read -p "Press any key to Continue " AUX
clear
echo "==================================================="
echo "=========  Install essential packages ============="
echo "==================================================="
pacstrap /mnt base linux linux-firmware base-devel cryptsetup dialog e2fsprogs device-mapper dhcpcd dosfstools efibootmgr gptfdisk grub inetutils less linux-lts linux-firmware lvm2 mkinitcpio mtools nano netctl nvme-cli os-prober reflector rsync sysfsutils xz zstd
clear
echo "==================================================="
echo "=========   Configure the system   ============="
echo "==================================================="
echo "= Create Fstab"
genfstab -U /mnt >> /mnt/etc/fstab
echo "= Chroot into system"
#arch-chroot /mnt
echo "= Configure timezone"
arch-chroot /mnt rm -rf /etc/localtime
arch-chroot /mnt ln -sf /usr/share/zoneinfo/"${MYTMZ}" /etc/localtime
echo "= Running hwclock(8) to generate /etc/adjtime"
hwclock --systohc --utc
timedatectl set-ntp true
echo "= Configure locale"
echo "= Edit /etc/locale.gen and uncomment:  "
echo "=           en_US.UTF-8 UTF-8          "
echo "=           and other needed locales   "
read -p "Press any key to Continue " AUX
nano /mnt/etc/locale.gen
echo "= Generate the locales "
locale-gen
echo ""${LCLST}".UTF-8 UTF-8" >> /mnt/etc/locale.gen
echo "LANG="${LCLST}".UTF-8" > /mnt/etc/locale.conf
echo "KEYMAP="${KEYMP}"" > /mnt/etc/vconsole.conf
arch-chroot /mnt locale-gen
arch-chroot /mnt localectl set-locale LANG="${LCLST}".UTF-8
arch-chroot /mnt localectl set-keymap "${KEYMP}"
echo "= Network configuration"
echo ""${HSTNAME}"" > /mnt/etc/hostname
echo "127.0.0.1          localhost" >> /mnt/etc/hosts
echo "::1          localhost" >> /mnt/etc/hosts
echo "127.0.1.1          "${HSTNAME}".localdomain "${HSTNAME}"" >> /mnt/etc/hosts

echo "==================================================="
echo "======= Create root password and user   ==========="
echo "==================================================="
echo "= ROOT Password"
passwd root
echo "= ADD "${USRNAME}" "
useradd -m -G sys,log,network,floppy,scanner,power,rfkill,users,video,storage,optical,lp,audio,wheel,adm -s /bin/bash "${USRNAME}"
passwd "${USRNAME}"
export VISUAL=nano
export EDITOR=nano

echo "= Configure locale"
echo "= will edit /etc/sudoers and uncomment:  "
echo "=           %wheel ALL=(ALL) ALL          "
read -p "Press any key to Continue " AUX
sudo nano /etc/sudoers

echo "==================================================="
echo "= Sync repositories, ="
echo "= Install Reflector ="
echo "= Create mirrorlist ="
echo "==================================================="
pacman -S reflector
reflector --latest 10 --protocol https --save /etc/pacman.d/mirrorlist

echo "==================================================="
echo "================ Install GRUB   ==================="
echo "==================================================="
pacman -S grub efibootmgr os-prober
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
echo "= Initramfs"  # 18. Run mkinitcpio -- linux-lts for long term support kernel, linux for standard kernel
#mkinitcpio -p linux-lts
mkinitcpio -p linux
echo "= boot loader."



echo "==================================================="
echo "================== SOFTWARE   ====================="
echo "==================================================="
echo "= Xorg"
pacman -S xorg xorg-apps xorg-server xorg-drivers xorg-xkill xorg-xinit xterm mesa
echo "= General"
pacman -S --needed amd-ucode arch-install-scripts archiso bash-completion bind-tools bluez bluez-utils btrfs-progs cdrtools cmake dd_rescue ddrescue devtools diffutils dkms dvd+rw-tools efitools exfatprogs f2fs-tools fatresize fsarchiver fuse3 fwupd git gnome-disk-utility gnome-keyring gpart gparted grsync gvfs gvfs-afc gvfs-goa gvfs-gphoto2 grsync gvfs-mtp gvfs-nfs gvfs-smb hardinfo haveged hdparm htop hwdata hwdetect hwinfo intel-ucode jfsutils mkinitcpio-archiso mkinitcpio-nfs-utils libburn libisofs libisoburn linux-lts-headers logrotate lsb-release lsscsi man-db man-pages mdadm ntfs-3g p7zip pacutils packagekit pacman-contrib pahole papirus-icon-theme parted perl perl-data-dump perl-json perl-lwp-protocol-https perl-term-readline-gnu perl-term-ui pkgfile plocate polkit pv qt5ct reiserfsprogs rsync s-nail sdparm sg3_utils smartmontools squashfs-tools sudo testdisk texinfo tlp udftools udisks2 unace unrar unzip usbmuxd usbutils vim which xdg-user-dirs xfsprogs
echo "= Multimedia"
pacman -S --needed alsa-lib alsa-plugins alsa-firmware alsa-utils audacious audacious-plugins cdrdao dvdauthor faac faad2 ffmpeg ffmpegthumbnailer flac frei0r-plugins gstreamer gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gstreamer-vaapi imagemagick lame libdvdcss libopenraw mencoder mjpegtools mpv poppler-glib pulseaudio pulseaudio-alsa pulseaudio-bluetooth pulseaudio-equalizer pulseaudio-jack simplescreenrecorder sox transcode smplayer x265 x264 xvidcore
echo "= Networking"
pacman -S --needed avahi b43-fwcutter broadcom-wl-dkms curl dhclient dmraid dnsmasq dnsutils ethtool firefox ipw2100-fw ipw2200-fw iwd gnu-netcat net-tools netctl net-tools networkmanager networkmanager-openvpn network-manager-applet nm-connection-editor nfs-utils nilfs-utils nss-mdns openconnect openresolv openssh openssl openvpn r8168 samba vsftpd wget wireless-regdb wireless_tools whois wpa_supplicant
echo "= Fonts"
pacman -S --needed ttf-ubuntu-font-family ttf-dejavu ttf-bitstream-vera ttf-liberation noto-fonts ttf-roboto ttf-opensans opendesktop-fonts cantarell-fonts freetype2
echo "= Printing"
pacman -S --needed cups cups-pdf cups-filters cups-pk-helper foomatic-db foomatic-db-engine ghostscript gsfonts gutenprint python-pillow python-pip python-pyqt5 python-reportlab simple-scan system-config-printer
echo "= others"
pacman -S --needed neofetch


echo "==================================================="
echo "==================== Desktop ======================"
echo "==================================================="

if [[ "${desktop_environment}" = "KDE" ]]; then
      pacman -S --needed accountsservice aisleriot ark bluedevil breeze-icons bluez-qt cryfs discover dolphin encfs geany gocryptfs guvcview gwenview k3b kcalc kinit konsole kwrite meld  networkmanager-qt okular packagekit-qt5 papirus-icon-theme pavucontrol-qt plasma print-manager qbittorrent sddm sddm-kcm sweeper
fi

if [[ "${desktop_environment}" = "XFCE" ]]; then
      pacman -S --needed accountsservice adapta-gtk-theme aisleriot arc-gtk-theme arc-icon-theme asunder blueman catfish dconf-editor epdfview galculator geany gnome-firmware gnome-packagekit gtk-engine-murrine guvcview meld  papirus-icon-theme pavucontrol polkit-gnome sddm  transmission-gtk xarchiver xfburn xfce4 xfce4-goodies
fi

if [[ "${desktop_environment}" = "LXQt" ]]; then
      pacman -S --needed accountsservice aisleriot bluedevil bluez-qt breeze-icons discover epdfview galculator geany guvcview k3b kwrite lxqt lxqt-sudo meld  networkmanager-qt obconf-qt openbox packagekit-qt5 papirus-icon-theme pavucontrol-qt pcmanfm-qt polkit-qt5 qbittorrent qterminal sddm sddm-kcm xarchiver xscreensaver

fi

if [[ "${desktop_environment}" = "Mate" ]]; then
      pacman -S --needed accountsservice adapta-gtk-theme aisleriot arc-gtk-theme arc-icon-theme asunder blueman brasero dconf-editor geany gnome-firmware gnome-packagekit gtk-engine-murrine guvcview mate mate-applet-dock mate-extra mate-polkit meld  papirus-icon-theme sddm transmission-gtk
fi

if [[ "${desktop_environment}" = "Cinnamon" ]]; then
      pacman -S --needed accountsservice adwaita-icon-theme adapta-gtk-theme aisleriot arc-gtk-theme arc-icon-theme asunder blueman brasero cinnamon cinnamon-translations dconf-editor epdfview file-roller geany gnome-firmware gnome-packagekit gnome-terminal gtk-engine-murrine guvcview meld nemo nemo-fileroller nemo-share  papirus-icon-theme pavucontrol polkit-gnome sddm tldr tmux transmission-gtk viewnior xed

fi

echo "==================================================="
echo "================ Enable services =================="
echo "==================================================="
systemctl disable dhcpcd.service
systemctl enable bluetooth.service
systemctl enable cups.service
systemctl enable NetworkManager
echo "= SDDM Display Manager"

systemctl enable sddm.service
echo "==================================================="
echo "================ Exit chroot =================="
exit (arch-chroot)
umount -a
reboot



