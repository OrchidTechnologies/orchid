#!/bin/bash

set -e

#https://terrywang.net/2016/02/02/new-iptables-gotchas.html
#https://davidhamann.de/2017/04/19/sharing-vpn-on-macos/

sysctl -w net.ipv4.ip_forward=1

dev=$1
ip4=$(ip address show dev $dev | sed -e '/^ *inet /!d;s///;s@/.*@@')
gw4=${ip4%.*}.1

ip tuntap add dev tun0 mode tun
ifconfig tun0 $ip4 pointtopoint $ip4

ip route delete table local $ip4 dev $dev
ip route delete table local $ip4 dev tun0

sysctl -w net.ipv4.conf.$dev.src_valid_mark=1
sysctl -w net.ipv4.conf.tun0.src_valid_mark=1

iptables -t mangle -A PREROUTING -i $dev -j MARK --set-mark 7
iptables -t mangle -A PREROUTING -i tun0 -j MARK --set-mark 7

ip route add table 7 $gw4 dev $dev
ip route add table 7 default via $gw4 dev $dev
ip route add table 7 $ip4 dev tun0

ip rule add fwmark 7 table 7

ip route get $ip4 from $gw4 mark 7 iif $dev
ip route get $gw4 from $ip4 mark 7 iif tun0
