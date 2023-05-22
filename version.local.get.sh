#!/bin/bash

versionFile=version
currentVersion=""

if [ -f $versionFile ]; then
    cat $versionFile
fi