#!/usr/bin/env bash

source ./functions.sh

pushd ${HOME}/Documents/wubi_workflow >/dev/null

awk '{ sub ("\\\\$", ""); printf "%s", $0 } END { print "" }' his.txt > recent.md
echo "" >> recent.md
echo "| 字 | 图解 | 字根输入 |" >> recent.md
echo "| --- | --- | --- |" >> recent.md

while read w
do
    echo grep "${w}.png" ${default_version}.md
    grep "${w}.png" ${default_version}.md >> recent.md
done < <(tail -r his.txt)
if [ -z "${MARKDOWN_APP}" ]; then
    open recent.md
else
    open -a "${MARKDOWN_APP}" recent.md
fi
popd
