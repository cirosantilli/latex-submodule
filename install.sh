#!/usr/bin/env bash

#create necessary outide this repo so that main repo can use this subrepo

set -u # error on undefined variable
set -e # stop execution if one command returns != 0

BNAME="$( basename "$( pwd )" )"
cd ..
for b in makefile .gitignore shared.sty shared-presentation.sty; do
    ln -s "$BNAME"/"$b" "$b"
    git add "$b"
done
