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


// <cstdint> {{{
typedef signed char int8_t;

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;

typedef unsigned int size_t;

typedef uint32_t uintptr_t;
/// }}}
// <memory> {{{
extern "C" int8_t memcmp(const void *l, const void *r, size_t s) {
    for (size_t i(0); i != s; ++i)
        if (const auto v = reinterpret_cast<const uint8_t *>(l)[i] - reinterpret_cast<const uint8_t *>(r)[i]; v != 0)
            return v;
    return 0;
}

extern "C" void memcpy(void *d, const void *v, size_t s) {
    for (size_t i(0); i != s; ++i)
        reinterpret_cast<uint8_t *>(d)[i] = reinterpret_cast<const uint8_t *>(v)[i];
}

extern "C" void memmove(void *d, const void *v, size_t s) {
    if (d != v) if (d < v) return memcpy(d, v, s); else
    for (size_t i(s); i-- != s; )
        reinterpret_cast<uint8_t *>(d)[i] = reinterpret_cast<const uint8_t *>(v)[i];
}

extern "C" void memset(void *d, uint8_t v, size_t s) {
    for (size_t i(0); i != s; ++i)
        reinterpret_cast<uint8_t *>(d)[i] = v;
}
// }}}
// <string> {{{
extern "C" int strlen(const char *d) {
    for (size_t i(0); ; ++i)
        if (d[i] == '\0')
            return i;
}
// }}}

// std::initializer_list {{{
namespace std {
template <typename Type_>
class initializer_list {
  private:
    const Type_ *data_;
    size_t size_;

  public:
    inline const Type_ &operator [](size_t index) const {
        return data_[index]; }
    inline size_t size() const {
        return size_; }
}; } // }}}
// std::pair {{{
namespace std {
template <typename First_, typename Second_>
class pair {
  public:
    First_ first;
    Second_ second;
}; } // }}}
// std::strong_ordering {{{
namespace std {
constexpr struct strong_ordering {
    int value;
    static const strong_ordering equal, less, greater;
} strong_ordering::equal{0}, strong_ordering::less{-1}, strong_ordering::greater{1}; } // }}}

