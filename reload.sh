#!/bin/bash

while true; do
    while inotifywait -e close_write /etc/nginx/conf.d/default.conf; do
        nginx -s reload
    done
    sleep 5
done
