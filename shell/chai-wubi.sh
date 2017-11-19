#!/bin/bash

source ./functions.sh

subtitle="\"subtitle\": \"五笔版本: ${default_version}\""
if [ "${default_version}" != "98" -a  "${default_version}" != "86" ]; then
    echo "{\"items\":[{\"title\":\"WUBI_VERSION 参数设置错误，请设置为86或98\"}]}"
    exit
fi

pushd ${HOME}/Documents/wubi_workflow >/dev/null

if [ $# -lt 1 -o "$1" = "" ]; then
    show_history
#    echo "{\"items\":[{\"title\":\"请输入要拆解的汉字\", ${subtitle}}]}"
    exit
fi
#declare -a htmlInfo # (一简, 二简, 三简, 全码, 图片URL)

echo "{\"items\":["
string=$(echo "${1}"| LC_ALL=UTF-8 sed "s/[[:alnum:][:punct:]]*//g")
if [ "${string}" = "" ]; then
    echo "{\"title\":\"请输入要拆解的汉字\", ${subtitle}}"
else
    chai_line "${string}"
fi

echo "]}"
