#!/usr/bin/env bash
url=https://github.com/premutos2003/express
IFS='/' read -r -a split <<< "https://github.com/premutos2003/express"
echo  "${split[4]}"