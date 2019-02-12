/*
 * islandhack-io - library to override system certificate authority database
 *
 * Copyright (c) 2019 Benjamin Moody
 *
 * This program is free software: you can redistribute it and/or
 * modify it under the terms of the GNU Affero General Public License
 * as published by the Free Software Foundation, either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#define _GNU_SOURCE
#include <dlfcn.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <errno.h>

int __open(const char *, int, ...);
int __open64(const char *, int, ...);
int __open_2(const char *, int);
int __open64_2(const char *, int);
int __openat_2(int, const char *, int);
int __openat64_2(int, const char *, int);

static int init_done;

static int (*real_open)(const char *, int, ...);
static int (*real_open64)(const char *, int, ...);
static int (*real_openat)(int, const char *, int, ...);
static int (*real_openat64)(int, const char *, int, ...);
static FILE * (*real_fopen)(const char *, const char *);
static FILE * (*real_fopen64)(const char *, const char *);
static FILE * (*real_freopen)(const char *, const char *, FILE *);
static FILE * (*real_freopen64)(const char *, const char *, FILE *);
static int (*real___open)(const char *, int, ...);
static int (*real___open64)(const char *, int, ...);
static int (*real___open_2)(const char *, int);
static int (*real___open64_2)(const char *, int);
static int (*real___openat_2)(int, const char *, int);
static int (*real___openat64_2)(int, const char *, int);
static int (*real___xstat)(int, const char *, struct stat *);
static int (*real___xstat64)(int, const char *, struct stat64 *);
static int (*real___lxstat)(int, const char *, struct stat *);
static int (*real___lxstat64)(int, const char *, struct stat64 *);
static int (*real___fxstatat)(int, int, const char *, struct stat *, int);
static int (*real___fxstatat64)(int, int, const char *, struct stat64 *, int);

#define MAXPREFIXES 3
static struct prefix {
    int length;
    char *prefix;
} ca_prefixes[MAXPREFIXES];

static const char *fake_cert_file;

#define LOOKUP_NEXT(name) do {                  \
        real_##name = dlsym(RTLD_NEXT, #name);  \
        (void) (real_##name == name);           \
    } while (0);

static void add_prefix(const char *s)
{
    int i;
    for (i = 0; i < MAXPREFIXES; i++) {
        if (!ca_prefixes[i].prefix) {
            ca_prefixes[i].prefix = strdup(s);
            ca_prefixes[i].length = strlen(s);
            return;
        }
    }
}

static void __attribute__((constructor)) init()
{
    const char *s;

    if (!init_done) {
        LOOKUP_NEXT(open);        LOOKUP_NEXT(open64);
        LOOKUP_NEXT(openat);      LOOKUP_NEXT(openat64);
        LOOKUP_NEXT(fopen);       LOOKUP_NEXT(fopen64);
        LOOKUP_NEXT(freopen);     LOOKUP_NEXT(freopen64);
        LOOKUP_NEXT(__open);      LOOKUP_NEXT(__open64);
        LOOKUP_NEXT(__open_2);    LOOKUP_NEXT(__open64_2);
        LOOKUP_NEXT(__openat_2);  LOOKUP_NEXT(__openat64_2);
        LOOKUP_NEXT(__xstat);     LOOKUP_NEXT(__xstat64);
        LOOKUP_NEXT(__lxstat);    LOOKUP_NEXT(__lxstat64);
        LOOKUP_NEXT(__fxstatat);  LOOKUP_NEXT(__fxstatat64);

        if ((s = getenv("SSL_CERT_FILE")))
            fake_cert_file = strdup(s);

        add_prefix("/etc/ssl/certs/");
        add_prefix("/etc/pki/tls/certs/");
        if ((s = getenv("ISLANDHACK_SYS_CA_PREFIX")))
            add_prefix(s);

        init_done = 1;
    }
}

static const char * map_name(const char *name)
{
    int i;
    init();
    for (i = 0; i < MAXPREFIXES && ca_prefixes[i].prefix; i++)
        if (!strncmp(name, ca_prefixes[i].prefix, ca_prefixes[i].length))
            return (fake_cert_file ? fake_cert_file : "/dev/null");
    return name;
}

#define WRAP(rtype, func, argtypelist, setup, arglist)  \
    rtype func argtypelist                              \
    {                                                   \
        setup;                                          \
        return (*real_##func) arglist;                  \
    }

#define WSETUP0 NAME = map_name(NAME)

#define WSETUP1(parg, vtype, varg)                              \
    va_list ap; vtype varg;                                     \
    va_start(ap, parg); varg = va_arg(ap, vtype); va_end(ap);   \
    WSETUP0

#define WRAP2A(rtype, func, t1, a1, t2, a2)                     \
    WRAP(rtype, func, (t1 a1, t2 a2),                           \
         WSETUP0, (a1, a2))

#define WRAP2V(rtype, func, t1, a1, t2, a2, t3, a3)             \
    WRAP(rtype, func, (t1 a1, t2 a2, ...),                      \
         WSETUP1(a2, t3, a3), (a1, a2, a3))

#define WRAP3A(rtype, func, t1, a1, t2, a2, t3, a3)             \
    WRAP(rtype, func, (t1 a1, t2 a2, t3 a3),                    \
         WSETUP0, (a1, a2, a3))

#define WRAP3V(rtype, func, t1, a1, t2, a2, t3, a3, t4, a4)     \
    WRAP(rtype, func, (t1 a1, t2 a2, t3 a3, ...),               \
         WSETUP1(a3, t4, a4), (a1, a2, a3, a4))

#define WRAP5A(rtype, func, t1, a1, t2, a2, t3, a3, t4, a4, t5, a5)     \
    WRAP(rtype, func, (t1 a1, t2 a2, t3 a3, t4 a4, t5 a5),              \
         WSETUP0, (a1, a2, a3, a4, a5))

WRAP2V(int, open,         const char *, NAME, int, flags, mode_t, mode)
WRAP2V(int, open64,       const char *, NAME, int, flags, mode_t, mode)

WRAP2V(int, __open,       const char *, NAME, int, flags, mode_t, mode)
WRAP2V(int, __open64,     const char *, NAME, int, flags, mode_t, mode)

WRAP2A(int, __open_2,     const char *, NAME, int, flags)
WRAP2A(int, __open64_2,   const char *, NAME, int, flags)

WRAP3V(int, openat,       int, fd, const char *, NAME, int, flags, mode_t, mode)
WRAP3V(int, openat64,     int, fd, const char *, NAME, int, flags, mode_t, mode)

WRAP3A(int, __openat_2,   int, fd, const char *, NAME, int, flags)
WRAP3A(int, __openat64_2, int, fd, const char *, NAME, int, flags)

WRAP2A(FILE *, fopen,     const char *, NAME, const char *, mode)
WRAP2A(FILE *, fopen64,   const char *, NAME, const char *, mode)

WRAP3A(FILE *, freopen,   const char *, NAME, const char *, mode, FILE *, fp)
WRAP3A(FILE *, freopen64, const char *, NAME, const char *, mode, FILE *, fp)

WRAP3A(int, __xstat,      int, ver, const char *, NAME, struct stat *, buf)
WRAP3A(int, __xstat64,    int, ver, const char *, NAME, struct stat64 *, buf)

WRAP3A(int, __lxstat,     int, ver, const char *, NAME, struct stat *, buf)
WRAP3A(int, __lxstat64,   int, ver, const char *, NAME, struct stat64 *, buf)

WRAP5A(int, __fxstatat,   int, ver, int, fd, const char *, NAME,
                          struct stat *, buf, int, flags)
WRAP5A(int, __fxstatat64, int, ver, int, fd, const char *, NAME,
                          struct stat64 *, buf, int, flags)
