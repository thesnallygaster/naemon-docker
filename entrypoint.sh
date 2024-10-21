#!/bin/sh

# make sure /var/cache/naemon/checkresults exists, otherwise naemon won't start
mkdir -p /var/cache/naemon/checkresults

# make sure /var/log/naemon/archives exists, otherwise naemon-livestatus will complain
mkdir -p /var/log/naemon/archives

# make sure below directories are owned by naemon
chown -R naemon:naemon /etc/naemon /var/cache/naemon /var/lib/naemon /var/log/naemon

# check if naemon config is correct
runuser -P -u naemon -- /usr/bin/naemon -v /etc/naemon/naemon.cfg

# run naemon as naemon user
exec runuser -P -u naemon -- /usr/bin/naemon /etc/naemon/naemon.cfg
