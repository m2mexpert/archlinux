#! /bin/bash
echo "Joe's Way Cool Arch Installer"

# Set up network connection
read -p 'Are you connected to internet? [y/N]: ' neton
if ! [ $neton = 'y' ] && ! [ $neton = 'Y' ]
then 
    echo "Connect to internet to continue..."
    exit
fi

# Filesystem mount warning
echo "This script will create and format the partitions as follows:"
echo "/dev/vda1 - 512Mib will be mounted as /boot/efi"
echo "/dev/vda2 - 16GiB will be used as swap"
echo "/dev/vda3 - rest of space will be mounted as /"
read -p 'Continue? [y/N]: ' fsok
if ! [ $fsok = 'y' ] && ! [ $fsok = 'Y' ]
then 
    echo "Edit the script to continue..."
    exit
fi

# to create the partitions programatically (rather than manually)
# https://superuser.com/a/984637
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/vda
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
  +512M # 512 MB boot parttion
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +16G # 16 GB swap parttion
  n # new partition
  p # primary partition
  3 # partion number 3
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  a # make a partition bootable
  1 # bootable partition is partition 1 -- /dev/vda1
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

# Format the partitions
mkfs.ext4 /dev/vda3
mkfs.fat -F32 /dev/vda1

# Set up time
timedatectl set-ntp true

# Initate pacman keyring
pacman-key --init
#pacman-key --populate archlinux
#pacman-key --refresh-keys

# Mount the partitions
mount /dev/vda3 /mnt
mkdir -pv /mnt/boot/efi
mount /dev/vda1 /mnt/boot/efi
mkswap /dev/vda2
swapon /dev/vda2

# Install Arch Linux
echo "Starting install.."
echo "Installing Arch Linux, KDE with Konsole and Dolphin and GRUB2 as bootloader" 
pacstrap /mnt base base-devel zsh grml-zsh-config grub os-prober linux linux-firmware intel-ucode efibootmgr dosfstools openssh freetype2 fuse2 mtools iw wpa_supplicant dialog xorg xorg-server xorg-xinit mesa xf86-video-intel plasma konsole dolphin

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Copy post-install system cinfiguration script to new /root
cp -rfv /root/archlinux/post-install.sh /mnt/root
chmod a+x /mnt/root/post-install.sh

# Chroot into new system and run remaining setup
arch-chroot /mnt /root/post-install.sh

# Finish
echo "If post-install.sh was run succesfully, you will now have a fully working bootable Arch Linux system installed."
echo "The only thing left is to reboot into the new system."
echo "Press any key to reboot or Ctrl+C to cancel..."
read tmpvar
reboot
