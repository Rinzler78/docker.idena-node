#!/bin/bash
docker build -t idena-node . && docker run --env RUN_TIMEOUT=3 --rm --name idena-node idena-node

returnedCode=$?

if [ $returnedCode -eq 124 ]; then
    echo "Success"
    exit 0
fi

exit $returnedCode