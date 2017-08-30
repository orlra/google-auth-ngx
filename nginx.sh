#!/bin/bash

#echo ${SSL_CERT} > /etc/nginx/cert.cert
#echo ${SSL_CERT_KEY} > /etc/nginx/key.key

cat > /etc/nginx/conf.d/default.conf << EOF
upstream dashboard {
    server dashboard:8080;
}
server {
        server_name ${SERVER_NAME:-_};
        listen 80;

        location / {
                # Set proxy headers
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto \$scheme;

                # Proxy
                proxy_pass http://dashboard;
                proxy_redirect off;

                # Enable connection Upgrade request for WebSockets
                proxy_http_version 1.1;
                proxy_set_header Upgrade \$http_upgrade;
                proxy_set_header Connection "upgrade";
                return 301 https://$host$request_uri;
        }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name ${SERVER_NAME:-_};

    ssl_certificate /ssh_cert/cert.crt;
    ssl_certificate_key /ssh_cert/key.key;


    location /oauth2 {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Scheme \$scheme;
        proxy_set_header X-Auth-Request-Redirect \$request_uri;

        proxy_pass       http://oauth:4180;
    }

    location / {
        auth_request /oauth2/callback;
        error_page 401 = /oauth2/sign_in;
        error_page 403 = /oauth2/sign_in;
        auth_request_set \$user   \$upstream_http_x_auth_request_user;
        auth_request_set \$email  \$upstream_http_x_auth_request_email;
        # pass information via X-User and X-Email headers to backend,
        # requires running with --set-xauthrequest flag
        # TODO o'rly?

        proxy_set_header X-User  \$user;
        proxy_set_header X-Email \$email;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Proxy
        proxy_pass http://dashboard;
        proxy_redirect off;

        # Enable connection Upgrade request for WebSockets
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

EOF

/reload.sh &

nginx -g 'daemon off;'
