# ------------------------------------------------------------------------------
# webui-aria2 Container
# ------------------------------------------------------------------------------

IMAGE="cannable/webui-aria2"
ARCHES=(amd64 arm64 arm)


# Runtime variables
ARIA_UID=1000
ARIA_GID=1000
ARIA_RPC_TOKEN="T0tallyChang3M3!"


build() {

    local arch=$1

    local dl_url="https://github.com/ziahamza/webui-aria2/archive/refs/heads/master.zip"

    echo Building $arch...

    local c=$(buildah from --format docker --arch "$arch" alpine)

    buildah run $c -- apk add --no-cache \
        aria2 \
        dumb-init \
        nginx \
        openssl \
        unzip

    buildah run $c -- rm -rf /var/lib/nginx/html

    # Install AriaNg
    buildah run $c -- wget -P /tmp "${dl_url}"
    buildah run $c -- unzip -o /tmp/master.zip  '*/docs/*' -d /tmp
    buildah run $c -- cp -R /tmp/webui-aria2-master/docs /var/lib/nginx/html
    buildah run $c -- chmod 0755 /var/lib/nginx/html
    buildah run $c -- rm -rf /tmp/master.zip /tmp/webui-aria2-master

    # Copy over various config files
    buildah copy --chown root:root --chmod 0640 \
        $c aria2.conf /etc/aria2.conf

    buildah copy --chown root:root --chmod 0644 \
        $c nginx.conf /etc/nginx/nginx.conf

    buildah copy --chown root:root --chmod 0755 \
        $c init.sh /init.sh

    buildah config  \
        --env "ARIA_UID=${ARIA_UID}" \
        --env "ARIA_GID=${ARIA_GID}" \
        --env "ARIA_RPC_TOKEN=${ARIA_RPC_TOKEN}" \
        --volume /config \
        --volume /downloads \
        --port 443 \
        --port 80 \
        --entrypoint '["/usr/bin/dumb-init", "--", "/init.sh"]' \
        $c

    buildah commit --format docker --rm $c "$IMAGE:${arch}-latest"
}
