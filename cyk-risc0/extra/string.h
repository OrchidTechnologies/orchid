#include <stddef.h>
#include <stdint.h>

int8_t memcmp(const void *l, const void *r, size_t s);

void memcpy(void *d, const void *v, size_t s);
void memmove(void *d, const void *v, size_t s);

void memset(void *d, uint8_t v, size_t s);
