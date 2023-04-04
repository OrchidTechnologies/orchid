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


#undef _FORTIFY_SOURCE

#include <iostream>
#include <random>

#include <assert.h>
#include <cxxabi.h>
#include <dirent.h>
#include <dlfcn.h>
#include <execinfo.h>
#include <fcntl.h>
#include <nl_types.h>
#include <semaphore.h>
#include <signal.h>
#include <stdlib.h>
#include <syscall.h> // XXX
#include <unistd.h>

#include <sys/mman.h>
#include <sys/prctl.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/utsname.h>

#include "scope.hpp"

#define orc_trace() do { \
    std::cout << "_trace()@" << __FILE__ << ":" << __LINE__ << std::endl; \
} while (false)

#define __(x) extern "C" __typeof(x) __##x __attribute__((alias(#x)));

// NOLINTBEGIN(readability-inconsistent-declaration-parameter-name)

// *dir -> error {{{
DIR *opendir(const char *name) {
    return nullptr; } __(opendir)
int closedir(DIR *dirp) {
    errno = EINVAL; return -1; } __(closedir)
struct dirent *readdir(DIR *dirp) {
    return nullptr; } __(readdir)
// }}}
// FILE {{{
int open(const char *pathname, int flags, ...) {
    errno = ENOENT; return -1; } __(open)
int close(int fd) {
    errno = EBADF; return -1; } __(close)
ssize_t read(int fd, void *buf, size_t count) {
    errno = EBADF; return -1; } __(read)

#if 0
ssize_t write(int fd, const void *buf, size_t count) {
    __builtin_debugtrap();
    errno = EBADF; return -1;
} __(write)
#endif

off_t lseek(int fd, off_t offset, int whence) {
    errno = EBADF; return -1; } __(lseek)
off64_t lseek64(int fd, off64_t offset, int whence) {
    errno = EBADF; return -1; } __(lseek64)

FILE *fopen(const char *pathname, const char *mode) {
    errno = ENOENT; return nullptr; }
FILE *fdopen(int fd, const char *mode) {
    errno = ENOENT; return nullptr; }
int fclose(FILE *stream) {
    errno = EBADF; return EOF; }

FILE *stdin = reinterpret_cast<FILE *>(1);
FILE *stdout = reinterpret_cast<FILE *>(2);
FILE *stderr = reinterpret_cast<FILE *>(3);

int fileno(FILE *stream) {
    if (false);
    else if (stream == stdout)
        return 1;
    else if (stream == stderr)
        return 2;
    else abort();
} __(fileno)

size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream) {
    const auto total(nmemb * size);
    // for some reason libcxx loves to call fwrite with 0 items during some kind of sync operation
    if (total == 0) return 0;
    // clang (incorrectly) rewrites fprintf() with constant format string to #,1 instead of 1,# :/
    // https://github.com/llvm/llvm-project/blob/main/llvm/lib/Transforms/Utils/SimplifyLibCalls.cpp
    // https://github.com/llvm/llvm-project/blob/main/llvm/test/Transforms/InstCombine/fprintf-1.ll
    // https://github.com/llvm/llvm-project/blob/main/llvm/lib/Transforms/Utils/BuildLibCalls.cpp
    // https://virtuallyfun.com/wordpress/2018/03/01/fread-and-fwrite-demystified-stdio-on-unix-v7/
    // https://www.tuhs.org/cgi-bin/utree.pl?file=V7/usr/src/libc/stdio/rdwr.c
    // https://retrocomputing.stackexchange.com/questions/16633/is-this-the-reason-why-fread-fwrite-has-2-size-t-arguments
    // https://sourceware.org/git/?p=glibc.git;a=blob;f=libio/iofwrite.c;h=640b0a7c2be46e05b7c4750ce6f0330ad6e39d3d;hb=HEAD
    const auto writ(write(fileno(stream), ptr, total));
    return writ >= 0 ? writ / size : 0;
}

int fputc(int c, FILE *stream) {
    return fwrite(&c, 1, 1, stream) == 1 ? c : EOF;
}

int fputs(const char *s, FILE *stream) {
    return fwrite(s, 1, strlen(s), stream);
}

int fflush(FILE *stream) {
    return 0;
}

char *fgets(char *s, int size, FILE *stream) { abort(); }
size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream) { abort(); }
size_t fread_unlocked(void *ptr, size_t size, size_t nmemb, FILE *stream) { abort(); } __(fread_unlocked)
int fscanf(FILE *stream, const char *format, ...) { abort(); }
int fseek(FILE *stream, long offset, int whence) { abort(); }
int fseeko(FILE *stream, off_t offset, int whence) { abort(); }
long ftell(FILE *stream) { abort(); }
off_t ftello(FILE *stream) { abort(); } __(ftello)
int getc(FILE *stream) { abort(); }
void rewind(FILE *stream) { abort(); }
int setvbuf(FILE *stream, char *buf, int mode, size_t size) { abort(); }
FILE *tmpfile(void) { abort(); }
int ungetc(int c, FILE *stream) { abort(); }
// }}}
// get* -> stub {{{
char *secure_getenv(const char *name) { return nullptr; }
char *getenv(const char *name) { return secure_getenv(name); }

