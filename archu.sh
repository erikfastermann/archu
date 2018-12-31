#!/bin/bash

# ARCHU - 'Arch your way'
# A hackable and easy install of Arch Linux
# written by Erik Fastermann

# Based on https://wiki.archlinux.org/index.php/installation_guide
# and https://wiki.archlinux.de/title/Anleitung_f%C3%BCr_Einsteiger

# USAGE
# 1. Boot from an Arch installation medium.
# 2. If you are not using the US Keyboard layout:
# loadkeys [YOUR COUNTRY CODE] e.g.: loadkeys de
# 3. Check your Internet connection with 'ping -c4 google.com'
# For Wifi use 'wifi-menu'
# 4.
# curl -LO fastermann.de/archu.sh
# bash archu.sh
# 5. After the script ran successfully,
# you will be prompted for a new root password.
# Then unplug the installation media and 'reboot'


# CONFIG
my_device="/dev/sda" # set the drive/device.
# WARNING: All Data on this device will be lost.
# you can change the partition sizes in the functions below

mirrorlist="Germany" # Pacman mirrorlist, change to country-name with
# servers closest to you ( https://wiki.archlinux.org/index.php/Mirrors )

locale_gen="de_DE ISO-8859-1,de_DE.UTF-8 UTF-8,de_DE@euro ISO-8859-15" 
locale="LANG=de-DE.UTF-8"
keymap="KEYMAP=de-latin1-nodeadkeys"
# separte values with comma
# https://wiki.archlinux.org/index.php/installation_guide#Localization

timezone="Europe/Berlin" # path from zoneinfo 
# https://wiki.archlinux.org/index.php/installation_guide#Time_zone

my_hostname="archu" # set the hostname of your computer



# exit when any command fails
set -e


# parsing strings separated by comma
IFS=","
config_add () {
	for i in $1
	do
	    echo "$i" >> "$2"
	done
}


chk_inet () {
	
	if ! wget --spider --quiet http://www.google.com ; then
		echo "No Internet connection."
		exit 1
	fi
}


clean_device () {
	gdisk "$1" <<- _EOF_
		x
		z
		y
		y
	_EOF_
}

# UEFI Install
# Creating GPT Partition Table with BOOT, ROOT, SWAP
uefi () {
	# change uefi partition sizes here
	gdisk "$1" <<- _EOF_
		n


		512M
		ef00
		n


		-8G
		8300
		n



		8200
		w
		y
		y
	_EOF_
}

# Installing systemd-boot and creating config files
setup_uefi () {
	# Configuring the Boot loader
	arch-chroot /mnt/ bootctl install

	echo "default arch-uefi
	timeout 3" > /mnt/boot/loader/loader.conf

	echo "title		Arch Linux
	linux		/vmlinuz-linux
	initrd		/initramfs-linux.img
	options		root=LABEL=ROOT rw resume=LABEL=SWAP" > /mnt/boot/loader/entries/arch-uefi.conf

	echo "title		Arch Linux Fallback
	linux		/vmlinuz-linux
	initrd		/initramfs-linux-fallback.img
	options		root=LABEL=ROOT rw resume=LABEL=SWAP" > /mnt/boot/loader/entries/arch-uefi-fallback.conf
}

# Creating File systems
# Making Root Partition and mounting it
root_part () {
	mkfs.ext4 -L ROOT "${1}$2"
	mount "${1}$2" /mnt
}

# Making EFI-Boot Partition and mounting it
boot_part () {
	mkfs.fat -F 32 -n EFIBOOT "${1}$2"
	mkdir /mnt/boot
	mount "${1}$2" /mnt/boot
}

# Making Home Partition and mounting it
home_part () {
	mkfs.ext4 -L HOME "${1}$2"
	mkdir /mnt/home
	mount "${1}$2" /mnt/home
}

# Creating and enabling SWAP
swap () {
	mkswap -L SWAP "${1}$2"
	swapon "${1}$2"
}


# Fstab
fstab () {
	genfstab -Lp -U /mnt >> /mnt/etc/fstab
}


# Generating Pacman Mirrorlist
gen_mirrorlist () {
	cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
	grep -E -A 1 ".*${1}.*$" /etc/pacman.d/mirrorlist.bak | sed '/--/d' > /etc/pacman.d/mirrorlist
}

# Installing the base system
install_arch () {
	pacstrap /mnt base base-devel 
}

# Installing and enabling NetworkManager
networkman () {
	arch-chroot /mnt/ pacman -S --noconfirm networkmanager
	arch-chroot /mnt/ systemctl enable NetworkManager
}


# Generating locales (see config vars for customization)
locales () {
	# locale-gen
	config_add "$1" "/mnt/etc/locale.gen"
	
	arch-chroot /mnt/ locale-gen

	# locale
	config_add "$2" "/mnt/etc/locale.conf"

	# Keymap
	config_add "$3" "/mnt/etc/vconsole.conf"

	# Timezone
	ln -sf "/usr/share/zoneinfo/${4}" /mnt/etc/localtime
}


# Setting Hostname
my_hostname_func () {
	echo "$1" > /mnt/etc/hostname
}

# Changing Root Password
root_passwd () {
	arch-chroot /mnt/ passwd
}


# Actual installation and configuration of arch
main () {
	chk_inet

	clean_device "$my_device"
	uefi "$my_device"
	root_part "$my_device" "2"
	boot_part "$my_device" "1"
	swap "$my_device" "3"
	
	gen_mirrorlist "$mirrorlist"
	install_arch
	networkman

	fstab

	setup_uefi

	locales "$locale_gen" "$locale" "$keymap" "$timezone"
	my_hostname_func "$my_hostname"
	root_passwd
}


# user prompt
echo "This script will install and configure Arch Linux 
on your computer with the following settings:
UEFI-Install on '$my_device'
locale-gen: '$locale_gen'
locale: '$locale'
keymap: '$keymap'
timezone: '$timezone'
hostname: '$my_hostname'

If you want to modify this settings,
edit the config section at the beginning of the script.
WARNING: All Files on '$my_device' will be deleted."

read -r -p "Continue (y/n)?" choice
case "$choice" in 
  y|Y ) main;;
  n|N ) echo "cancelling...";;
  * ) echo "invalid, exiting...";;
esac

