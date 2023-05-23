#!/bin/bash

port="${1}"
if [[ -z "${port}" ]]; then
    echo "Error: Please provide a port number as the first argument."
    return 1
fi

if command -v apache2 &> /dev/null; then
    service_name="apache2"
    ports_conf="/etc/apache2/ports.conf"
elif command -v httpd &> /dev/null; then
    service_name="httpd"
    ports_conf="/etc/httpd/conf/httpd.conf"
else
    echo "Error: Apache2/httpd is not installed on this system."
    return 1
fi

if grep -q "Listen ${port}" "${ports_conf}"; then
    echo "${service_name} is already listening on port ${port}."
    return 2
else
    echo "Listen ${port}" | tee -a "${ports_conf}"
    systemctl reload "${service_name}"
    echo "${service_name} is now listening on port ${port}."
    return 0
fi
