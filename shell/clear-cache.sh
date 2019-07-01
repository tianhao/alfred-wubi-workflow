#!/bin/bash

source ./functions.sh
pushd ${HOME}/Documents/wubi_workflow
rm -rf 86_img/*.png 86_img_sp/*.png 98_img/*.png 98_img_sp/*.png 06_img/*.png 06_img_sp/*.png 
echo "" > 86_cache.txt
echo "" > 98_cache.txt
echo "" > 06_cache.txt
echo "" > 98_top.txt
echo "" > 86_top.txt
echo "" > 06_top.txt
echo "" > his.txt
echo "" > recent.md
popd