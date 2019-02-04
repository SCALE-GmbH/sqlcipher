# original setting (scale)
# export CRYPTO_LIB=libtomcrypt
# export CRYPTO_LIB=libtomcrypt DEBUG_FLAGS="--enable-debug"
# export CRYPTO_LIB=openssl LDFLAGS="-lcrypto"
# export CRYPTO_LIB=openssl LDFLAGS="-lcrypto" DEBUG_FLAGS="--enable-debug"
# export TEST_OPTIONS="--disable-codec" CRYPTO_LIB=openssl LDFLAGS="-lcrypto"
# export TEST_OPTIONS="--disable-codec" CRYPTO_LIB=openssl LDFLAGS="-lcrypto" DEBUG_FLAGS="--enable-debug"
# export TESTSUITE=test/full.test TEST_OPTIONS="--disable-codec" CRYPTO_LIB=openssl LDFLAGS="-lcrypto"

unset CFLAGS
unset CXXFLAGS
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

TMP_CONFIG_MODE="ASAN"
if [ "$TMP_CONFIG_MODE" == "DEBUG" ] ; then
	export CFLAGS="-ggdb $CFLAGS"
	export DEBUG_FLAGS="--enable-debug"

elif [ "$TMP_CONFIG_MODE" == "ASAN" ] ; then
	export ASAN_OPTIONS=detect_leaks=0

	ASAN_FLAGS="-O2 -fsanitize=address -fno-omit-frame-pointer"
	export CFLAGS="-ggdb $ASAN_FLAGS $CFLAGS"
	export CXXFLAGS="$ASAN_FLAGS $CXXFLAGS"
	#export DEBUG_FLAGS="--enable-debug"
	export LDFLAGS="-fsanitize=address -static-libasan $LDFLAGS"

	unset ASAN_FLAGS

else  # default: RELEASE
	export CFLAGS="-O2 $CFLAGS"
fi
unset TMP_CONFIG_MODE


echo "CFLAGS=$CFLAGS"
echo "CXXFLAGS=$CXXFLAGS"
echo "CRYPTO_LIB=$CRYPTO_LIB"
echo "DEBUG_FLAGS=$DEBUG_FLAGS"
echo "LDFLAGS=$LDFLAGS"
echo "LIB=$LIB"
echo "TEST_OPTIONS=$TEST_OPTIONS"
echo "ASAN_OPTIONS=$ASAN_OPTIONS"
