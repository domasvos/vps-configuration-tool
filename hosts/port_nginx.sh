#!/bin/bash

port="${1}"
if [[ -z "${port}" ]]; then
    echo "Error: Please provide a port number as the first argument."
    return 1
fi

nginx_conf="/etc/nginx/nginx.conf"

if grep -q "listen ${port};" "${nginx_conf}"; then
    echo "Nginx is already listening on port ${port}."
    return 2
else
    sed -i "/http {/a\ \ \ \ server { listen ${port}; }" "${nginx_conf}"
    systemctl reload nginx
    echo "Nginx is now listening on port ${port}."
    return 0
fi
