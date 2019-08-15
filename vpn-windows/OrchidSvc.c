#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <WinSock2.h>

#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>

#include <Ws2tcpip.h>
#include <process.h>

#include "orchid.h"

#pragma comment(lib, "ws2_32")
#pragma comment(lib, "Iphlpapi")

static HANDLE tunHandle;
static OVERLAPPED overlapWrite;


int main()
{
	tunHandle = CreateFile(
		device_path,
		MAXIMUM_ALLOWED,
		0,
		0,
		OPEN_EXISTING,
		FILE_ATTRIBUTE_SYSTEM | FILE_FLAG_OVERLAPPED,
		0
	);

	OVERLAPPED overlapRead = { .hEvent = CreateEvent(NULL, TRUE, FALSE, NULL) };
	overlapWrite.hEvent = CreateEvent(NULL, TRUE, FALSE, NULL);

	for (;;) {
		uint8_t buf[65536];
		DWORD bufSize = sizeof(buf);
		DWORD bytesRead = 0;
		if (!ReadFile(tunHandle, buf, bufSize, &bytesRead, &overlapRead)) {
			DWORD err = GetLastError();
			if (err != ERROR_IO_PENDING) {
				printf("ReadFile failed: %d\n", err);
				return;
			}
			if (!GetOverlappedResult(tunHandle, &overlapRead, &bytesRead, TRUE)) {
				err = GetLastError();
				printf("GetOverlappedResult failed: %d\n", err);
				return;
			}
		}
		printf("tun packet len:%d\n", bytesRead);

		if (!on_tunnel_packet(buf, bytesRead)) {
			write_tunnel_packet(buf, bytesRead);
		}
	}
}

bool vpn_protect(int s, port_t port)
{
	sockaddr_in *tun_addr = TODO;
	if (!tun_addr) {
		printf("vpn_protect(%d, %d) failed\n", s, port);
		WSASetLastError(WSAEADDRNOTAVAIL);
		return false;
	}
	tun_addr->sin_port = htons(port);
	if (!bind(s, (const struct sockaddr*)tun_addr, sizeof(sockaddr_in))) {
		printf("bind failed:%d\n", WSAGetLastError());
		return false;
	}
	return true;
}

void write_tunnel_packet(const uint8_t *packet, size_t length)
{
	DWORD bytesWritten = 0;
	if (!WriteFile(tunHandle, packet, length, &bytesWritten, &overlapWrite)) {
		DWORD err = GetLastError();
		if (err != ERROR_IO_PENDING) {
			printf("WriteFile failed with error %d\n", err);
			return;
		}
		if (!GetOverlappedResult(tunHandle, &overlapWrite, &bytesWritten, TRUE)) {
			err = GetLastError();
			printf("GetOverlappedResult failed: %d\n", err);
			return;
		}
	}
	return;
}
