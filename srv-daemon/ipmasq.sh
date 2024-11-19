#!/bin/bash

set -ex

tun=$1
dev=$2
shift 2

ip4=192.168.0.5
gw4=${ip4%.*}.1
net=${ip4%.*}.0/24

ip tuntap del dev $tun mode tun
ip tuntap add dev $tun mode tun
ifconfig $tun $gw4 pointtopoint $ip4

iptables -t nat -A POSTROUTING -s $net -o $dev -j MASQUERADE

sysctl -w net.ipv4.ip_forward=1
iptables -A FORWARD -i $tun -o $dev -j ACCEPT
iptables -A FORWARD -i $dev -o $tun -j ACCEPT

ip route get 1.0.0.1 from $ip4 iif $tun
