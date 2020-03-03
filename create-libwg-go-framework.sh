#!/bin/bash

set -euo pipefail

if [ ! -d lib ]; then
    echo "Please run the project first!"
    exit 1
fi

FWNAME=libwg-go
FWROOT=frameworks

if [ -d $FWROOT ]; then
    echo "Removing previous $FWNAME.framework copies"
    rm -rf $FWROOT
fi

ALL_SYSTEMS=("iPhone")

function check_bitcode() {
    local FWDIR=$1

    BITCODE_PATTERN="__bitcode"

    if otool -l "$FWDIR/$FWNAME" | grep "${BITCODE_PATTERN}" >/dev/null; then
        echo "INFO: $FWDIR contains Bitcode"
    else
        echo "INFO: $FWDIR doesn't contain Bitcode"
    fi
}

for SYS in ${ALL_SYSTEMS[@]}; do
    SYSDIR="$FWROOT/$SYS"
    FWDIR="$SYSDIR/$FWNAME.framework"

    if [[ -e lib/libwg-go.a ]]; then
        echo "Creating framework for $SYS"
        mkdir -p $FWDIR/Headers
        libtool -static -o $FWDIR/$FWNAME lib/libwg-go.a
        #cp -r include/* $FWDIR/Headers/
        cp -L assets/$SYS/Info.plist $FWDIR/Info.plist
        echo "Created $FWDIR"
        check_bitcode $FWDIR
    else
        echo "Skipped framework for $SYS"
    fi
done
