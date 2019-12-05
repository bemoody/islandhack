#!/bin/sh
#
# Script for testing islandhack
#
# Copyright (c) 2019 Benjamin Moody
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

if [ $# != 3 ]; then
    echo "Usage: $0 islandhack temp-directory get-url-command" >&2
    exit 1
fi

ih=$1
tdata=$2
get=$3

unset ISLANDHACK_CACHE
unset ISLANDHACK_LOG
unset ISLANDHACK_AUTO_UPDATE
unset ISLANDHACK_HTTPS
unset ISLANDHACK_CA_CERT
unset ISLANDHACK_CA_KEY

data=example.cache

for proto in http https ftp; do
    goodurl=$proto://hello.test/hello
    badurl=$proto://hello.test/missing
    rm -rf $tdata
    mkdir $tdata

    # Test whether we can download and cache a working (fake) URL from
    # a second instance of islandhack.

    d="$get $goodurl (download)"
    c="$ih -d $data $ih -u -d $tdata $get $goodurl"
    v=`sh -c "$c" 2>$tdata/log`
    if [ $? != 200 ] || [ "$v" != "Hello, world" ]; then
        echo "$d: FAILED"
        echo " ** Failed command: $c"
        cat $tdata/log
        exit 1
    fi
    echo "$d: OK"

    # Test whether we can download and cache a non-working URL from a
    # second instance of islandhack.

    d="$get $badurl (download)"
    c="$ih -d $data $ih -u --remember-404 -d $tdata sh -c '! $get $badurl'"
    v=`sh -c "$c" 2>$tdata/log`
    if [ $? != 200 ] || [ "$v" != "" ]; then
        echo "$d: FAILED"
        echo " ** Failed command: $c"
        cat $tdata/log
        exit 1
    fi
    echo "$d: OK"

    # Test whether we can download a working URL from the cache
    # directory we just created.

    d="$get $goodurl (cached)"
    c="$ih -d $tdata $get $goodurl"
    v=`sh -c "$c" 2>$tdata/log`
    if [ $? != 0 ] || [ "$v" != "Hello, world" ]; then
        echo "$d: FAILED"
        echo " ** Failed command: $c"
        cat $tdata/log
        exit 1
    fi
    echo "$d: OK"

    # Test whether we can use download a non-working URL from the
    # cache directory we just created.

    d="$get $badurl (cached)"
    c="$ih -d $tdata sh -c '! $get $badurl'"
    v=`sh -c "$c" 2>$tdata/log`
    if [ $? != 0 ] || [ "$v" != "" ]; then
        echo "$d: FAILED"
        echo " ** Failed command: $c"
        cat $tdata/log
        exit 1
    fi
    echo "$d: OK"
done

rm -rf $tdata
