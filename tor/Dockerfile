# Bridge-capable Tor proxy for The JI Project.
#
# Same interface as the default dperson/torproxy service so the rest of the
# stack doesn't change:
#   - SOCKS5 on 0.0.0.0:9050   (used by SearXNG via socks5h://tor:9050)
#   - HTTP proxy on 0.0.0.0:8118 (Privoxy -> Tor; used by Open WebUI)
#
# The difference: this one uses obfs4 BRIDGES, which obfuscate the Tor protocol
# so your ISP can't easily tell you're using Tor at all. You supply the bridge
# lines in tor/bridges.conf (see bridges.conf.example).
FROM alpine:3.20

# tor + obfs4 pluggable transport + privoxy (HTTP->SOCKS bridge)
RUN apk add --no-cache tor obfs4proxy privoxy

COPY torrc /etc/tor/torrc
COPY privoxy.config /etc/privoxy/config
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
    && mkdir -p /var/lib/tor && chown -R tor:tor /var/lib/tor

EXPOSE 9050 8118
ENTRYPOINT ["/entrypoint.sh"]
