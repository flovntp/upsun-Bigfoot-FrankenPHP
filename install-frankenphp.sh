# contributors:
#  - Thomas DI LUCCIO <thomas.diluccio@platform.sh>
#  - Florent HUCK <florent.huck@platform.sh>
#  - Benjamin Hirsch <mail@benjaminhirsch.net>

run() {
    # Run the compilation process.
    cd $PLATFORM_CACHE_DIR || exit 1;

    FRANKENPHP_PROJECT=$1;
    FRANKENPHP_VERSION=$2;

    FRANKENPHP_BINARY="${FRANKENPHP_PROJECT}_v$2"
    FRANKENPHP_BINARY="${FRANKENPHP_BINARY//\./_}"

    if [ ! -f "${PLATFORM_CACHE_DIR}/${FRANKENPHP_BINARY}" ]; then
        ensure_source "$FRANKENPHP_PROJECT" "$FRANKENPHP_VERSION"
        #compile_source "$FRANKENPHP_PROJECT"
        move_binary "$FRANKENPHP_PROJECT" "$FRANKENPHP_BINARY"
    fi

    copy_lib "$FRANKENPHP_PROJECT" "$FRANKENPHP_BINARY"
}

copy_lib() {
    echo "------------------------------------------------"
    echo " Copying compiled extension to PLATFORM_APP_DIR "
    echo "------------------------------------------------"

    FRANKENPHP_PROJECT=$1;
    FRANKENPHP_BINARY=$2;

    cp "${PLATFORM_CACHE_DIR}/${FRANKENPHP_BINARY}" "${PLATFORM_APP_DIR}/${FRANKENPHP_PROJECT}"
}

enable_lib() {
    echo "-------------------------------"
    echo " Enabling extension in php.ini "
    echo "-------------------------------"

    FRANKENPHP_PROJECT=$1;

    echo "extension=${PLATFORM_APP_DIR}/${FRANKENPHP_PROJECT}" >> $PLATFORM_APP_DIR/php.ini
}

move_extension() {
    echo "---------------------------------------"
    echo " Moving and caching compiled extension "
    echo "---------------------------------------"

    FRANKENPHP_PROJECT=$1;
    FRANKENPHP_BINARY=$2;

    mv "${PLATFORM_CACHE_DIR}/${FRANKENPHP_PROJECT}/frankenphp-src/${FRANKENPHP_PROJECT}" "${PLATFORM_CACHE_DIR}/${FRANKENPHP_BINARY}"
}

ensure_source() {
    echo "---------------------------------------------------------------------"
    echo " Ensuring that the extension source code is available and up to date "
    echo "---------------------------------------------------------------------"

    FRANKENPHP_PROJECT=$1;
    FRANKENPHP_VERSION=$2;

    mkdir -p "$PLATFORM_CACHE_DIR/$FRANKENPHP_PROJECT"
    cd "$PLATFORM_CACHE_DIR/$FRANKENPHP_PROJECT" || exit 1;

    if [ -d "frankenphp-src" ]; then
        cd frankenphp-src || exit 1;
    else
        wget https://github.com/dunglas/frankenphp/releases/download/$FRANKENPHP_VERSION/frankenphp-linux-x86_64
        mv frankenphp-linux-x86_64 frankenphp
        chmod +x frankenphp
    fi
}

compile_source() {

    FRANKENPHP_PROJECT=$1;

    echo "--------------------"
    echo " Compiling valgrind "
    echo "--------------------"

    ./autogen.sh
    ./configure --prefix="$PLATFORM_CACHE_DIR/$FRANKENPHP_PROJECT/swoole-src"
    make
    make install

    echo "---------------------"
    echo " Compiling extension "
    echo "---------------------"

    cd ..
    phpize
    ./configure --enable-openssl \
                --enable-mysqlnd \
                --enable-sockets \
                --enable-http2 \
                --with-postgres
    make




}

ensure_environment() {
    # If not running in a Platform.sh build environment, do nothing.
    if [ -z "${PLATFORM_CACHE_DIR}" ]; then
        echo "Not running in a Platform.sh build environment.  Aborting Open Swoole installation."
        exit 0;
    fi
}

ensure_arguments() {
    # If no Swoole repository was specified, don't try to guess.
    if [ -z $1 ]; then
        echo "No version of the Swoole project specified. (swoole/openswoole)."
        exit 1;
    fi

    if [[ ! "$1" =~ ^(swoole|openswoole)$ ]]; then
        echo "The requested Swoole project is not supported: ${1} Aborting.\n"
        exit 1;
    fi

    # If no version was specified, don't try to guess.
    if [ -z $2 ]; then
        echo "No version of the ${1} extension specified.  You must specify a tagged version on the command line."
        exit 1;
    fi
}


ensure_environment
ensure_arguments "$1" "$2"

FRANKENPHP_PROJECT=$1;
FRANKENPHP_VERSION=$(sed "s/^[=v]*//i" <<< "$2" | tr '[:upper:]' '[:lower:]')

run "$FRANKENPHP_PROJECT" "$FRANKENPHP_VERSION"