#!/bin/bash

source ./functions.sh

pushd ${HOME}/Documents/wubi_workflow >/dev/null
chai_file $*
popd >/dev/null