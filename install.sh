#!/usr/bin/env bash

#create necessary outide this repo so that main repo can use this subrepo

set -u # error on undefined variable
set -e # stop execution if one command returns != 0

BNAME="$( basename "$( pwd )" )"
cd ..

FS=( makefile .gitignore shared.sty shared-presentation.sty )
for F in "${FS[@]}"; do
    if [ -e "$F" ]; then
        echo "FILE ALREADY EXISTS. INSTALLATION ABORTED: $f"
        exit 1
    fi
done

for F in "${FS[@]}"; do
    ln -s "$BNAME"/"$F" "$F"
done

echo 'INSTALLATION FINISHED. CONSIDER ADDING GENERATED FILES TO PROJECT WITH: `git add`'
exit 0
