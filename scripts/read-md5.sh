#!/bin/zsh

BASEDIR=$(dirname "$0")
$BASEDIR/read.sh ${1:-latest} "md5" "find . -type f -exec md5sum {} \;"
