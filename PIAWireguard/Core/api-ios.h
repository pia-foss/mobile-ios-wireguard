//
//  api-ios.h
//  PIAWireguard
//  
//  Created by Jose Antonio Blaya Garcia on 27/03/2020.
//  Copyright © 2020 Private Internet Access, Inc.
//
//  This file is part of the Private Internet Access iOS Client.
//
//  The Private Internet Access iOS Client is free software: you can redistribute it and/or
//  modify it under the terms of the GNU General Public License as published by the Free
//  Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  The Private Internet Access iOS Client is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
//  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
//  details.
//
//  You should have received a copy of the GNU General Public License along with the Private
//  Internet Access iOS Client.  If not, see <https://www.gnu.org/licenses/>.
//

/* Code generated by cmd/cgo; DO NOT EDIT. */

/* package command-line-arguments */

#define WIREGUARD_GO_VERSION "0.0.20200121"

#line 1 "cgo-builtin-export-prolog"

#include <stddef.h> /* for ptrdiff_t below */

typedef struct {
    const char *p; size_t n;
} gostring_t;

typedef void(*logger_fn_t)(int level,
                           const char *msg);

#ifndef GO_CGO_EXPORT_PROLOGUE_H
#define GO_CGO_EXPORT_PROLOGUE_H

#ifndef GO_CGO_GOSTRING_TYPEDEF
typedef struct { const char *p; ptrdiff_t n; } _GoString_;
#endif

#endif

/* Start of preamble from import "C" comments.  */


#line 8 "api-ios.go"
 #include <stdlib.h>
 #include <sys/types.h>
 static void callLogger(void *func, int level, const char *msg)
 {
     ((void(*)(int, const char *))func)(level, msg);
 }

#line 1 "cgo-generated-wrapper"


/* End of preamble from import "C" comments.  */


/* Start of boilerplate cgo prologue.  */
#line 1 "cgo-gcc-export-header-prolog"

#ifndef GO_CGO_PROLOGUE_H
#define GO_CGO_PROLOGUE_H

typedef signed char GoInt8;
typedef unsigned char GoUint8;
typedef short GoInt16;
typedef unsigned short GoUint16;
typedef int GoInt32;
typedef unsigned int GoUint32;
typedef long long GoInt64;
typedef unsigned long long GoUint64;
typedef GoInt64 GoInt;
typedef GoUint64 GoUint;
typedef __SIZE_TYPE__ GoUintptr;
typedef float GoFloat32;
typedef double GoFloat64;
typedef float _Complex GoComplex64;
typedef double _Complex GoComplex128;

/*
  static assertion to make sure the file is being used on architecture
  at least with matching size of GoInt.
*/
typedef char _check_for_64_bit_pointer_matching_GoInt[sizeof(void*)==64/8 ? 1:-1];

typedef void *GoMap;
typedef void *GoChan;
typedef struct { void *t; void *v; } GoInterface;
typedef struct { void *data; GoInt len; GoInt cap; } GoSlice;

#endif

/* End of boilerplate cgo prologue.  */

#ifdef __cplusplus
extern "C" {
#endif


extern void wgEnableRoaming(GoUint8 p0);

extern void wgSetLogger(logger_fn_t p0);

extern GoInt32 wgTurnOn(gostring_t p0, GoInt32 p1);

extern void wgTurnOff(GoInt32 p0);

extern GoInt64 wgSetConfig(GoInt32 p0, gostring_t p1);

extern char* wgGetConfig(GoInt32 p0);

extern void wgBumpSockets(GoInt32 p0);

extern char* wgVersion();

#ifdef __cplusplus
}
#endif