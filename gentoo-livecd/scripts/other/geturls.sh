#!/bin/sh
# Скрипт для вытягивания url'ов из вывода emerge
# pizgin@gmail,com

emerge -pf $@ 2>&1 | awk '/tp:/ { print $1 }' | while read f; do [ ! -s /usr/portage/distfiles/${f##*/} ] && echo $f; done | sort -u > need_files.txt
