# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# GNU Affero General Public License, Version 3 {{{ */
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# }}}


pwd := ./$(patsubst %/,%,$(patsubst $(CURDIR)/%,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))

cflags += -Wno-bitwise-op-parentheses
cflags += -Wno-dangling-else
cflags += -Wno-empty-body
cflags += -Wno-logical-op-parentheses
cflags += -Wno-missing-selector-name
cflags += -Wno-potentially-evaluated-expression

cflags += -fcoroutines-ts

cflags += -I$(pwd)/extra
cflags += -I$(output)/$(pwd)

cflags += -I$(pwd)/cppcoro/include

source += $(pwd)/cppcoro/lib/async_auto_reset_event.cpp
source += $(pwd)/cppcoro/lib/async_manual_reset_event.cpp
source += $(pwd)/cppcoro/lib/async_mutex.cpp
source += $(pwd)/cppcoro/lib/auto_reset_event.cpp
source += $(pwd)/cppcoro/lib/lightweight_manual_reset_event.cpp
source += $(pwd)/cppcoro/lib/spin_mutex.cpp
source += $(pwd)/cppcoro/lib/spin_wait.cpp
source += $(pwd)/cppcoro/lib/static_thread_pool.cpp

source += $(wildcard $(pwd)/source/*.cpp)
cflags += -I$(pwd)/source

#include $(pwd)/aleth.mk

cflags += $(patsubst %,-I%,$(wildcard $(pwd)/boost/libs/*/include))
cflags += $(patsubst %,-I%,$(wildcard $(pwd)/boost/libs/numeric/*/include))

cflags += -include $(pwd)/source/byte.hpp

source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_box/*.c)
source += $(pwd)/libsodium/src/libsodium/crypto_box/curve25519xsalsa20poly1305/box_curve25519xsalsa20poly1305.c
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_core/*/ref*/*.c)
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_generichash/*.c)
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_generichash/blake2b/ref/*.c)
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_hash/*.c)
#source += $(pwd)/libsodium/src/libsodium/crypto_hash/sha512/cp/hash_sha512_cp.c
source += $(pwd)/libsodium/src/libsodium/crypto_onetimeauth/poly1305/onetimeauth_poly1305.c
source += $(pwd)/libsodium/src/libsodium/crypto_onetimeauth/poly1305/donna/poly1305_donna.c
source += $(pwd)/libsodium/src/libsodium/crypto_pwhash/argon2/argon2-core.c
#source += $(pwd)/libsodium/src/libsodium/crypto_pwhash/argon2/argon2-fill-block-ref.c
#source += $(pwd)/libsodium/src/libsodium/crypto_pwhash/argon2/blake2b-long.c
source += $(pwd)/libsodium/src/libsodium/crypto_scalarmult/curve25519/scalarmult_curve25519.c
source += $(pwd)/libsodium/src/libsodium/crypto_scalarmult/curve25519/ref10/x25519_ref10.c
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_secretbox/*.c)
#source += $(pwd)/libsodium/src/libsodium/crypto_secretbox/xsalsa20poly1305/secretbox_xsalsa20poly1305.c
#source += $(pwd)/libsodium/src/libsodium/crypto_stream/chacha20/ref/chacha20_ref.c
source += $(pwd)/libsodium/src/libsodium/crypto_stream/chacha20/stream_chacha20.c
source += $(pwd)/libsodium/src/libsodium/crypto_stream/salsa20/stream_salsa20.c
source += $(pwd)/libsodium/src/libsodium/crypto_stream/salsa20/ref/salsa20_ref.c
#source += $(pwd)/libsodium/src/libsodium/crypto_stream/xsalsa20/stream_xsalsa20.c
source += $(pwd)/libsodium/src/libsodium/crypto_verify/sodium/verify.c
source += $(wildcard $(pwd)/libsodium/src/libsodium/randombytes/*.c)
source += $(wildcard $(pwd)/libsodium/src/libsodium/randombytes/sysrandom/*.c)
source += $(pwd)/libsodium/src/libsodium/sodium/core.c
source += $(pwd)/libsodium/src/libsodium/sodium/runtime.c
source += $(pwd)/libsodium/src/libsodium/sodium/utils.c

cflags += -I$(pwd)/libsodium/src/libsodium/include
cflags += -I$(pwd)/libsodium/src/libsodium/include/sodium
cflags += -DCONFIGURED
c_libsodium += -Wno-unused-variable

# crypto_pwhash/argon2/argon2-fill-block-ref.c
#c_libsodium += -Wno-unknown-pragmas

cflags += -I$(pwd)/boost/libs/asio/include/boost
#cflags += -DASIO_STANDALONE
#cflags += -I$(pwd)/asio/asio/include


cflags += -I$(pwd)/double-conversion
cflags += -I$(pwd)/folly

# XXX: BoringSSL and Folly conflict on sdallocx
c_boringssl += -Dsdallocx=sdallocx_
#cflags += -DFOLLY_HAVE_WEAK_SYMBOLS=1

cflags += -DFOLLY_HAVE_CLOCK_GETTIME=1
cflags += -DFOLLY_HAVE_PTHREAD=1
cflags += -DFOLLY_HAVE_PTHREAD_ATFORK=1
cflags += -DFOLLY_USE_LIBCPP=1
c_folly += -Wno-unused-variable

source += $(pwd)/folly/folly/Conv.cpp
source += $(pwd)/folly/folly/Demangle.cpp
source += $(pwd)/folly/folly/ExceptionWrapper.cpp
source += $(pwd)/folly/folly/Executor.cpp
source += $(pwd)/folly/folly/FileUtil.cpp
source += $(pwd)/folly/folly/Format.cpp
source += $(pwd)/folly/folly/ScopeGuard.cpp
source += $(pwd)/folly/folly/SharedMutex.cpp
source += $(pwd)/folly/folly/Singleton.cpp
source += $(pwd)/folly/folly/SingletonThreadLocal.cpp
source += $(pwd)/folly/folly/String.cpp

source += $(pwd)/folly/folly/detail/AtFork.cpp
source += $(pwd)/folly/folly/detail/Demangle.cpp
source += $(pwd)/folly/folly/detail/Futex.cpp
source += $(pwd)/folly/folly/detail/MemoryIdler.cpp
source += $(pwd)/folly/folly/detail/SingletonStackTrace.cpp
source += $(pwd)/folly/folly/detail/StaticSingletonManager.cpp
source += $(pwd)/folly/folly/detail/ThreadLocalDetail.cpp

source += $(pwd)/folly/folly/concurrency/CacheLocality.cpp
source += $(pwd)/folly/folly/executors/CPUThreadPoolExecutor.cpp
source += $(pwd)/folly/folly/executors/GlobalThreadPoolList.cpp
source += $(pwd)/folly/folly/executors/InlineExecutor.cpp
source += $(pwd)/folly/folly/executors/ManualExecutor.cpp
source += $(pwd)/folly/folly/executors/ThreadPoolExecutor.cpp
source += $(pwd)/folly/folly/fibers/Baton.cpp
source += $(pwd)/folly/folly/futures/Future.cpp
source += $(pwd)/folly/folly/io/async/Request.cpp
source += $(pwd)/folly/folly/lang/Assume.cpp
source += $(pwd)/folly/folly/lang/ColdClass.cpp
source += $(pwd)/folly/folly/lang/SafeAssert.cpp
source += $(pwd)/folly/folly/memory/MallctlHelper.cpp
source += $(pwd)/folly/folly/memory/detail/MallocImpl.cpp
source += $(pwd)/folly/folly/portability/SysMembarrier.cpp
source += $(pwd)/folly/folly/synchronization/AsymmetricMemoryBarrier.cpp
source += $(pwd)/folly/folly/synchronization/LifoSem.cpp
source += $(pwd)/folly/folly/synchronization/ParkingLot.cpp
source += $(pwd)/folly/folly/system/ThreadName.cpp

source += $(wildcard $(pwd)/double-conversion/double-conversion/*.cc)

#source += $(pwd)/folly/folly/container/detail/F14Table.cpp
#source += $(pwd)/folly/folly/executors/ExecutorWithPriority.cpp
#source += $(pwd)/folly/folly/executors/TimedDrivableExecutor.cpp
#source += $(pwd)/folly/folly/fibers/Fiber.cpp
#source += $(pwd)/folly/folly/fibers/FiberManager.cpp
#source += $(pwd)/folly/folly/fibers/GuardPageAllocator.cpp
#source += $(pwd)/folly/folly/futures/ThreadWheelTimekeeper.cpp
#source += $(pwd)/folly/folly/io/async/AsyncTimeout.cpp
#source += $(pwd)/folly/folly/io/async/EventBase.cpp
#source += $(pwd)/folly/folly/io/async/HHWheelTimer.cpp
#source += $(pwd)/folly/folly/net/NetOps.cpp
#source += $(pwd)/folly/folly/portability/Sockets.cpp
#source += $(pwd)/folly/folly/synchronization/Hazptr.cpp

source += $(wildcard $(pwd)/lwip/src/api/*.c)
source += $(wildcard $(pwd)/lwip/src/core/*.c)
source += $(wildcard $(pwd)/lwip/src/core/ipv4/*.c)
source += $(wildcard $(pwd)/lwip/src/core/ipv6/*.c)
#source += $(wildcard $(pwd)/lwip/src/netif/*.c)

cflags += -I$(pwd)/lwip/src/include
cflags += -I$(pwd)/lwip/contrib/ports/unix/port/include

include $(pwd)/target-$(target).mk
include $(pwd)/rtc/target.mk
