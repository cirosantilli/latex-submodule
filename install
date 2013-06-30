#!/usr/bin/env bash

#create necessary outide this repo so that main repo can use this subrepo

set -u # error on undefined variable
set -e # stop execution if one command returns != 0

BNAME="$( basename "$( pwd )" )"

#shared files that will be symlinked into this repo:
FS_LN=( makefile .gitignore shared.sty shared-presentation.sty )

#templates that will be copied to project repo:
FS_CP=( config.py )

for F in "${FS_LN[@]}" "${FS_LN[@]}" ; do
    if [ -e "$F" ]; then
        echo "FILE ALREADY EXISTS. INSTALLATION ABORTED: $F"
        exit 1
    fi
done

for F in "${FS_LN[@]}"; do
    cp "$F" ..
done

cd ..

for F in "${FS_LN[@]}"; do
    ln -s "$BNAME"/"$F" "$F"
done

echo 'INSTALLATION FINISHED. CONSIDER ADDING GENERATED FILES TO PROJECT WITH: `git add`'
exit 0
