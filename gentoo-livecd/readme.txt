Создание LiveCD дистрибутива на базе Gentoo Linux

Версия 1.4 от 23.03.2008
e-mail: pizgin@gmail.com


Введение

В руководстве рассказывается о том как создать свой LiveCD диск на основе Gentoo 
Linux. Диск будет полностью русифицирован, произведена установка KDE и
обеспечено автоматическое монтирование flash накопителей. В качестве загрузчика 
рассматривается ISOLINUX. Раньше был GRUB, но пришлось от него отказаться, так как он не
работает на некоторых ноутбуках. Созданный по этой инструкции диск можно будет
постоянно совершенстовать, устанавливать новые пакеты, вообщем можно делать все то что
можно делать с обычным дистрибутивом установленным на вашем ПК.


Подготовительные действия

Для сборки необходимо создать определенную структуру каталогов, где создавать
- в принципе без разницы. Я создавал в домашней директории. Структура
следующая: 

livecd
 conf		// набор конфигурационных файлов
 source		// создаваемый дистрибутив
 scripts	// набор вспомогательных скриптов
 distr		// исходники: portage, stage, может картинки какие-то и пр.
 target		// здесь сборочный скрипт будет создавать squashfs образ

Создаем:
$ cd ~
$ mkdir -p livecd/{conf,distrib,scripts,source,target}

Теперь из прикрепленного к статье файла, берем его содержимое и распихиваем по
указанным директориям.

Собирать livecd будем из второй стадии. Скачиваем ее из сети и копируем в
distr и распаковываем в каталог сборки. Распаковывать следует с root правами,
иначе будут проблемы с созданием устройств в каталоге /dev.

# tar -C source/ -pxjvf distrib/stage2-i686-2007.0.tar.bz2

Архив с портеджами и дистфайлами распаковывать в каталог сборки не будем. 
Вместо этого скрипты будут автоматически монтировать эти каталоги от основной 
системы. 

Для того чтобы легко отличать консоль в chroot окружении от консоли основной системы, 
рекомендую для первой изменить приглашение коммандной строки и вместо просто "#" 
написать например "(LIVECD) #". Для этого копируем заготовленный в conf директории файл 
root/bashrc в каталог source/root/ (добавив в начало названия точку).

Для сборки образа, на ПК предварительно должны быть установлены 
пакеты squashfs-tools и cdrtools. Первый для работы с файловой системой SquashFS,
второй для записи CD дисков. 

# emerge -av squashfs-tools cdrtools


Собираем базовую систему

Сейчас можно входить (chroot'иться как еще говорят) в собираемую систему и
начианать подгонять ее под свои поотребности.

# cd scripts
# ./enter.sh

Если все прошло нормально - на экране не должно быть никаких ругательных
сообщений, а приглашение коммандной строки выглядеть вот так: "(LIVECD) #". 
Сейчас мы находимся в только-что распакованной из stage2 системе.

Общий план работ таков: 
1) Установить имя машины/домена, профиль, дописать USE флагов в make.conf, 
   создать /etc/fstab.
2) Установить часовой пояс, перевести часы в режим Local, сгенерировать
русские локали, установить русскую расскладку клавиатуры и экранный шрифт.
3) Выполнить emerge -e system и emerge -e world для получения Stage3.
4) Не забыть установить пароль root'у.
5) Собрать ядро, настроить загрузчик и попробовать перезагрузиться.
6) Установаить свои приложения.
7) Создать ISO образ и записать его на диск.

Первые два пункта за вас может выполнить подготовленный скрипт "_prepare.sh".
Написан он был потому как собрать livecd получилось не с первого раза, и
делать одно и тоже на только-что распакованных stage-2 порядком надоело. Его
нужно скопировать куда нибудь в source директорию и выполнить один раз для
свеже распакованного stage-2. Скопировать можно например в /root или прямо в 
корень (важно не забыть перед созданием ISO образа его оттуда удалить).

Итак начинаем:
Напомню что все действия происходят в chroot окружении.

1. Подготавливаем и русифицируем систему.
(LIVECD) # ./_prepare.sh
(LIVECD) # rm _prepare.sh

2. Устанавливаем основные утилиты для управления пакетами
(LIVECD) # emerge -av gentoolkit

3. Собираем Stage3
(LIVECD) # emerge -e system
Обновляем конфигурационные файлы обновленных приложений
(LIVECD) # dispatch-conf
Здесь нужно быть внимательным и не затереть те конфигурационные файлы которые
мы сами изменяли (или их изменил скрипт _prepare.sh). Это касается русского
шрифта, раскладки клавиатуры и прочее. Вообщем прежде чем в ответ на вопрос
dispatch-conf'a жать 'u', внимательно посмотрите какой файл он хочет обновить.
Если это файлы: clock, consolefont, hostname или keymaps - жмите 'z' (не
обновлять).

