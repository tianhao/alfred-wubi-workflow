#!/usr/bin/env bash

is_chinese(){
    if [ $(echo ${1} | od -t x | tail -1) -gt 2 ];then
        echo 1
    else
        echo 0
    fi
}

## 拆一个字
chai_word(){
    local current_version=$1
    local current_word=$2
    local htmlInfo=()
    local cache=$(egrep "^${current_word}:" ${current_version}_cache.txt)
    if [ ! -z "${cache}" ]; then
        echo ${cache#${current_word}:}
        new_val=$(egrep "[[:digit:]]* ${current_word}" ${current_version}_top.txt | awk '{print $1+1" "$2}')
        sed -i ".bak" "s/[[:digit:]]* ${current_word}/${new_val}/g" ${current_version}_top.txt
        rm -f *_top.txt.bak
        return
    fi
    local line=""
    while read line;
    do
        htmlInfo+=("${line}")
    done < <(curl -XPOST "http://www.chaiwubi.com/bmcx?wz=${current_word}" 2>/dev/null | egrep "的五笔王码${current_version}版.*码|wubi/${current_version}tj" | sed 's#^[[:blank:]]*##g' | sed -e 's/<strong.*">//g' | sed 's#</strong>.*##g' | sed 's#<img.*src="##g' | sed 's#".*##g')

    local title=""
    local ma=""
    local sp=""
    local output=""
    # 一简
    if [ "${htmlInfo[0]}" != "" ]; then
        htmlInfo[0]=$(echo ${htmlInfo[0]} | tr 'a-z' 'A-Z')
        title="${htmlInfo[0]}₁"
        ma="${htmlInfo[0]}"
        sp=" — "
    fi
    # 二简
    if [ "${htmlInfo[1]}" != "" ]; then
        htmlInfo[1]=$(echo ${htmlInfo[1]} | tr 'a-z' 'A-Z')
        title="${title}${sp}${htmlInfo[1]}₂"
        ma="${htmlInfo[1]}"
        sp=" — "
    fi
    # 三简
    if [ "${htmlInfo[2]}" != "" ]; then
        htmlInfo[2]=$(echo ${htmlInfo[2]} | tr 'a-z' 'A-Z')
        title="${title}${sp}${htmlInfo[2]}₃"
        ma="${htmlInfo[2]}"
        sp=" — "
    fi
    # 全码
    if [ "${htmlInfo[3]}" != "" ]; then
        htmlInfo[3]=$(echo ${htmlInfo[3]} | tr 'a-z' 'A-Z')
        title="${title}${sp}${htmlInfo[3]}₄"
        ma="${htmlInfo[3]}"
    fi
    if [ "${ma}" = "" ];then
        output="{\"title\":\"${current_word} => 没有找到该字的拆字信息\"},"
    else
        # 图片URL
        if [ "${htmlInfo[4]}" != "" ]; then
            wget -O ${current_version}_img/${current_word}.png ${htmlInfo[4]} 2>/dev/null
            convert -crop 25%x100% ${current_version}_img/${current_word}.png ${current_version}_img_sp/${current_word}_%d.png
        fi

        local l=0
        output="{\"title\":\"${current_word} => ${title}\",\"subtitle\": \"五笔版本: ${current_version}\"},"
        if [ $(convert ${current_version}_img_sp/${current_word}_0.png -colorspace RGB -verbose info:| grep "Colors:" | awk '{print $2}') -gt 1 ]; then
            output="${output}{\"title\":\"${ma:0:1}\", \"icon\": {\"type\": \"file\", \"path\": \"$PWD/${current_version}_img_sp/${current_word}_0.png\"}},"
            l="25%x100%";
        fi
        if [ $(convert ${current_version}_img_sp/${current_word}_1.png -colorspace RGB -verbose info:| grep "Colors:" | awk '{print $2}') -gt 1 ]; then
            output="${output}{\"title\":\"${ma:1:1}\", \"icon\": {\"type\": \"file\", \"path\": \"$PWD/${current_version}_img_sp/${current_word}_1.png\"}},"
            l="50%x100%";
        fi
        if [ $(convert ${current_version}_img_sp/${current_word}_2.png -colorspace RGB -verbose info:| grep "Colors:" | awk '{print $2}') -gt 1 ]; then
            output="${output}{\"title\":\"${ma:2:1}\", \"icon\": {\"type\": \"file\", \"path\": \"$PWD/${current_version}_img_sp/${current_word}_2.png\"}},"
            l="75%x100%";
        else
            rm ${current_version}_img_sp/${current_word}_2.png
        fi
        if [ $(convert ${current_version}_img_sp/${current_word}_3.png -colorspace RGB -verbose info:| grep "Colors:" | awk '{print $2}') -gt 1 ]; then
            output="${output}{\"title\":\"${ma:3:1}\", \"icon\": {\"type\": \"file\", \"path\": \"$PWD/${current_version}_img_sp/${current_word}_3.png\"}},"
            l="100%x100%"; rmx="${current_version}_img_md/${current_word}_x.png"
        else
            rm ${current_version}_img_sp/${current_word}_3.png
        fi
        cp ${current_version}_img/${current_word}.png ${current_version}_img_md/${current_word}.png
        echo "| ${current_word} | ![](${current_version}_img_md/${current_word}.png) | ${title} |" >> ${current_version}.md
    fi
    echo "1 ${current_word}" >> ${current_version}_top.txt
    echo "${current_word}:${output}" >> ${current_version}_cache.txt
    echo ${output}
}

## 拆一行字
chai_line(){
    local line="$*"
    local i=0
    local max=${#line}
    while [ ${i} -lt ${max} ]
    do
        current_word="${line:${i}:1}"
        index=$(echo ${line/${current_word}//} | cut -d/ -f1 | wc -m)
        if [ ${index} -ge ${i} -a $(is_chinese ${current_word}) -gt 0 ];then # 没有拆过且为中文
            chai_word ${default_version} ${current_word}
            if [ ${BOTH_VERSION:-0} -eq 1 ];then
                chai_word ${other_version} ${current_word}
            fi
        fi
        i=$((i+1))
    done
}

## 拆一个文件
chai_file(){
    local file="$*"
    local lineF=""
    if [ ! -f "${file}" ]; then
        echo "文件不存在: ${file}"
        exit
    fi
    local x=0
    while read lineF
    do
        x=$((x+1))
        if [ ${x} -lt 10 ];then
            chai_line "${lineF}" &
        else
            chai_line "${lineF}"
        fi
    done < <(LC_ALL=UTF-8 sed "s/[[:alnum:][:punct:]]*//g" "${file}")
}

open_markdown(){
    if [ -f "${HOME}/Documents/wubi_workflow/${default_version}.md" ];then
        open ${HOME}/Documents/wubi_workflow/${default_version}.md
    fi
}

PATH=$PATH:/usr/local/bin
default_version=${WUBI_VERSION:-98}
if [ "${default_version}" = "98" ]; then
    other_version=86
else
    other_version=98
fi
BOTH_VERSION=${BOTH_VERSION:-0}
if [ ! -f "${HOME}/Documents/wubi_workflow/inited" ];then
    mkdir -p ${HOME}/Documents/wubi_workflow
    pushd ${HOME}/Documents/wubi_workflow >/dev/null
    mkdir -p ${HOME}/Documents/wubi_workflow/98_img
    mkdir -p ${HOME}/Documents/wubi_workflow/98_img_md
    mkdir -p ${HOME}/Documents/wubi_workflow/98_img_sp
    mkdir -p ${HOME}/Documents/wubi_workflow/86_img
    mkdir -p ${HOME}/Documents/wubi_workflow/86_img_md
    mkdir -p ${HOME}/Documents/wubi_workflow/86_img_sp
    touch ${HOME}/Documents/wubi_workflow/98_cache.txt
    touch ${HOME}/Documents/wubi_workflow/86_cache.txt
    touch ${HOME}/Documents/wubi_workflow/98_top.txt
    touch ${HOME}/Documents/wubi_workflow/86_top.txt
    echo "# 五笔拆字 98 版" > 98.md
    echo "| 字 | 图解 | 字根输入 |" >> 98.md
    echo "| --- | --- | --- |" >> 98.md
    echo "# 五笔拆字 86 版" > 86.md
    echo "| 字 | 图解 | 字根输入 |" >> 86.md
    echo "| --- | --- | --- |" >> 86.md
    touch inited
    popd >/dev/null
fi