#!/bin/bash -ex
cd $HOME
rm -rf $REPO_NAME
git clone $REPO_URL
cd $REPO_NAME
git checkout $REVISION

python3 -m venv venv
source venv/bin/activate

export PIP_INDEX_URL=https://pypi.flatt.tech/simple/
pip3 install -r requirements.txt
mkdocs build

rm -rf $OUTPUT/*
cp -r site/* $OUTPUT/