namespace cyk {

static inline long ecall_2(long call, long arg0, long arg1) { /*{{{*/
    register long t0 __asm__("t0") = call;
    register long a0 __asm__("a0") = arg0;
    register long a1 __asm__("a1") = arg1;
    __asm__("ecall" : "=r" (a0) :
        "r" (a0), "r" (a1),
        "r" (t0)
    : "memory");
    return a0;
/*}}}*/ }
static inline long ecall_5(long call, long arg0, long arg1, long arg2, long arg3, long arg4) { /*{{{*/
    register long t0 __asm__("t0") = call;
    register long a0 __asm__("a0") = arg0;
    register long a1 __asm__("a1") = arg1;
    register long a2 __asm__("a2") = arg2;
    register long a3 __asm__("a3") = arg3;
    register long a4 __asm__("a4") = arg4;
    __asm__("ecall" : "=r" (a0) :
        "r" (a0), "r" (a1), "r" (a2), "r" (a3), "r" (a4),
        "r" (t0)
    : "memory");
    return a0;
/*}}}*/ }

static inline long syscall_0(const char *call, void *data, size_t size) { /*{{{*/
    register long t0 __asm__("t0") = 2;
    register long a0 __asm__("a0") = (long) data;
    register long a1 __asm__("a1") = size;
    register const char *a2 __asm__("a2") = call;
    __asm__("ecall" : "=r" (a0) :
        "r" (a0), "r" (a1),
        "r" (t0), "r" (a2)
    : "memory");
    return a0;
/*}}}*/ }
static inline long syscall_1(const char *call, void *data, size_t size, long arg0) { /*{{{*/
    register long t0 __asm__("t0") = 2;
    register long a0 __asm__("a0") = (long) data;
    register long a1 __asm__("a1") = size;
    register const char *a2 __asm__("a2") = call;
    register long a3 __asm__("a3") = arg0;
    __asm__("ecall" : "=r" (a0) :
        "r" (a3),
        "r" (a0), "r" (a1),
        "r" (t0), "r" (a2)
    : "memory");
    return a0;
/*}}}*/ }
static inline long syscall_2(const char *call, void *data, size_t size, long arg0, long arg1) { /*{{{*/
    register long t0 __asm__("t0") = 2;
    register long a0 __asm__("a0") = (long) data;
    register long a1 __asm__("a1") = size;
    register const char *a2 __asm__("a2") = call;
    register long a3 __asm__("a3") = arg0;
    register long a4 __asm__("a4") = arg1;
    __asm__("ecall" : "=r" (a0) :
        "r" (a3), "r" (a4),
        "r" (a0), "r" (a1),
        "r" (t0), "r" (a2)
    : "memory");
    return a0;
/*}}}*/ }
static inline std::pair<long, long> syscall_2_2(const char *call, void *data, size_t size, long arg0, long arg1) { /*{{{*/
    register long t0 __asm__("t0") = 2;
    register long a0 __asm__("a0") = (long) data;
    register long a1 __asm__("a1") = size;
    register const char *a2 __asm__("a2") = call;
    register long a3 __asm__("a3") = arg0;
    register long a4 __asm__("a4") = arg1;
    __asm__("ecall" : "=r" (a0), "=r" (a1) :
        "r" (a3), "r" (a4),
        "r" (a0), "r" (a1),
        "r" (t0), "r" (a2)
    : "memory");
    return {a0, a1};
/*}}}*/ }
static inline long syscall_3(const char *call, void *data, size_t size, long arg0, long arg1, long arg2) { /*{{{*/
    register long t0 __asm__("t0") = 2;
    register long a0 __asm__("a0") = (long) data;
    register long a1 __asm__("a1") = size;
    register const char *a2 __asm__("a2") = call;
    register long a3 __asm__("a3") = arg0;
    register long a4 __asm__("a4") = arg1;
    register long a5 __asm__("a5") = arg2;
    __asm__("ecall" : "=r" (a0) :
        "r" (a3), "r" (a4), "r" (a5),
        "r" (a0), "r" (a1),
        "r" (t0), "r" (a2)
    : "memory");
    return a0;
/*}}}*/ }
static inline long syscall_4(const char *call, void *data, size_t size, long arg0, long arg1, long arg2, long arg3) { /*{{{*/
    register long t0 __asm__("t0") = 2;
    register long a0 __asm__("a0") = (long) data;
    register long a1 __asm__("a1") = size;
    register const char *a2 __asm__("a2") = call;
    register long a3 __asm__("a3") = arg0;
    register long a4 __asm__("a4") = arg1;
    register long a5 __asm__("a5") = arg2;
    register long a6 __asm__("a6") = arg3;
    __asm__("ecall" : "=r" (a0) :
        "r" (a3), "r" (a4), "r" (a5), "r" (a6),
        "r" (a0), "r" (a1),
        "r" (t0), "r" (a2)
    : "memory");
    return a0;
/*}}}*/ }
static inline long syscall_5(const char *call, void *data, size_t size, long arg0, long arg1, long arg2, long arg3, long arg4) { /*{{{*/
    register long t0 __asm__("t0") = 2;
    register long a0 __asm__("a0") = (long) data;
    register long a1 __asm__("a1") = size;
    register const char *a2 __asm__("a2") = call;
    register long a3 __asm__("a3") = arg0;
    register long a4 __asm__("a4") = arg1;
    register long a5 __asm__("a5") = arg2;
    register long a6 __asm__("a6") = arg3;
    register long a7 __asm__("a7") = arg4;
    __asm__("ecall" : "=r" (a0) :
        "r" (a3), "r" (a4), "r" (a5), "r" (a6), "r" (a7),
        "r" (a0), "r" (a1),
        "r" (t0), "r" (a2)
    : "memory");
    return a0;
/*}}}*/ }

}

