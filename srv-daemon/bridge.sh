#!/bin/bash

set -ex

#https://terrywang.net/2016/02/02/new-iptables-gotchas.html
#https://davidhamann.de/2017/04/19/sharing-vpn-on-macos/

tun=$1
dev=$2
shift 2

ip4=$(ip address show dev $dev | sed -e '/^ *inet /!d;s///;s@/.*@@')
gw4=${ip4%.*}.1

ip tuntap del dev $tun mode tun
ip tuntap add dev $tun mode tun
ifconfig $tun $ip4 pointtopoint $ip4

ip route delete table local $ip4 dev $tun
ip route delete table local $ip4 dev $dev

ip route add table 7 $gw4 dev $dev
ip route add table 7 default via $gw4 dev $dev
ip route add table 7 $ip4 dev $tun

ip rule add iif $tun table 7
ip rule add iif $dev table 7

sysctl -w net.ipv4.ip_forward=1
iptables -A FORWARD -i $tun -o $dev -j ACCEPT
iptables -A FORWARD -i $dev -o $tun -j ACCEPT

ip route get 1.0.0.1 from $ip4 iif $tun
ip route get $ip4 from 1.0.0.1 iif $dev
