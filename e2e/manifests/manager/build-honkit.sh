#!/bin/bash -ex
cd $HOME
rm -rf $REPO_NAME
git clone $REPO_URL
cd $REPO_NAME
git checkout $REVISION

pnpm config set registry https://npm.flatt.tech/
pnpm install --frozen-lockfile
pnpm run build

rm -rf $OUTPUT/*
cp -r _book/* $OUTPUT/