// panic/assert {{{
namespace cyk {

long sys_panic(const char *data, size_t size) {
    auto value(syscall_2("risc0_zkvm_platform::syscall::nr::SYS_PANIC", nullptr, 0, (long) data, size));
    __asm__ ("sw x0, 1(x0)");
    return value;
}

#define cyk_panic(data) \
    cyk::sys_panic(data, sizeof(data) - 1)

#define cyk_line__(x) #x
#define cyk_line_(x) cyk_line__(x)
#define cyk_line() cyk_line_(__LINE__)

#define cyk_assert(code) \
    if (!(code)) \
        cyk_panic("cyk_assert(" __FILE__ ":" cyk_line() ") " #code);

} // }}}

namespace cyk {

long sys_argc() {
    return syscall_0("risc0_zkvm_platform::syscall::nr::SYS_ARGC", nullptr, 0);
}

long sys_argv(void *data, size_t size, size_t index) {
    return syscall_1("risc0_zkvm_platform::syscall::nr::SYS_ARGV", data, size, index);
}

long sys_random(void *data, size_t size) {
    return syscall_0("risc0_zkvm_platform::syscall::nr::SYS_RANDOM", data, size / sizeof(uint32_t));
}

std::pair<long, long> sys_read(int file, void *data, size_t size) {
    return syscall_2_2("risc0_zkvm_platform::syscall::nr::SYS_READ", data, size / sizeof(uint32_t), (long) file, size);
}

long sys_write(int file, const void *data, size_t size) {
    return syscall_3("risc0_zkvm_platform::syscall::nr::SYS_WRITE", nullptr, 0, file, (long) data, size);
}

#define cyk_write2(x) \
    cyk::sys_write(2, x, sizeof(x)-1)

#define cyk_trace() \
    cyk_write2("cyk_trace(" __FILE__ ":" cyk_line() ")\n")

constexpr int bless(char hex) {
    return hex - (hex >= 'a' ? 'a' - 10 : hex >= 'A' ? 'A' - 10 : '0');
}

void print(const void *data, size_t size) {
    char hex[size*2+1];
    for (size_t i(0); i != size; ++i) {
        const auto value(reinterpret_cast<const uint8_t *>(data)[i]);
        hex[i*2+0] = "0123456789abcdef"[value>>4];
        hex[i*2+1] = "0123456789abcdef"[value&15];
    }
    hex[sizeof(hex)-1] = '\n';
    sys_write(2, hex, sizeof(hex));
}

template <typename Type_>
void print(const Type_ &data) {
    print(&data, sizeof(data));
}

template <size_t Size_ = 32>
struct Digest {
    uint8_t data_ alignas(4) [Size_];

    constexpr Digest() = default;

    consteval Digest(const char value[Size_ * 2 + 1]) {
        for (size_t i(0); i != sizeof(data_); ++i)
            data_[i] = bless(value[i*2]) << 4 | bless(value[i*2+1]);
    }

    const uint8_t *data() const {
        return data_; }
    size_t size() const {
        return sizeof(data_); }

    auto operator<=>(const Digest &) const = default;

    /*bool operator ==(const Digest &rhs) const {
        return memcmp(data_, rhs.data_, sizeof(data_)) == 0;
    }*/

    void clear() {
        const auto data(reinterpret_cast<uint32_t *>(data_));
        for (size_t i(0); i != sizeof(data_) / sizeof(uint32_t); ++i)
            data[i] = 0;
    }

