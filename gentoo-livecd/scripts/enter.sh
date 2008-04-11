#!/bin/sh
# Скрипт для входа в chroot окружение
# pizgin@gmail.com

echo "Mounting..."

mount --bind /proc/ ../source/proc/
mount --bind /dev/ ../source/dev/
mount --bind /sys/ ../source/sys/

if [ ! -e "../source/usr/portage" ]
then
    mkdir ../source/usr/portage
fi

mount --bind /usr/portage ../source/usr/portage

echo "Chroot in"
chroot ../source 

echo "Unmounting..."
umount ../source/proc/
umount ../source/dev/
umount ../source/sys/
umount ../source/usr/portage

echo "Ok"
