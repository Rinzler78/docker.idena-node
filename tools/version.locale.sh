#!/bin/bash

# Print only the idena-node version number (e.g. 1.1.1)
if [ -x /bin/idena-node ]; then
    /bin/idena-node --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+'
else
    echo "idena-node not found" >&2
    exit 1
fi 