    void bswap32() {
        const auto data(reinterpret_cast<uint32_t *>(data_));
        for (size_t i(0); i != sizeof(data_) / sizeof(uint32_t); ++i)
            data[i] = __builtin_bswap32(data[i]);
    }
};

struct Digest32 :
    Digest<32>
{
    using Digest::Digest;

#define SHA256_RESET "6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19"

    void reset() {
        const auto data(reinterpret_cast<uint32_t *>(data_));
        data[0] = 0x67e6096a; data[1] = 0x85ae67bb;
        data[2] = 0x72f36e3c; data[3] = 0x3af54fa5;
        data[4] = 0x7f520e51; data[5] = 0x8c68059b;
        data[6] = 0xabd9831f; data[7] = 0x19cde05b;
    }
};

constexpr Digest32 Sha256_Reset(SHA256_RESET);

// read {{{

void read(int file, void *data, size_t size) {
    const auto [writ, last] = sys_read(0, data, size);
    cyk_assert(writ == size);
    memcpy(reinterpret_cast<uint8_t *>(data) + (writ & ~0x3), reinterpret_cast<const uint8_t *>(&last), writ & 0x3);
}

template <typename Type_>
inline void read(int file, Type_ *data) {
    read(file, data, sizeof(data));
}

template <typename Type_>
inline Type_ read(int file) {
    Type_ data;
    read(file, &data);
    return data;
}

inline void read0(void *data, size_t size) {
    return read(0, data, size);
}

template <typename Type_>
inline void read0(Type_ *data) {
    read0(data, sizeof(*data));
}

template <typename Type_>
inline Type_ read0() {
    Type_ data;
    read0(&data);
    return data;
}

#define cyk_read0lve(name) \
    uint8_t name alignas(4) [cyk::read0<size_t>()]; \
    cyk::read0(data, sizeof(data));

template <typename Type_>
inline void read0lve(Type_ &data) {
    cyk_assert(cyk::read0<size_t>() == sizeof(data));
    cyk::read0(&data, sizeof(data));
}

template <typename Type_, size_t Size_>
void read0lve(Type_ data[Size_]) {
    cyk_assert(cyk::read0<size_t>() == sizeof(data));
    cyk::read0(data, sizeof(data));
}

// }}}
// sha256 {{{

long sha256compress(Digest<32> &output, const Digest<32> &input, const uint8_t one[32], const uint8_t two[32]) {
    //print(*reinterpret_cast<const Digest<32> *>(one));
    //print(*reinterpret_cast<const Digest<32> *>(two));
    return ecall_5(3, (long) output.data_, (long) input.data_, (long) one, (long) two, 1);
}

inline long sha256compress(Digest<32> &digest, const uint8_t one[32], const uint8_t two[32]) {
    return sha256compress(digest, digest, one, two);
}

class Sha256 {
  public:
    Digest32 state_;
  private:
    uint8_t block_ alignas(4) [64];
    size_t size_ = 0;
    uint64_t bits_ = 0;

  public:
    Sha256() { state_.reset(); }

    void operator ()(const Digest32 &left, const Digest32 &right) {
        if (size_ == 0) [[likely]]
            sha256compress(state_, left.data_, right.data_);
        else {
            operator ()(left.data_, sizeof(left.data_));
            operator ()(right.data_, sizeof(right.data_));
        }
    }

    void operator ()(const void *data, size_t size) {
        auto here(reinterpret_cast<const uint8_t *>(data));
        bits_ += size * 8;
        while (size != 0)
            if (size_ == 0 && size >= sizeof(block_)) {
                sha256compress(state_, here, here + 32);
                here += sizeof(block_);
                size -= sizeof(block_);
            } else if (size_ == 32 && size >= 32) {
                sha256compress(state_, block_, here);
                size_ = 0;
                here += 32;
                size -= 32;
            } else if (size_t left(sizeof(block_) - size_); size >= left) {
                memcpy(block_ + size_, here, left);
                sha256compress(state_, block_, block_ + 32);
                size_ = 0;
                size -= left;
                here += left;
            } else {
                memcpy(block_ + size_, here, size);
                size_ += size;
                break;
            }
    }

    template <typename Type_>
    void operator ()(const Type_ &value) {
        return operator ()(&value, sizeof(value));
    }

