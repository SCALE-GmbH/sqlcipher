#!/usr/bin/env bash
set -eo pipefail

## go to base dir of sqlcipher, not to this subdir!
#cd $(dirname `readlink -f "$0"`)/..

source ./scale/scale_include.sh

echo -e '\nbuild'
./configure --verbose --enable-tempstore=yes --with-crypto-lib=$CRYPTO_LIB $DEBUG_FLAGS CFLAGS="$CFLAGS"
make clean
make -j3 all
