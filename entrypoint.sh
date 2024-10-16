#!/bin/sh

# make sure /var/cache/naemon/checkresults exists, otherwise naemon won't start
mkdir -p /var/cache/naemon/checkresults

# make sure /var/log/naemon/archives exists, otherwise naemon-livestatus will complain
mkdir -p /var/log/naemon/archives

/usr/bin/naemon -v /etc/naemon/naemon.cfg
exec /usr/bin/naemon /etc/naemon/naemon.cfg
