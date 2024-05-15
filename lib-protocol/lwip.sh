#!/bin/bash
set -e

function fix() {
    sed -e '
        s/PhysicalSocket/LwipSocket/g;
        s/PHYSICAL/LOGICAL/g;

        s/\<rtc\>/orc/g;
        s/orc::/rtc::/g;

        s/= {}/= {0}/g;
        s/{}/= default;/g;

        s/#include <fcntl.h>/#include <signal.h>/g;
        s/#include "rtc_base\/physical_socket_server\.h"/#include "logical_.hpp"/g;

        /#include <netinet\//d;
        /#include <sys\//d;

        s/defined(WEBRTC_USE_EPOLL)/0/g;
        s/defined(WEBRTC_USE_POLL)/0/g;

        s/defined(WEBRTC_POSIX)/1/g;
        s/defined(WEBRTC_ANDROID)/0/g;
        s/defined(WEBRTC_FUCHSIA)/0/g;
        s/defined(WEBRTC_IOS)/0/g;
        s/defined(WEBRTC_LINUX)/0/g;
        s/defined(WEBRTC_MAC)/0/g;
        s/defined(WEBRTC_WIN)/0/g;

        s/defined(__native_client__)/0/g;

        s/::accept(/::lwip_accept(/g;
        s/::bind(/::lwip_bind(/g;
        s/\<close(/lwip_close(/g;
        s/::closesocket(/::lwip_close(/g;
        s/::connect(/::lwip_connect(/g;
        s/\<fcntl(/lwip_fcntl(/g;
        s/::getpeername(/::lwip_getpeername(/g;
        s/::getsockname(/::lwip_getsockname(/g;
        s/\<getsockopt(/lwip_getsockopt(/g;
        s/::listen(/::lwip_listen(/g;
        s/read(/lwip_recv(/g;
        s/::recv(/::lwip_recv(/g;
        s/::recvfrom(/::lwip_recvfrom(/g;
        s/::recvmsg(/::lwip_recvmsg(/g;
        s/\<select(/lwip_select(/g;
        s/::send(/::lwip_send(/g;
        s/::sendto(/::lwip_sendto(/g;
        s/::setsockopt(/::lwip_setsockopt(/g;
        s/::socket(/::lwip_socket(/g;
        s/write(/lwip_send(/g;

        s/\<SO_TIMESTAMP\>/-1/g;
    '
}

{
    diff -ru source/lwip.hpp <(fix <../min-webrtc/webrtc/rtc_base/physical_socket_server.h) | colordiff
    diff -ru source/lwip.cpp <(fix <../min-webrtc/webrtc/rtc_base/physical_socket_server.cc) | colordiff
} | nl | less -R

# e077ee472a6a14fb78aa59faa4549eea3a227958 <- remove IP_MTU

#/GetSocketRecvTimestamp(.*{/,/^}/s/^ .*/  return -1;/;
