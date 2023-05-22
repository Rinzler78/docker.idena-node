#!/bin/bash

version=$1

if [ -z "$version" ];
then
    echo "Missing version number"
    exit 1
fi

versionFile=version
echo "$version" > $versionFile