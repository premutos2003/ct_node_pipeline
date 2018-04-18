#!/usr/bin/env bash


project="$(cut -d'/' -f5 <<< ${GIT_URL} )"
folder="$(cut -d'.' -f1 <<< $project )"

echo $folder