    Digest32 operator ()() {
        block_[size_++] = 0x80;

        Digest32 digest;
        if (sizeof(block_) - size_ < sizeof(uint64_t)) {
            memset(block_ + size_, 0, sizeof(block_) - size_);
            sha256compress(state_, block_, block_ + 32);
            size_ = 0;
        }

        memset(block_ + size_, 0, sizeof(block_) - sizeof(uint64_t) - size_);
        *reinterpret_cast<uint64_t *>(block_ + sizeof(block_) - sizeof(uint64_t)) = __builtin_bswap64(bits_);
        sha256compress(digest, state_, block_, block_ + 32);
        return digest;
    }
};

Digest32 sha256(const uint8_t *data, size_t size) {
    Sha256 hasher;
    hasher(data, size);
    return hasher();
}

// }}}
// tagging {{{

namespace {
    namespace tag {
        constexpr Digest32 Null("0000000000000000000000000000000000000000000000000000000000000000");
        constexpr Digest32 SystemState_Halted("a3acc27117418996340b84e5a90f3ef4c49d22c79e44aad822ec9c313e1eb8e2");

        constexpr Digest32 Assumption("9fb524f65d5de53ce0b5dfeb62fd586678676f67a22f58b071c48a46505a2ee8");
        constexpr Digest32 Assumptions("8e378d4256f07898df0bb8912f5da80f8e78448c2a7b321f9232e21124186839");
        constexpr Digest32 Output("77eafeb366a78b47747de0d7bb176284085ff5564887009a5be63da32d3559d4");
        constexpr Digest32 ReceiptClaim("cb1fefcd1f2d9a64975cbbbf6e161e2914434b0cbb9960b84df5d717e86b48af");
    }

    Digest32 tagged(const std::initializer_list<const Digest32 *> &down, const std::initializer_list<uint32_t> &data) {
        Sha256 hasher;
        for (size_t i(0); i != down.size(); ++i)
            hasher(&down[i]->data_, sizeof(Digest32));
        for (size_t i(0); i != data.size(); ++i)
            hasher(&data[i], sizeof(uint32_t));
        uint16_t size(down.size() - 1);
        hasher(&size, sizeof(uint16_t));
        return hasher();
    }
}

// }}}
// commitment {{{

namespace {
    Sha256 journal_;
    Digest32 assumptions_;
}

void commit(const uint8_t *data, size_t size) {
    sys_write(3, data, size);
    journal_(data, size);
}

template <typename Type_>
inline void commit(const Type_ &data) {
    return commit(reinterpret_cast<const uint8_t *>(&data), sizeof(data));
}

struct Assumption {
    Digest32 claim;
    Digest32 control;
};

void verify(const Assumption &assumption) {
    syscall_2("risc0_zkvm_platform::syscall::nr::SYS_VERIFY_INTEGRITY", nullptr, 0, (long) &assumption, sizeof(assumption));
    Digest32 digest(tagged({&tag::Assumption, &assumption.claim, &assumption.control}, {}));
    assumptions_ = tagged({&tag::Assumptions, &digest, &assumptions_}, {});
}

void verify(const Digest32 &image, const Digest32 &journal) {
    Digest32 output(tagged({&tag::Output, &journal, &tag::Null}, {}));
    return verify({tagged({&tag::ReceiptClaim, &tag::Null, &image, &tag::SystemState_Halted, &output}, {0, 0}), {}});
}

// }}}
// keccak256 {{{

namespace {

struct KeccakState {
    uint64_t data_[25] = {};

    inline KeccakState &operator =(const KeccakState &rhs) {
        for (size_t i(0); i != 25; ++i)
            data_[i] = rhs.data_[i];
        return *this;
    }
};

constexpr Digest32 KECCAK_CONTROL_ROOT("c4c6721b179b8501218a842a3731e14017f0cc2eaaba2d076f98eb2aa305564f");

class Batcher {
  private:
    static constexpr unsigned po2 = 17;
    KeccakState state_[(1<<po2)/200];

    size_t count_ = 0;
    Digest32 claim_{};

    void commit(KeccakState &state) {
        sha256compress(claim_, reinterpret_cast<uint8_t *>(state.data_+0), reinterpret_cast<uint8_t *>(state.data_+4));
        sha256compress(claim_, reinterpret_cast<uint8_t *>(state.data_+8), reinterpret_cast<uint8_t *>(state.data_+12));
        sha256compress(claim_, reinterpret_cast<uint8_t *>(state.data_+16), reinterpret_cast<uint8_t *>(state.data_+20));
        static Digest32 last{}, zero{};
        reinterpret_cast<uint64_t *>(last.data_)[0] = state.data_[24];
        sha256compress(claim_, last.data_, zero.data_);
    }

