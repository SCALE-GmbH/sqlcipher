# original setting (scale)
# export CRYPTO_LIB=libtomcrypt
# export CRYPTO_LIB=libtomcrypt DEBUG_FLAGS="--enable-debug"
# export CRYPTO_LIB=openssl LDFLAGS="-lcrypto"
# export CRYPTO_LIB=openssl LDFLAGS="-lcrypto" DEBUG_FLAGS="--enable-debug"
# export TEST_OPTIONS="--disable-codec" CRYPTO_LIB=openssl LDFLAGS="-lcrypto"
# export TEST_OPTIONS="--disable-codec" CRYPTO_LIB=openssl LDFLAGS="-lcrypto" DEBUG_FLAGS="--enable-debug"
# export TESTSUITE=test/full.test TEST_OPTIONS="--disable-codec" CRYPTO_LIB=openssl LDFLAGS="-lcrypto"

unset CFLAGS
unset CRYPTO_LIB
unset DEBUG_FLAGS
unset LDFLAGS
unset LIB
unset TEST_OPTIONS

# common

CFLAGS=" -fno-strict-aliasing \
-DSQLITE_HAS_CODEC -DSQLITE_ENABLE_RTREE=1 -DSQLITE_ENABLE_COLUMN_METADATA \
-DSQLITE_ENABLE_UPDATE_DELETE_LIMIT=1 -DSQLITE_MAX_VARIABLE_NUMBER=250000 \
-DSQLITE_TEMP_STORE=2 -DSQLITE_ENABLE_API_ARMOR"

export CRYPTO_LIB=openssl
export LDFLAGS="-lcrypto"
# testing without encryption! export TEST_OPTIONS="--disable-codec"


# debug + release config

if [ "RELEASE" == "RELEASE" ] ; then
	export CFLAGS="-O2 $CFLAGS"
else
	export CFLAGS="-ggdb $CFLAGS -DSQLITE_TEST"
	export DEBUG_FLAGS="--enable-debug"
fi

echo "CFLAGS=$CFLAGS"
echo "CRYPTO_LIB=$CRYPTO_LIB"
echo "DEBUG_FLAGS=$DEBUG_FLAGS"
echo "LDFLAGS=$LDFLAGS"
echo "LIB=$LIB"
echo "TEST_OPTIONS=$TEST_OPTIONS"