Проверям целостность зависимостей системы
(LIVECD) # revdep-rebuild

Тоже самое про мир, пересобираем, обновляем конфигурационные файлы и проверяем
целостность зависимостей.
(LIVECD) # emerge -e world
(LIVECD) # dispatch-conf
(LIVECD) # revdep-rebuild

Пересборка system на Turion64X2 заняла приблизительно 2.5 часа, world - 3 ч.

При emerge -e system могут быть проблемы с perl. Если такое случиться - 
делать так (ставиться будет примерно минут 15):
(LIVECD) # emerge --oneshot gdbm db
(LIVECD) # emerge -N --oneshot --nodeps perl

После можно снова пробовать emerge -e system.

Возможно где-то в середине сборка system прервется с ошибкой на пакете 
sys-apps/attr. Ошибка будет выглядеть так: "libexpat.so.0: cannot open shared 
objects file: No such file or directory". Если это случилось - создаем сиволическую ссылку 
с libexpat.so на libexpat.so.0, и затем пробуем продолжить сборку, т.е. делаем

(LIVECD) # ln -s /usr/lib/libexpat.so /usr/lib/libexpat.so.0
(LIVECD) # emerge --resume

Обнаружил небольшой недочет при сборке с использованием portage от
05.03.2008. emerge -e system прерывается на пакете 'which-2.19' с ошибкой
"error: readline/rlstdc.h: No such file or directory". На момент сборки
этого пакета уже должна стоять библиотека readline, но ее нет. Устанавливаем
ее сами и продолжаем сборку system. Если подробно, то:

(LIVECD) # emerge -av readline
(LIVECD) # emerge --resume

Если будут еще какие-либо проблемы - скачайте или обновитесь до самого свежего 
архива портеджей. Не поможет - идите на bugzilla.gentoo.org. 

4. Устанавливаем пароль root'у
(LIVECD) # passwd 

5. Создаем пользователя livecd
(LIVECD) # useradd -m -G users,wheel,audio,video,cdrom,cdrw,usb -s /bin/bash livecd
(LIVECD) # passwd livecd

6. Устанавливаем splash темы для красивой графической загрузки
(LIVECD) # emerge -av splash-themes-livecd

7. Устанавливаем и компилируем ядро
(LIVECD) # emerge -av gentoo-sources

genkernel должен быть не старее чем 3.4.10_pre4. На момент написания этого
руководства такой версии в стабильной ветке небыло. Если у вас тоже-самое -
разрешаем устанавливать его из тестовой (~x86), для этого выполним
(LIVECD) # echo 'sys-kernel/genkernel ~x86' >> /etc/portage/package.keywords

(LIVECD) # emerge -av genkernel
(LIVECD) # genkernel all --gensplash=livecd-2007.0

8. Устанавливаем и добавляем в автозагрузку Gentoo LiveCD скрипты
Снимаем маскировку (установлена разработчиками для того чтобы предупредить о
том, что скрипты предназначены только для использования вместе с livecd)
(LIVECD) # echo 'app-misc/livecd-tools' >> /etc/portage/package.unmask
(LIVECD) # echo 'x11-misc/mkxf86config' >> /etc/portage/package.unmask
(LIVECD) # echo 'sys-apps/hwsetup' >> /etc/portage/package.unmask

livecd-tools нужен версии не ниже 1.0.40_pre1. На момент написания этого
руководства такой версии в стабильной ветке небыло. Если у вас тоже-самое -
разрешаем устанавливать его из тестовой (~x86), для этого выполним
(LIVECD) # echo 'app-misc/livecd-tools ~x86' >> /etc/portage/package.keywords

(LIVECD) # emerge -av livecd-tools

библиотека libkudzu должна быть версии не ниже чем 1.2.57.1,
если будет устанавливаться более старая версия - отвечаем 'no' и разрешаем
libkudzu из тестовой ветки.

(LIVECD) # echo 'sys-libs/libkudzu ~x86' >> /etc/portage/package.keywords

(LIVECD) # rc-update add autoconfig default

9. Устанавливаем загрузчик
(LIVECD) # emerge -av syslinux
(LIVECD) # mkdir /boot/isolinux
(LIVECD) # cp /usr/lib/syslinux/isolinux.bin /boot/isolinux
(LIVECD) # cp /boot/kernel-genkernel-x86-2.6.23-gentoo-r6/boot/isolinux/vmlinuz
(LIVECD) # cp /boot/initramfs-genkernel-x86-2.6.23-gentoo-r6 /boot/isolinux/initrd
Из директории с конфиг. файлами копируем в /boot/isolinux файл isolinux.cfg.

10. Создаем образ и пробуем его загрузить.
Выходим из chroot окружения и запускаем скрипт "build.sh"
(LIVECD) # exit
# ./build.sh
Процесс сборки образа длиться примерно минут 5. После него забираем iso файл
в директории livecd. Можно записать его на болванку, но лучше для этих целей 
поставить например VirtualBox или VMWare, потому как удобнее и быстрее. 

