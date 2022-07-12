/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2020  The Orchid Authors
*/

/* GNU Affero General Public License, Version 3 {{{ */
/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.

 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/
/* }}} */


#include "log.hpp"
#include "memory.hpp"
#include "syscall.hpp"

#ifdef __APPLE__

#include <fcntl.h>
#include <unistd.h>

#include <malloc/malloc.h>

namespace orc {

static int file_(-1);

// XXX: there are a number of arrays in this file; are they correct?

class Out {
  private:
    char data_[128];
    char *next_;

  public:
    Out() :
        next_(data_)
    {
    }

    ~Out() {
        *next_++ = '\n';
        write(file_, data_, next_ - data_);
    }

    Out &operator <<(char data) {
        *next_++ = data;
        return *this;
    }

    Out &operator <<(const char *data) {
        while (*data != '\0')
            operator <<(*data++);
        return *this;
    }

    Out &operator <<(size_t value) {
        char buffer[32];
        char *end(buffer + sizeof(buffer));
        *--end = '\0';
        if (value == 0)
            *--end = '0';
        else do {
            unsigned digit(value % 10);
            value /= 10;
            *--end = static_cast<char>('0' + digit);
        } while (value != 0);
        return operator <<(end);
    }

    Out &operator <<(ssize_t value) {
        if (value >= 0)
            operator <<('+');
        else {
            operator <<('-');
            value = -value;
        }

        return operator <<(size_t(value));
    }

    Out &operator <<(void *pointer) {
        uintptr_t value(reinterpret_cast<uintptr_t>(pointer));
        char buffer[32];
        char *end(buffer + sizeof(buffer));
        *--end = '\0';
        if (value == 0)
            *--end = '0';
        else do {
            unsigned digit(value & 0xf);
            value >>= 4;
            *--end = static_cast<char>((digit < 10 ? '0' : 'a' - 10) + digit);
        } while (value != 0);
        *--end = 'x';
        *--end = '0';
        return operator <<(end);
    }
};

static size_t total_(0);

static void Audit(size_t add, size_t sub) {
    total_ += add;
    total_ -= sub;
    if (add < sub)
        return;
    if (file_ == -1)
        return;
    Out() << total_ << " (" << (add - sub) << ")";
}

static decltype(std::declval<_malloc_zone_t *>()->malloc) apl_malloc;
static void *orc_malloc(struct _malloc_zone_t *zone, size_t size) {
    auto value(apl_malloc(zone, size));
    if (value == nullptr)
        return nullptr;
    auto full(zone->size(zone, value));
    if (file_ != -1)
        Out() << "malloc(" << size << ") = " << value;
    Audit(full, 0);
    return value;
}

static decltype(std::declval<_malloc_zone_t *>()->calloc) apl_calloc;
static void *orc_calloc(struct _malloc_zone_t *zone, size_t count, size_t size) {
    auto value(apl_calloc(zone, count, size));
    if (value == nullptr)
        return nullptr;
    auto full(zone->size(zone, value));
    if (file_ != -1)
        Out() << "calloc(" << count << ", " << size << ") = " << value;
    Audit(full, 0);
    return value;
}

static decltype(std::declval<_malloc_zone_t *>()->valloc) apl_valloc;
static void *orc_valloc(struct _malloc_zone_t *zone, size_t size) {
    auto value(apl_valloc(zone, size));
    if (value == nullptr)
        return nullptr;
    auto full(zone->size(zone, value));
    if (file_ != -1)
        Out() << "valloc(" << size << ") = " << value;
    Audit(full, 0);
    return value;
}

static decltype(std::declval<_malloc_zone_t *>()->realloc) apl_realloc;
static void *orc_realloc(struct _malloc_zone_t *zone, void *old, size_t size) {
    auto before(zone->size(zone, old));
    auto value(apl_realloc(zone, old, size));
    auto after(zone->size(zone, value));
    if (file_ != -1)
        Out() << "realloc(" << old << ", " << size << ") = " << value;
    Audit(after, before);
    return value;
}

static decltype(std::declval<_malloc_zone_t *>()->free) apl_free;
static void orc_free(struct _malloc_zone_t *zone, void *value) {
    auto full(zone->size(zone, value));
    if (file_ != -1)
        Out() << "free(" << value << ")";
    Audit(0, full);
    return apl_free(zone, value);
}

static decltype(std::declval<_malloc_zone_t *>()->batch_malloc) apl_batch_malloc;
static unsigned orc_batch_malloc(struct _malloc_zone_t *zone, size_t size, void **values, unsigned count) {
    count = apl_batch_malloc(zone, size, values, count);
    size_t full(0);
    for (size_t i(0); i != count; ++i) {
        full += zone->size(zone, values[i]);
        if (file_ != -1)
            Out() << "batch_malloc(" << size << ", " << values << "[" << i << "]) = " << values[i];
    }
    Audit(full, 0);
    return count;
}

static decltype(std::declval<_malloc_zone_t *>()->batch_free) apl_batch_free;
static void orc_batch_free(struct _malloc_zone_t *zone, void **values, unsigned count) {
    size_t full(0);
    for (size_t i(0); i != count; ++i) {
        full += zone->size(zone, values[i]);
        if (file_ != -1)
            Out() << "batch_free(" << values << "[" << i << "] = " << values[i] << ")";
    }
    Audit(0, full);
    return apl_batch_free(zone, values, count);
}

static decltype(std::declval<_malloc_zone_t *>()->memalign) apl_memalign;
static void *orc_memalign(struct _malloc_zone_t *zone, size_t alignment, size_t size) {
    auto value(apl_memalign(zone, alignment, size));
    auto full(zone->size(zone, value));
    if (file_ != -1)
        Out() << "memalign(" << alignment << ", " << size << ") = " << value;
    Audit(full, 0);
    return value;
}

static decltype(std::declval<_malloc_zone_t *>()->free_definite_size) apl_free_definite_size;
static void orc_free_definite_size(struct _malloc_zone_t *zone, void *value, size_t size) {
    auto full(zone->size(zone, value));
    if (file_ != -1)
        Out() << "free_definite_size(" << value << ", " << size << ")";
    Audit(0, full);
    return apl_free_definite_size(zone, value, size);
}

#define orc_swizzle(name) do { \
    apl_ ## name = zone->name; \
    if (apl_ ## name == nullptr) \
        break; \
    zone->name = &orc_ ## name; \
} while (false)

void Hook() {
    return;

    Log() << "TMPDIR : " << getenv("TMPDIR") << std::endl;
    file_ = orc_syscall(open((std::string(getenv("TMPDIR")) + "/hook.log").c_str(), O_CREAT | O_TRUNC | O_WRONLY, 0644));

    if (file_ == -1)
        return;

    static bool hooked(false);
    if (hooked)
        return;
    hooked = true;

    auto zone(malloc_default_zone());
    if (zone->version != 10)
        return;

    orc_swizzle(malloc);
    orc_swizzle(calloc);
    orc_swizzle(valloc);
    orc_swizzle(realloc);
    orc_swizzle(free);
    orc_swizzle(batch_malloc);
    orc_swizzle(batch_free);
    orc_swizzle(memalign);
    orc_swizzle(free_definite_size);
}

}

#else
namespace orc {
void Hook() {
} }
#endif
