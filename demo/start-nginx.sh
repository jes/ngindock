#!/bin/sh

set -e

if nginx -p . -c nginx.conf; then
    echo "OK! nginx started"
else
    echo "Uh-oh! nginx not started"
fi
