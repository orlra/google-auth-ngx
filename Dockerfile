FROM ubuntu:16.04

RUN echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu xenial main" \
  > /etc/apt/sources.list.d/nginx-stable.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C && \
  apt-get update && \
  apt-get install -y nginx-extras


RUN apt-get update && \
    apt-get install -y lua-cjson git ca-certificates curl nano

RUN git clone -c transfer.fsckobjects=true https://github.com/pintsized/lua-resty-http.git /tmp/lua-resty-http && \
    cd /tmp/lua-resty-http && \
    # https://github.com/pintsized/lua-resty-http/releases/tag/v0.10
    git checkout f28b904097aa53dac8be8672edbce5ea573aef86  && \
    mkdir -p /etc/nginx/lua && \
    cp -aR /tmp/lua-resty-http/lib/resty /etc/nginx/lua/resty && \
    rm -rf /tmp/lua-resty-http && \
    mkdir /etc/nginx/http.conf.d && \
sed 's%http {%include /etc/nginx/http.conf.d/*.conf;\n\nhttp {%' -i /etc/nginx/nginx.conf && \
sed 's/\# server_names_hash_bucket_size 64;/server_names_hash_bucket_size 64;/'  -i /etc/nginx/nginx.conf

ENV  NGO_SIGNOUT_URI /auth/logout/logout
ENV  NGO_CLIENT_ID 77777777777-ididididididididid.apps.googleusercontent.com
ENV  NGO_CLIENT_SECRET THISISSECREEEEEEET
ENV  NGO_TOKEN_SECRET  Bananananananananana
ENV  NGO_SECURE_COOKIES True
ENV  NGO_CALLBACK_SCHEME=https
ENV  PORT 443
COPY ./access.lua /etc/nginx/lua/nginx-google-oauth/access.lua
COPY ./docker/etc-nginx /etc/nginx

ENTRYPOINT ["/etc/nginx/run.sh"]
