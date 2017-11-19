#!/usr/bin/env bash

source ./functions.sh

add_word2md(){
    local current_version=${1}
    local current_word=${2}
    local cache=$(egrep "^${current_word}:" ${current_version}_cache.txt)
    local title=${cache%%\",\"subtitle*}
    local title=${title#*\> }
    echo "| ${current_word} | ![](${current_version}_img_md/${current_word}.png) | ${title} |" >> ${current_version}.md
}

pushd ${HOME}/Documents/wubi_workflow >/dev/null

i=0
m=$(wc -l ${default_version}_top.txt | awk '{print $1}')
while read w
do
    n=$(grep ${w} ${default_version}.md | wc -l)
    if [ ${n} -eq 0 ];then
        add_word2md ${default_version} ${w}
    fi
    i=$((i+1))
    echo ${i}/${m}
done < <(sort -rg ${default_version}_top.txt | egrep -v '^$' | cut -d" " -f 2)

if [ ${BOTH_VERSION} -gt 0 ]; then
    i=0
    m=$(wc -l ${other_version}_top.txt | awk '{print $1}')
    while read w
    do
        n=$(grep ${w} ${other_version}.md | wc -l)
        if [ ${n} -eq 0 ];then
            add_word2md ${other_version} ${w}
        fi
        i=$((i+1))
        echo ${i}/${m}
    done < <(sort -rg ${other_version}_top.txt | egrep -v '^$' | cut -d" " -f 2)
fi

popd
