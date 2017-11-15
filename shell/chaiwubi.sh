#!/bin/bash

is_chinese(){
    if [ $(echo ${1} | od -t x | tail -1) -gt 2 ];then
        echo 1
    else
        echo 0
    fi
}

chai(){
    htmlInfo=()
    word=$1

    cache=$(egrep "^${word}:" cache.txt)
    if [ ! -z "${cache}" ]; then
        echo ${cache#${word}:}
        return
    fi
    while read line;
    do
        htmlInfo+=("${line}")
    done < <(curl -XPOST "http://www.chaiwubi.com/bmcx?wz=${word}" 2>/dev/null | egrep "的五笔王码${version}版.*码|wubi/${version}tj" | sed 's#^[[:blank:]]*##g' | sed -e 's/<strong.*">//g' | sed 's#</strong>.*##g' | sed 's#<img.*src="##g' | sed 's#".*##g')

    title=""
    ma=""
    # 一简
    if [ "${htmlInfo[0]}" != "" ]; then
        htmlInfo[0]=$(echo ${htmlInfo[0]} | tr 'a-z' 'A-Z')
        title="| ${title}一简: ${htmlInfo[0]} "
        ma="${htmlInfo[0]}"
    fi
    # 二简
    if [ "${htmlInfo[1]}" != "" ]; then
        htmlInfo[1]=$(echo ${htmlInfo[1]} | tr 'a-z' 'A-Z')
        title="${title}| 二简: ${htmlInfo[1]} "
        ma="${htmlInfo[1]}"
    fi
    # 三简
    if [ "${htmlInfo[2]}" != "" ]; then
        htmlInfo[2]=$(echo ${htmlInfo[2]} | tr 'a-z' 'A-Z')
        title="${title}| 三简: ${htmlInfo[2]} "
        ma="${htmlInfo[2]}"
    fi
    # 全码
    if [ "${htmlInfo[3]}" != "" ]; then
        htmlInfo[3]=$(echo ${htmlInfo[3]} | tr 'a-z' 'A-Z')
        title="${title}| 全码: ${htmlInfo[3]} "
        ma="${htmlInfo[3]}"
    fi
    title="${title} |"
    # 图片URL
    if [ "${htmlInfo[4]}" != "" ]; then
        wget -O ${word}.png ${htmlInfo[4]} 2>/dev/null
        convert -crop 25%x100% ${word}.png ${word}_%d.png
    fi

    output="{\"title\":\"${word} => ${title}\"},"
    if [ $(convert ${word}_0.png -colorspace RGB -verbose info:| grep "Colors:" | awk '{print $2}') -gt 1 ]; then
        output="${output}{\"title\":\"${ma:0:1}\", \"icon\": {\"type\": \"file\", \"path\": \"$PWD/${word}_0.png\"}},"
    fi
    if [ $(convert ${word}_1.png -colorspace RGB -verbose info:| grep "Colors:" | awk '{print $2}') -gt 1 ]; then
        output="${output}{\"title\":\"${ma:1:1}\", \"icon\": {\"type\": \"file\", \"path\": \"$PWD/${word}_1.png\"}},"
    fi
    if [ $(convert ${word}_2.png -colorspace RGB -verbose info:| grep "Colors:" | awk '{print $2}') -gt 1 ]; then
        output="${output}{\"title\":\"${ma:2:1}\", \"icon\": {\"type\": \"file\", \"path\": \"$PWD/${word}_2.png\"}},"
    fi
    if [ $(convert ${word}_3.png -colorspace RGB -verbose info:| grep "Colors:" | awk '{print $2}') -gt 1 ]; then
        output="${output}{\"title\":\"${ma:3:1}\", \"icon\": {\"type\": \"file\", \"path\": \"$PWD/${word}_3.png\"}},"
    fi
    echo "${word}:${output}" >> cache.txt
    echo ${output}
}

version=${WUBI_VERSION:-98}
subtitle="\"subtitle\": \"五笔版本: ${version}\""
if [ "${version}" != "98" -a  "${version}" != "86" ]; then
    echo "{\"items\":[{\"title\":\"WUBI_VERSION 参数设置错误，请设置为86或98\"}]}"
    exit
fi

if [ $# -lt 1 -o "$1" = "" ]; then
    echo "{\"items\":[{\"title\":\"请输入要拆解的汉字\", ${subtitle}}]}"
    exit
fi

declare -a htmlInfo # (一简, 二简, 三简, 全码, 图片URL)
PATH=$PATH:/usr/local/bin
mkdir -p ${HOME}/Documents/wubi_workflow/${version}
# pushd $(mktemp -d) >/dev/null
pushd ${HOME}/Documents/wubi_workflow/${version} >/dev/null
touch cache.txt
echo "{\"items\":["

i=0
n=0
string=${1}
max=${#string}
while [ ${i} -lt ${max} ]
do
    word=${string:${i}:1}
    index=$(echo ${string/${word}//} | cut -d/ -f1 | wc -m)
    if [ ${index} -ge ${i} -a $(is_chinese ${word}) -gt 0 ];then # 没有拆过且为中文
        chai ${word}
        n=$((n+1))
    fi
    i=$((i+1))
done
if [ ${n} -eq 0 ]; then
    echo "{\"title\":\"请输入要拆解的汉字\", ${subtitle}}"
fi
echo "]}"
popd >/dev/null
