#!/bin/sh

# ------------------------------------------------------------------------------
# Set Up Aria 2 Environment

adduser \
    -h /downloads \
    -u "${ARIA_UID}" \
    -g "${ARIA_GID}" \
    -D aria2

# Write a new config file, if needed
if [ ! -f /config/aria2.conf ]; then
    cp /etc/aria2.conf /config/aria2.conf
fi

touch /config/aria2.session
chown -R aria2:aria2 /config /downloads

# Replace token secret with environment variable
sed -i s/rpc-secret=.*/rpc-secret=${ARIA_RPC_TOKEN}/g /config/aria2.conf


# ------------------------------------------------------------------------------
# SSL

# If a keypair doesn't exist, genenrate a self-signed one.
# NOTE: Ideally, you should replace this with a real keypair.
if [ ! -f /config/ssl.key ] || [ ! -f /config/ssl.crt ]; then
    openssl req -new -x509 -nodes -newkey rsa:2048 -days 365 \
            -subj "/C=CA/ST=Ontario/L=Hamilton /O=webui-aria2 /CN=localhost" \
            -keyout /config/ssl.key \
            -out /config/ssl.crt
fi

# For OCSP Stapling. If you don't supply your own cert, nginx will ignore this
if [ ! -f /config/ca_chain.crt ]; then
    cp /config/ssl.crt /config/ca_chain.crt
fi

chown root:nginx /config/ssl.key /config/ssl.crt /config/ca_chain.crt
chmod 0640 /config/ssl.key /config/ssl.crt /config/ca_chain.crt


# ------------------------------------------------------------------------------
# Start Services

su aria2 -c '/usr/bin/aria2c --enable-rpc=true --rpc-listen-all=false --rpc-secret ${ARIA_RPC_TOKEN} --quiet=true --log=/config/aria2.log --conf-path=/config/aria2.conf' &

/usr/sbin/nginx -c /etc/nginx/nginx.conf