  public:
    consteval Batcher() = default;

    void flush() {
        if (count_ == 0)
            return;

        claim_.bswap32(); //?!
        syscall_5("risc0_zkvm_platform::syscall::nr::SYS_PROVE_KECCAK", nullptr, 0, (long) claim_.data_, po2, (long) KECCAK_CONTROL_ROOT.data_, (long) state_, count_ * 50);
        verify({claim_, KECCAK_CONTROL_ROOT});

        count_ = 0;
    }

    void operator ()(KeccakState &state) {
        if (count_ == 0)
            claim_.reset();

        state_[count_++] = state;

        commit(state);
        syscall_1("risc0_zkvm_platform::syscall::nr::SYS_KECCAK", state.data_, 50, (long) state.data_);
        commit(state);

        if (count_ == sizeof(state_) / sizeof(state_[0]))
            flush();
    }
} batcher_;

}

// this code mostly taken from SHA3IUF; thanks!
// Aug 2015. Andrey Jivsov. crypto@brainhub.org

#define SHA3_KECCAK_SPONGE_WORDS (((1600)/8)/sizeof(uint64_t))

#define SHA3_ROTL64(x, y) \
	(((x) << (y)) | ((x) >> ((sizeof(uint64_t)*8) - (y))))

constexpr uint64_t keccakf_rndc[24] = {
    0x0000000000000001ULL, 0x0000000000008082ULL, 0x800000000000808aULL, 0x8000000080008000ULL,
    0x000000000000808bULL, 0x0000000080000001ULL, 0x8000000080008081ULL, 0x8000000000008009ULL,
    0x000000000000008aULL, 0x0000000000000088ULL, 0x0000000080008009ULL, 0x000000008000000aULL,
    0x000000008000808bULL, 0x800000000000008bULL, 0x8000000000008089ULL, 0x8000000000008003ULL,
    0x8000000000008002ULL, 0x8000000000000080ULL, 0x000000000000800aULL, 0x800000008000000aULL,
    0x8000000080008081ULL, 0x8000000000008080ULL, 0x0000000080000001ULL, 0x8000000080008008ULL,
};

constexpr unsigned keccakf_rotc[24] = { 1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 2, 14, 27, 41, 56, 8, 25, 43, 62, 18, 39, 61, 20, 44 };
constexpr unsigned keccakf_piln[24] = { 10, 7, 11, 17, 18, 3, 5, 16, 8, 21, 24, 4, 15, 23, 19, 13, 12, 2, 20, 14, 22, 9, 6, 1 };

class Keccak256 {
  private:
    uint64_t saved = 0;
    uint64_t s[25] = {};
    unsigned byteIndex = 0;
    unsigned wordIndex = 0;
    static constexpr unsigned capacityWords = 8;

    inline void keccakf() {
#if 1
        batcher_(*reinterpret_cast<KeccakState *>(s));
#else
        for (int round = 0; round < 24; round++) {
            uint64_t bc[5];
            for (int i = 0; i < 5; i++)
                bc[i] = s[i] ^ s[i + 5] ^ s[i + 10] ^ s[i + 15] ^ s[i + 20];

            for (int i = 0; i < 5; i++) {
                uint64_t t = bc[(i + 4) % 5] ^ SHA3_ROTL64(bc[(i + 1) % 5], 1);
                for (int j = 0; j < 25; j += 5)
                    s[j + i] ^= t;
            }

            uint64_t t = s[1];
            for (int i = 0; i < 24; i++) {
                int j = keccakf_piln[i];
                bc[0] = s[j];
                s[j] = SHA3_ROTL64(t, keccakf_rotc[i]);
                t = bc[0];
            }

            for (int j = 0; j < 25; j += 5) {
                for (int i = 0; i < 5; i++)
                    bc[i] = s[j + i];
                for (int i = 0; i < 5; i++)
                    s[j + i] ^= (~bc[(i + 1) % 5]) & bc[(i + 2) % 5];
            }

            s[0] ^= keccakf_rndc[round];
        }
#endif
    }