static const pid_t pid_(1);
pid_t getpid() { return pid_; } __(getpid)

static const gid_t gid_(500);
gid_t getgid() { return gid_; } __(getgid)
gid_t getegid() { return gid_; } __(getegid)

static const uid_t uid_(500);
uid_t getuid() { return uid_; } __(getuid)
uid_t geteuid() { return uid_; } __(geteuid)
// }}}
// *link -> error {{{
ssize_t readlink(const char *pathname, char *buf, size_t bufsiz) {
    errno = ENOENT; return -1; }
int unlink(const char *pathname) {
    errno = ENOENT; return -1; }
// }}}
// pthread_* {{{
int pthread_atfork(void (*) (), void (*) (), void (*) ()) { return 0; }
int pthread_attr_destroy(pthread_attr_t *) { return 0; }
int pthread_attr_init(pthread_attr_t *) { return 0; }
int pthread_attr_setstacksize(pthread_attr_t *, size_t) { return 0; }
int pthread_cond_broadcast(pthread_cond_t *) { return 0; }
int pthread_cond_destroy(pthread_cond_t *) { return 0; }
int pthread_cond_init(pthread_cond_t *, const pthread_condattr_t *) { return 0; }
int pthread_cond_signal(pthread_cond_t *) { return 0; }
int pthread_cond_timedwait(pthread_cond_t *, pthread_mutex_t *, const struct timespec *) { abort(); } // XXX
int pthread_cond_wait(pthread_cond_t *, pthread_mutex_t *) { abort(); }
int pthread_condattr_destroy(pthread_condattr_t *) { return 0; }
int pthread_condattr_init(pthread_condattr_t *) { return 0; }
int pthread_condattr_setclock(pthread_condattr_t *, clockid_t) { return 0; }
int pthread_create(pthread_t *, const pthread_attr_t *, void *(*)(void *), void *) { abort(); }
int pthread_equal(pthread_t, pthread_t) { return 1; }
int pthread_join(pthread_t, void **) { abort(); }
int pthread_kill(pthread_t, int) { abort(); }
int pthread_mutex_destroy(pthread_mutex_t *) { return 0; }
int pthread_mutex_init(pthread_mutex_t *, const pthread_mutexattr_t *) { return 0; }
int pthread_mutex_lock(pthread_mutex_t *) { return 0; }
int pthread_mutex_trylock(pthread_mutex_t *) { return 0; } __(pthread_mutex_lock)
int pthread_mutex_unlock(pthread_mutex_t *) { return 0; } __(pthread_mutex_unlock)
int pthread_mutexattr_destroy(pthread_mutexattr_t *) { return 0; }
int pthread_mutexattr_init(pthread_mutexattr_t *) { return 0; }
int pthread_mutexattr_settype(pthread_mutexattr_t *, int) { return 0; }
int pthread_rwlock_destroy(pthread_rwlock_t *) { return 0; }
int pthread_rwlock_init(pthread_rwlock_t *, const pthread_rwlockattr_t *) { return 0; } __(pthread_rwlock_init)
int pthread_rwlock_rdlock(pthread_rwlock_t *) { return 0; } __(pthread_rwlock_rdlock)
int pthread_rwlock_tryrdlock(pthread_rwlock_t *) { return 0; }
int pthread_rwlock_unlock(pthread_rwlock_t *) { return 0; } __(pthread_rwlock_unlock)
int pthread_rwlock_wrlock(pthread_rwlock_t *) { return 0; } __(pthread_rwlock_wrlock)
pthread_t pthread_self() { return 0; }
void pthread_testcancel() {} __(pthread_testcancel)
int pthread_setname_np(pthread_t, const char *) { return 0; }
// }}}
// pthread_once {{{
int pthread_once (pthread_once_t *control, void (*routine)()) {
    if (*control == PTHREAD_ONCE_INIT) {
        *control = ~PTHREAD_ONCE_INIT;
        (*routine)();
    }
    return 0;
} __(pthread_once)
// }}}
// pthread_*specific {{{
static unsigned specific_(0);
static const void *specifics_[64];

int pthread_key_create(pthread_key_t *key, void (*)(void *)) {
    if (specific_ == sizeof(specifics_) / sizeof(specifics_[0])) abort();
    *key = specific_++;
    return 0;
} __(pthread_key_create)

int pthread_key_delete(pthread_key_t key) {
    return 0;
}

void *pthread_getspecific(pthread_key_t key) {
    return const_cast<void *>(specifics_[key]);
}

