#include <stdint.h>
#include <stdbool.h>


bool on_tunnel_packet(const uint8_t *packet, size_t length);

// defined by the caller
void write_tunnel_packet(const uint8_t *packet, size_t length);
