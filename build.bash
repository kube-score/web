#!/bin/bash

set -euo pipefail
set -x

build_func() {
    readonly local dir=$1
    readonly local src_path=$2
    readonly local handler_name=$3

    mkdir -p "${dir}/files"
    cd "${dir}/${src_path}"
    env GOOS=linux GOARCH=amd64 go build -o "$dir/files/${handler_name}-linux-amd64"
    rm -f "${dir}/files/${handler_name}-linux-amd64.zip"
    zip -r -j "${dir}/files/${handler_name}-linux-amd64.zip" "${dir}/files/${handler_name}-linux-amd64"
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

build_func $DIR "funcs/score/v2" "score_v2"
