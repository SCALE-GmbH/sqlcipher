#!/usr/bin/env bash
set -eo pipefail

# constants
BUILD_DEBUG="DEBUG"
BUILD_ASAN="ASAN"
BUILD_RELEASE="RELEASE"
SCRIPT_CONFIG_INFO="possibilities: $BUILD_DEBUG, $BUILD_ASAN, $BUILD_RELEASE == empty"

# go to base dir of sqlite/sqlcipher, not to this subdir!
cd $(dirname `readlink -f "$0"`)/..

echo -e '\nconfig env'

unset ASAN_OPTIONS
unset CFLAGS
unset CRYPTO_LIB
unset CXXFLAGS
unset DEBUG_FLAGS
unset LDFLAGS
unset LIB
unset TEST_OPTIONS

# common
CFLAGS_PRECONF=" -fno-strict-aliasing \
-DSQLITE_HAS_CODEC -DSQLITE_ENABLE_RTREE=1 -DSQLITE_ENABLE_COLUMN_METADATA \
-DSQLITE_ENABLE_UPDATE_DELETE_LIMIT=1 -DSQLITE_MAX_VARIABLE_NUMBER=250000 \
-DSQLITE_TEMP_STORE=2 -DSQLITE_ENABLE_API_ARMOR"

export CRYPTO_LIB=openssl
export LDFLAGS="-lcrypto"
# testing without encryption will mostly succeed! export TEST_OPTIONS="--disable-codec"

# argument uppercase
BUILD_CONFIG=$( echo "$1" | tr '[:lower:]' '[:upper:]' )

# default is RELEASE
if [ -z "$BUILD_CONFIG" ] ; then
    BUILD_CONFIG="$BUILD_RELEASE"
fi

echo "script argument=\"$BUILD_CONFIG\" ($SCRIPT_CONFIG_INFO)"

if [ "$BUILD_CONFIG" == "$BUILD_DEBUG" ] ; then
    export CFLAGS="-ggdb $CFLAGS_PRECONF"
    export DEBUG_FLAGS="--enable-debug"

elif [ "$BUILD_CONFIG" == "$BUILD_ASAN" ] ; then
    TMP_ASAN_FLAGS="-O2 -fsanitize=address -fno-omit-frame-pointer"
    export CFLAGS="-ggdb $TMP_ASAN_FLAGS $CFLAGS_PRECONF"
    export LDFLAGS="-fsanitize=address -static-libasan $LDFLAGS_COMMON"
    unset TMP_ASAN_FLAGS

    # has to be set during testing!
    #export ASAN_OPTIONS=detect_leaks=0
    #export OMIT_MISUSE=1  # skip sqlite/sqlcipher misuse tests (search for with clang_sanitize_address)

elif [ "$BUILD_CONFIG" == "$BUILD_RELEASE" ] ; then    
    export CFLAGS="-O2 $CFLAGS_PRECONF"

else
    # error when unknown parameters
    echo -e "ERROR: wrong script argument!"
    exit 1  
fi

echo "CFLAGS=\"$CFLAGS\""
echo "CRYPTO_LIB=\"$CRYPTO_LIB\""
echo "CXXFLAGS=\"$CXXFLAGS\""
echo "DEBUG_FLAGS=\"$DEBUG_FLAGS\""
echo "LDFLAGS=\"$LDFLAGS\""
echo "LIB=\"$LIB\""
echo "TEST_OPTIONS=\"$TEST_OPTIONS\""
echo "pwd=$(pwd)"

echo -e '\nconfig build'
./configure --verbose --enable-tempstore=yes --with-crypto-lib=$CRYPTO_LIB $DEBUG_FLAGS CFLAGS="$CFLAGS"

echo -e '\nbuild'
make clean
make -j3 all
make -j3 testfixture sqldiff
