#!/bin/sh
set -e

if [ ! -s /etc/tor/bridges.conf ]; then
  echo "ERROR: /etc/tor/bridges.conf is missing or empty."
  echo "Copy tor/bridges.conf.example to tor/bridges.conf and paste in bridge"
  echo "lines from https://bridges.torproject.org (obfs4)."
  exit 1
fi

# HTTP proxy on :8118 -> Tor SOCKS, in the background.
privoxy --no-daemon /etc/privoxy/config &

# Tor in the foreground (this is the container's main process).
exec tor -f /etc/tor/torrc