Записать на CD можно так:
# cdrecord -v -eject speed=10 fs=8m dev=/dev/cdrw image.iso
или если это DVD то так:
# growisofs -dvd-compat -Z /dev/dvd=image.iso

Образ должен загрузиться, когда дойдет до приглашения - введите root и ваш пароль. 
Если все так - пол дела сделано. LiveCD грузиться. Сейчас желательно создать архив 
с каталогом livecd на случай если при дальнейших манипуляциях что нибудь пойдет
не так - можно будет откатиться.


Установка KDE

1. Устанавливаем Xorg
(LIVECD) # emerge -av xorg-server

2. Устанавливаем оригинальный драйвера nVidia
(LIVECD) # emerge -av nvidia-drivers

3. Правим таблицу соответсвия устройство - драйвер для nVidia карт 
Открываем файл /usr/share/hwdata/Cards.
3.1. Находим строку NAME NVIDIA Legacy и меняем название драйвера 
     'vesa' на 'nv'.
3.2. Находим строку NAME NVIDIA GeForce и меняем название драйвера с 
     'vesa' на 'nvidia'.

4. Устанавливаем минимальный набор KDE
(LIVECD) # emerge -av kdm kdebase-startkde kde-i18n

5. Добавляем в автозапуск xdm и указываем в нем запускемый оконный менеджер
В файле /etc/conf.d/xdm переменной DISPLAYMANAGER присваиваем значение "kdm"
(LIVECD) # rc-update add xdm default

6. Настройка автомонтирования съемных устройств
(LIVECD) # emerge -auv dbus hal pmount
(LIVECD) # rc-update add dbus default
(LIVECD) # rc-update add hald default
(LIVECD) # gpasswd -a livecd plugdev

7. Включаем русскую раскладку и переключатель en/ru
7.1. Открываем файл /usr/sbin/mkxf86config.sh и удаляем строку вида
"-e 's|"XkbLayout" *"[^"]*"|"XkbLayout" "'"${XKEYBOARD}"'"|g;'"${DEADKEYS}" \"

7.2. Открываем файл /etc/X11/xorg.conf.in и в секции InputDevice, Keyboard0 
меняем последние три строчки на следующие:

Option     "XkbLayout"     "us,ru(winkeys)"
Option     "XkbVariant"    "us"
Option     "XkbOptions"    "grp:alt_shift_toggle,grp_led:scroll"


Что еще можно сделать

* Автологин в текстовой консоли не под root'ом

1. Устанавливаем mingetty
(LIVECD) # emerge -av mingetty

2. Прописываем его в /etc/inittab вместо agetty.
Как было:
c1:12345:respawn:/sbin/agetty 38400 tty1 linux
Как нужно исправить:
c1:12345:respawn:/sbin/mingetty --autologin root --noclear tty1
Естественно что вместо root можно вписать любого пользователя.

3. Правим файл /sbin/rc

Находим вот такую секцию (приблизительно это строка N 500)

if [ -f "/sbin/livecd-functions.sh" -a -n "${CDBOOT}" ]
then
	ebegin "Updating inittab"
	livecd_fix_inittab
	eend $?
	/sbin/telinit q &>/dev/null
fi

и делаем ее такой

if [ -f "/sbin/livecd-functions.sh" -a -n "${CDBOOT}" ]
then
	ebegin "Updating inittab"
	/bin/true #livecd_fix_inittab
	eend $?
	/bin/true #/sbin/telinit q &>/dev/null
fi

* Свое сообщение после init'a

Открываем файл /sbin/rc, ищем строку вида 'echo -e " Copyright' и добавляем
ниже нее свое сообщение.

* Автологин в KDE

Открываем файл /usr/kde/3.5/share/config/kdm/kdmrc и прописываем пользователя
в строки 'DefaultUser' и 'AutoLoginUser'.

* Красивый, настроенный и подогнанный под себя рабочий стол

Запускаем созданный LiveCD, загружаемся в KDE и настраиваем его под себя. Все,
шрифты, поведение окон, курсор занятости, панели и пр. Затем сжимаем свой
домашний каталог (/home/livecd) и копируем его на флешку. Выходим из LiveCD,
chroot'имся в source и распаковываем в каталог /home/livecd/ сохраненные на флешке 
настройки.


Приложение

* Версии основных используемых пакетов

 sys-fs/squashfs-tools-3.1_p2
 app-misc/livecd-tools-1.0.40_pre1
 sys-kernel/genkernel-3.4.10_pre4
 sys-kernel/gentoo-sources-2.6.23-r9
 sys-apps/hwdata-gentoo-0.3
 sys-apps/hwsetup-1.2
 x11-misc/mkxf86config-0.9.9

 stage2-i686-2007.0.tar.bz2
 portage-20080305.tar.bz2
 
