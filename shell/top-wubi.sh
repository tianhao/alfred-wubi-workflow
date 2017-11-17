#!/bin/bash

source ./functions.sh

subtitle="\"subtitle\": \"五笔版本: ${default_version}\""
touch ${HOME}/Documents/wubi_workflow/${default_version}_top.txt
echo "{\"items\":["
n=0
while read line
do
    echo "{\"title\":\"${line}\", \"arg\": \"${line}\", ${subtitle}}"
    n=$((n+1))
done < <(sort -rg ${HOME}/Documents/wubi_workflow/${default_version}_top.txt | head -100 | cut -d" " -f 2)

if [ ${n} -eq 0 ]; then
    echo "{\"title\":\"没有历史记录\", ${subtitle}}"
fi
echo "]}"
