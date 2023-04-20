#!/bin/bash

port="${1}"
if [[ -z "${port}" ]]; then
    echo "Error: Please provide a port number as the first argument."
    return 1
fi

ports_conf="/etc/apache2/ports.conf"

if grep -q "Listen ${port}" "${ports_conf}"; then
    echo "Apache2 is already listening on port ${port}."
    return 2
else
    echo "Listen ${port}" | tee -a "${ports_conf}"
    systemctl reload apache2
    echo "Apache2 is now listening on port ${port}."
    return 0
fi
