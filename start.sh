#!/bin/bash

mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

iptables -t mangle -A FORWARD -i CloudflareWARP -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
iptables -t mangle -A FORWARD -o CloudflareWARP -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

mkdir -p /var/lib/cloudflare-warp
cat <<EOF > /var/lib/cloudflare-warp/mdm.xml
<dict>
<key>organization</key>
<string>$ORGANIZATION</string>
<key>auth_client_id</key>
<string>$AUTH_CLIENT_ID</string>
<key>auth_client_secret</key>
<string>$AUTH_CLIENT_SECRET</string>
<key>warp_connector_token</key>
<string>$WARP_CONNECTOR_TOKEN</string>
</dict>
EOF

warp-svc > >(grep -iv dbus) 2> >(grep -iv dbus >&2) &
WARP_PID=$!

trap "echo 'Stopping warp-svc...'; kill -TERM $WARP_PID; exit" SIGTERM SIGINT

sleep "2s"
warp-cli --accept-tos connect

wait $WARP_PID