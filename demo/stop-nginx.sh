#!/bin/sh

set -e

if nginx -p . -c nginx.conf -s stop; then
    echo "OK! nginx stopped"
else
    echo "Uh-oh! nginx not stopped"
fi
