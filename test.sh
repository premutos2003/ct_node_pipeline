#!/usr/bin/env bash

url="${GIT_URL}"
set -f; IFS='/'
set -- $url
 tag=$5
set +f; unset IFS


set -f; IFS='.'
set -- $tag
folder=$1;
set +f; unset IFS

echo $folder