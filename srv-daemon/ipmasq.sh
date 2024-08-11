#!/bin/bash

set -ex

sysctl -w net.ipv4.ip_forward=1

dev=$1
ip4=192.168.0.5
gw4=${ip4%.*}.1

ip tuntap add dev tun0 mode tun
ifconfig tun0 $gw4 pointtopoint $ip4
iptables -t nat -A POSTROUTING -s $ip4 -o $dev -j MASQUERADE
ip route get 1.0.0.1 from $ip4 iif tun0
