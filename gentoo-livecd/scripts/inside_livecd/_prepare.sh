#!/bin/sh
# Скрипт для первичного конфигурирования системы (выполняется в chroot окружении один раз!)
# pizgin@gmail.com

function prepare()
{
    echo "Prepare..."
    
    # Устанавливаем имя машины
    echo 'HOSTNAME="tux"' > /etc/conf.d/hostname
    
    # Устанавливаем имя домена
    echo 'dns_domain="home.lan"' >> /etc/conf.d/net
    echo 'config_eth0=( "dhcp" )' >> /etc/conf.d/net
    sed -i -e "s/^127.0.0.1.*localhost$/127.0.0.1\ttux.home.lan tux localhost.localdomain localhost/g" /etc/hosts
    
    # Устанавливаем ссылку на профиль по-умолчанию
    rm /etc/make.profile
    ln -sfv /usr/portage/profiles/default-linux/x86/2007.0/desktop /etc/make.profile

# Устанавливаем USE флаги
(
cat <<'EOF' 
LINGUAS="ru en"
USE="livecd slang -gnome -gtk -java -doc -arts fbcondecor"
MAKEOPTS="-j2"
INPUT_DEVICES="keyboard mouse"
EOF
) >> /etc/make.conf

# Создаем /etc/fstab
(
cat <<'EOF' 
/dev/loop0              /               squashfs        rw,defaults     0 0
none                    /proc           proc            defaults        0 0
none                    /dev/shm        tmpfs           rw,defaults     0 0

EOF
) > /etc/fstab

    # Обновляем окружение, перезагружаем службы
    env-update
    source /etc/profile
}

function rus()
{
    echo "Russification..."    

    # Устанавливаем часовой пояс
    ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
    
    # В файле /etc/conf.d/clock меняем UTC на Local и раскоментироваем 
    # строку с TIMEZONE и устанавливаем ей значение "Europe/Moscow"
    sed -i -e "s/#TIMEZONE=\"Factory\"/TIMEZONE=\"Europe\/Moscow\"/g" /etc/conf.d/clock
    sed -i -e "s/CLOCK=\"UTC\"/CLOCK=\"Local\"/g" /etc/conf.d/clock
    
    # Создаем русскую и английскую локали
    cat /usr/share/i18n/SUPPORTED | grep -E 'ru_RU|en_US' > /etc/locale.gen && locale-gen
    
    # В файле /etc/conf.d/consolefont меняем шрифт "default_8x16" на "Cyr_a8x16"
    sed -i -e "s/default8x16/Cyr_a8x16/g" /etc/conf.d/consolefont
    
    # Создаем файл /etc/env.d/02locale
    echo -e 'LANG="ru_RU.UTF-8" \nLC_ALL="" \n' > /etc/env.d/02locale
    
    # В файле /etc/conf.d/keymaps меняем раскладку "us" на "ru4", 
    # а параметру DUMPKEYS_CHARSET устанавливаем значение "koi8-r"
    sed -i -e "s/KEYMAP=\"us\"/KEYMAP=\"ru4\"/g" /etc/conf.d/keymaps
    sed -i -e "s/DUMPKEYS_CHARSET=\"\"/DUMPKEYS_CHARSET=\"koi8-r\"/g" /etc/conf.d/keymaps
    
    # Обновляем окружение, перезагружаем службы
    env-update
    source /etc/profile
    # /etc/init.d/consolefont restart
    # /etc/init.d/keymaps restart
}

prepare
rus

