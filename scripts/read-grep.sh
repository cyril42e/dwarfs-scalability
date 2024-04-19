#!/bin/zsh

BASEDIR=$(dirname "$0")
$BASEDIR/read.sh ${1:-latest} "grep" "grep -R 'NON-EXISTING-STRING' *"