int pthread_setspecific(pthread_key_t key, const void *value) {
    specifics_[key] = value;
    return 0;
}
// }}}
// sched* -> return {{{
int __sched_cpucount(size_t, const cpu_set_t *) { return 1; }
int sched_getcpu() { return 0; }
int sched_setaffinity(pid_t, size_t, const cpu_set_t *) { return 0; }
int sched_getaffinity(pid_t, size_t, cpu_set_t *) { return 0; }
// }}}
// sem_* {{{
int sem_destroy(sem_t *) { return 0; }
int sem_init(sem_t *, int, unsigned int) { return 0; }
// XXX: implement EOVERFLOW
int sem_post(sem_t *) { return 0; }
int sem_wait(sem_t *) { abort(); }
// }}}
// *sig* -> abort {{{
int pthread_sigmask(int, const sigset_t *, sigset_t *) { abort(); }
int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact) { abort(); } __(sigaction)
int sigemptyset(sigset_t *) { abort(); }
int sigfillset(sigset_t *) { abort(); }
sighandler_t signal(int signum, sighandler_t handler) { abort(); }
// }}}
// *stat -> error {{{
int stat(const char *pathname, struct stat *statbuf) {
    errno = ENOENT; return -1; }
int stat64(const char *pathname, struct stat64 *statbuf) {
    errno = ENOENT; return -1; } __(stat64)
int fstat(int fd, struct stat *statbuf) {
    errno = EBADF; return -1; }
int fstat64(int fd, struct stat64 *statbuf) {
    errno = EBADF; return -1; } __(fstat64)
int lstat(const char *pathname, struct stat *statbuf) {
    errno = ENOENT; return -1; } __(lstat)
int lstat64(const char *pathname, struct stat64 *statbuf) {
    errno = ENOENT; return -1; } __(lstat64)
// }}}
// sysconf {{{
long sysconf(int name) {
    switch (name) {
        case _SC_NPROCESSORS_CONF:
            return 1;
        case _SC_NPROCESSORS_ONLN:
            return 1;
        case _SC_PAGESIZE:
            return 0x1000;
        case _SC_PHYS_PAGES:
            return 0x1000; // XXX
        case _SC_THREAD_STACK_MIN:
            return 0x10000; // XXX
        default:
            abort();
            errno = EINVAL;
            return -1;
    }
}

extern "C" __typeof(sysconf) __sysconf __attribute__((alias("sysconf")));
// }}}
// *time* {{{
int clock_gettime(clockid_t clk_id, struct timespec *tp) {
    switch (clk_id) {
        case CLOCK_MONOTONIC:
        case CLOCK_MONOTONIC_COARSE:
            break;
        default: errno = EINVAL; return -1;
    }

    if (tp == nullptr) { errno = EFAULT; return -1; }
    // XXX: implement time!!!
    tp->tv_sec = 1000;
    tp->tv_nsec = 0;
    return 0;
}

int gettimeofday(struct timeval *tv, void *tz) {
    struct timespec tp;
    if (clock_gettime(CLOCK_MONOTONIC, &tp) == -1) return -1;
    if (tz != nullptr) abort();
    tv->tv_sec = tp.tv_sec;
    tv->tv_usec = tp.tv_nsec / 1000;
    return 0;
}

time_t time(time_t *tloc) {
    struct timespec tp;
    if (clock_gettime(CLOCK_MONOTONIC, &tp) == -1) return -1;
    if (tloc != nullptr) *tloc = tp.tv_sec;
    return tp.tv_sec;
}
// }}}

extern "C" const char *_dl_get_origin () { return "/_"; }

extern "C" void __tls_pre_init_tp() {}
extern "C" void __tls_init_tp() {}

int prctl(int option, ...) { abort(); }

long syscall(long number, ...) {
    switch (number) {
        case SYS_gettid:
            return pid_;
        default: abort();
    }
}

char *getcwd(char *buf, size_t size) {
    if (size < 2) { errno = ERANGE; return nullptr; }
    buf[0] = '/'; buf[1] = '\0'; return buf;
} __(getcwd)


int uname(struct utsname *buf) {
    snprintf(buf->sysname, sizeof(buf->sysname) - 1, "Linux");
    snprintf(buf->nodename, sizeof(buf->nodename) - 1, "V8");
    snprintf(buf->release, sizeof(buf->release) - 1, "4.4.0");
    snprintf(buf->version, sizeof(buf->version) - 1, "");
    snprintf(buf->machine, sizeof(buf->machine) - 1, "x86_64");
    snprintf(buf->domainname, sizeof(buf->domainname) - 1, "example.com");
    return 0;
} __(uname)


int raise(int sig) { abort(); }

int kill(pid_t pid, int sig) {
    if (pid != pid_) abort();
    return raise(sig);
}


int sched_yield(void) { abort(); } __(sched_yield)

int usleep(useconds_t usec) {
    if (usec != 0) abort();
    return 0;
}

// NOLINTEND(readability-inconsistent-declaration-parameter-name)
