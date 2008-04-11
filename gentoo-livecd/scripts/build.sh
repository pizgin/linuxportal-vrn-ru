#!/bin/bash
# Скрипт для создания iso образа
# pizgin@gmail,com

LIVECD=`pwd | sed -r 's/\/[a-zA-Z]+$//'`
TARGET=${LIVECD}/target
TARGET_SOURCE=${TARGET}/files/source/
SOURCE=${LIVECD}/source

rm -rf ${TARGET}
mkdir ${TARGET}
echo "Copy boot"
cp -a ${SOURCE}/boot ${TARGET}/
echo "Copy sources"
mkdir -p ${TARGET}/files/source
cp -p -R -P -d ${SOURCE}/ ${TARGET}/files
echo "Copy complete"

echo "Mounting"
cd ${TARGET}/files
mount -o bind /sys ${TARGET_SOURCE}/sys
mount -o bind /dev ${TARGET_SOURCE}/dev
mount -o bind /proc ${TARGET_SOURCE}/proc

chroot ${TARGET_SOURCE} /bin/bash --login <<CHROOTED
env-update
source /etc/profile
/sbin/depscan.sh
modules-update
find / -xdev -name ".keep" -exec rm -rf {} \;
CHROOTED

umount ${TARGET_SOURCE}/sys
umount ${TARGET_SOURCE}/dev
umount ${TARGET_SOURCE}/proc
env-update
source /etc/profile

cd ${TARGET_SOURCE}
rm -rf var/tmp/*
rm -rf var/run/*
rm -rf var/lock/*
rm -rf var/cache/*
rm -rf var/db
rm -rf tmp/*
rm -f etc/mtab
touch etc/mtab
rm -rf usr/portage
rm -rf etc/portage
rm -rf usr/share/doc
rm root/.bash_history
rm root/.zcompdump
rm root/.bashrc
rm -rf var/log
mkdir var/log
rm etc/make.profile
rm _before_build.sh
rm -rf usr/src/
rm -rf boot
rm info

cd ${TARGET}/files
mksquashfs source/ ${TARGET}/livecd.squashfs
cd ${TARGET}
touch livecd
rm -rf ${TARGET}/files/

cd ${LIVECD}

# GRUB
# mkisofs -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -iso-level 4 -hide boot.catalog -o ${LIVECD}/image.iso ${TARGET}/

# ISOLINUX
mkisofs -R -b boot/isolinux/isolinux.bin -c boot/isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -iso-level 4 -o ${LIVECD}/image.iso ${TARGET}/
