#!/bin/bash

source ./functions.sh

subtitle="\"subtitle\": \"五笔版本: ${default_version}\""
if [ "${default_version}" != "98" -a  "${default_version}" != "86" ]; then
    echo "{\"items\":[{\"title\":\"WUBI_VERSION 参数设置错误，请设置为86或98\"}]}"
    exit
fi

if [ $# -lt 1 -o "$1" = "" ]; then
    echo "{\"items\":[{\"title\":\"请输入要拆解的汉字\", ${subtitle}}]}"
    exit
fi

declare -a htmlInfo # (一简, 二简, 三简, 全码, 图片URL)
PATH=$PATH:/usr/local/bin

pushd ${HOME}/Documents/wubi_workflow >/dev/null


echo "{\"items\":["

i=0
n=0
string=${1}
max=${#string}
while [ ${i} -lt ${max} ]
do
    current_word=${string:${i}:1}
    index=$(echo ${string/${word}//} | cut -d/ -f1 | wc -m)
    if [ ${index} -ge ${i} -a $(is_chinese ${word}) -gt 0 ];then # 没有拆过且为中文
        chai_word ${default_version} ${word}
        if [ ${BOTH_VERSION:-0} -eq 1 ];then
            chai_word ${other_version} ${word}
        fi
        n=$((n+1))
    fi
    i=$((i+1))
done
if [ ${n} -eq 0 ]; then
    echo "{\"title\":\"请输入要拆解的汉字\", ${subtitle}}"
fi

echo "]}"
