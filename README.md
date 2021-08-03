# webui-aria2c Container

This is a pretty simple implementation of a remote Aria 2 downloader. Nginx
hosts webui-aria2 as well as proxies Aria's RPC REST API. Alternate Aria 2
clients (there are a bunch, including Aria 2 itself and cURL) can be used in
addition to the web app bundled with this container.

## Getting Started
### Running the Container

Use some variation on the following:

```
docker run -d \
	--name getstuff \
	--hostname getstuff.somewhere \
	--restart unless-stopped \
    -p 80 \
    -p 443 \
	-e "ARIA_UID=1000" \
	-e "ARIA_GID=1000" \
	-e "ARIA_RPC_TOKEN=$up3rSecr3t" \
	--volume=dl-config:/config/ \
	--volume=/var/lib/aria2-downloads:/downloads/ \
	cannable/webui-aria2
```

Or go a little more to town:

```
docker run -d \
	--name getstuff \
	--hostname getstuff.somewhere \
	--restart unless-stopped \
	-e "ARIA_UID=1000" \
	-e "ARIA_GID=100" \
	-e "ARIA_RPC_TOKEN=$up3rSecr3t" \
	--volume=dl-config:/config/ \
	--volume=/var/lib/aria2-downloads:/downloads/ \
	--network 'some_ipvlan' \
	--ip '10.0.12.1' \
	--ip6 '2001:db8:dead:beef' \
	cannable/webui-aria2
```

### Connecting to Aria 2

After you start the container, you should be able to hop into a web browser and
try to reach the web app. Once the app loads, you will need to edit the
connection settings and provide the RPC token you created.

## Runtime Environment Variables

### ARIA_UID and ARIA_GID

Sets the UID and GID, respectively, of the Aria 2 user in the container when it
runs. Use these to sidestep permission issues when working with bind mounts.
Note that if you are running SELinux, then you might still have a few hiccups.
### ARIA_RPC_TOKEN

This is very important to randomize. Nginx will host webui-aria2 without any
form of authentication required to get to it. That's not directly an issue (and
if you want to do extra Nginx things, read further). Aria 2's REST API, on the
other hand, will be exposed to your network. TLS will secure traffic in flight,
but the token is the only form of authentication in play. So, again, set a
complex RPC token.

# Other Notes

## Default Volumes

The downloads volume at `/downloads` is self-explanatory. You should use a volume
to store the contents of `/config`, as that's where state for various things are
stored.

## Replacing the TLS Certificates

Replace `/config/ssl.key` and `/config/ssl.crt`. You can also replace
`/config/ca_chain.crt`, where the Nginx will look to do OCSP things.

# Customising Aria 2 Configuration

Just edit `/config/aria2.conf` and bounce the container.

# Customising Nginx Configuration

If you really want to tweak the Nginx config, just start the container with a
volume mounted at `/etc/nginx`. Note that only Alpine's base nginx package is
installed. if you need anything extra, you should probably just fork or clone
(https://github.com/cannable/oci-webui-aria2c)[https://github.com/cannable/oci-webui-aria2c]
and roll your own image.