  public:
    void operator ()(const void *bufIn, size_t len) {
        unsigned old_tail = (8 - byteIndex) & 7;
        const uint8_t *buf = reinterpret_cast<const uint8_t *>(bufIn);

        if (len < old_tail) {
            while (len--)
                saved |= (uint64_t) (*(buf++)) << ((byteIndex++) * 8);
            return;
        }

        if (old_tail) {
            len -= old_tail;
            while (old_tail--)
                saved |= (uint64_t) (*(buf++)) << ((byteIndex++) * 8);
            s[wordIndex] ^= saved;
            byteIndex = 0;
            saved = 0;
            if (++wordIndex == (SHA3_KECCAK_SPONGE_WORDS - capacityWords)) {
                keccakf();
                wordIndex = 0;
            }
        }

        size_t words = len / sizeof(uint64_t);
        unsigned tail = len - words * sizeof(uint64_t);

        for (size_t i = 0; i < words; i++, buf += sizeof(uint64_t)) {
            const uint64_t t = (uint64_t) (buf[0]) |
                    ((uint64_t) (buf[1]) << 8 * 1) |
                    ((uint64_t) (buf[2]) << 8 * 2) |
                    ((uint64_t) (buf[3]) << 8 * 3) |
                    ((uint64_t) (buf[4]) << 8 * 4) |
                    ((uint64_t) (buf[5]) << 8 * 5) |
                    ((uint64_t) (buf[6]) << 8 * 6) |
                    ((uint64_t) (buf[7]) << 8 * 7);
            s[wordIndex] ^= t;
            if (++wordIndex == (SHA3_KECCAK_SPONGE_WORDS - capacityWords)) {
                keccakf();
                wordIndex = 0;
            }
        }

        while (tail--)
            saved |= (uint64_t) (*(buf++)) << ((byteIndex++) * 8);
    }

    Digest32 operator ()() {
        uint64_t t = (uint64_t)(((uint64_t) 1) << (byteIndex * 8));
        s[wordIndex] ^= saved ^ t;
        s[SHA3_KECCAK_SPONGE_WORDS - capacityWords - 1] ^= 0x8000000000000000ULL;
        keccakf();

        Digest32 digest;
        for (size_t i(0); i != 4; ++i)
            reinterpret_cast<uint64_t *>(digest.data_)[i] = s[i];
        return digest;
    }
};

Digest32 keccak256(const uint8_t *data, size_t size) {
    Keccak256 hasher;
    hasher(data, size);
    return hasher();
}

// }}}
// stop {{{
namespace {
    uint32_t random_[4];

    void ready() {
        sys_random(random_, sizeof(random_));
        journal_.state_.reset();
    }

    [[noreturn]]
    __attribute__((noinline))
    long sys_halt(int intent, int status) {
        batcher_.flush();
        const Digest32 journal(journal_());
        const Digest32 output(tagged({&tag::Output, &journal, &assumptions_}, {}));
        return ecall_2(0, intent | (long) status << 8, (long) output.data_);
    }
}

inline void pause(int status) {
    sys_halt(1, status);
    ready();
    assumptions_.clear();
}
// }}}

}

// <stdlib> {{{
extern "C" [[noreturn]] void exit(int status) {
    cyk::sys_halt(0, status);
}

extern "C" [[noreturn]] void abort() {
    cyk_panic("abort()");
    return exit(1);
}

extern "C" void *malloc(size_t size) {
    cyk_panic("malloc()");
    return nullptr;
}

extern "C" void free(void *data) {
    cyk_panic("free()");
}
// }}}
// _start {{{
extern "C" int main();

namespace cyk {
extern "C" void start() {
    ready();
    exit(main());
} }

__attribute__((naked))
extern "C" void _start() {
    __asm__(R"(
        .option push
        .option norelax
        la gp, __global_pointer$
        .option pop
        la sp, 0x00200400
        call start
    )");
}
// }}}
