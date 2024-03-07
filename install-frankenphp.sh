# contributors:
#  - Thomas DI LUCCIO <thomas.diluccio@platform.sh>
#  - Florent HUCK <florent.huck@platform.sh>
#  - Benjamin Hirsch <mail@benjaminhirsch.net>

run() {
    # Run the compilation process.
    cd $PLATFORM_CACHE_DIR || exit 1;

    FRANKENPHP_PROJECT=$1;
    FRANKENPHP_VERSION=$2;

    FRANKENPHP_BINARY="${FRANKENPHP_PROJECT}_v$FRANKENPHP_VERSION"
    FRANKENPHP_BINARY="${FRANKENPHP_BINARY//\./_}"

    if [ ! -f "${PLATFORM_CACHE_DIR}/${FRANKENPHP_BINARY}" ]; then
        ensure_source "$FRANKENPHP_PROJECT" "$FRANKENPHP_VERSION"
        download_binary "$FRANKENPHP_PROJECT" "$FRANKENPHP_VERSION"
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

ensure_source() {
    echo "---------------------------------------------------------------------"
    echo " Ensuring that the $FRANKENPHP_PROJECT binary folder is available and up to date "
    echo "---------------------------------------------------------------------"

    FRANKENPHP_PROJECT=$1;
    FRANKENPHP_VERSION=$2;

    mkdir -p "$PLATFORM_CACHE_DIR/$FRANKENPHP_PROJECT/$FRANKENPHP_VERSION"
    cd "$PLATFORM_CACHE_DIR/$FRANKENPHP_PROJECT/$FRANKENPHP_VERSION" || exit 1;
}

download_binary() {
    echo "---------------------------------------------------------------------"
    echo " Downloading FRANKENPHP_PROJECT binary source code "
    echo "---------------------------------------------------------------------"

    FRANKENPHP_PROJECT=$1;
    FRANKENPHP_VERSION=$2;

    pwd
    wget https://github.com/dunglas/frankenphp/releases/download/$FRANKENPHP_VERSION/frankenphp-linux-x86_64

    ls -la

    mv frankenphp-linux-x86_64 ${FRANKENPHP_PROJECT}

}

move_binary() {
    echo "---------------------------------------"
    echo " Moving and caching ${FRANKENPHP_PROJECT} binary "
    echo "---------------------------------------"

    FRANKENPHP_PROJECT=$1;
    FRANKENPHP_BINARY=$2;

    cp "${PLATFORM_CACHE_DIR}/${FRANKENPHP_PROJECT}/${FRANKENPHP_VERSION}/${FRANKENPHP_PROJECT}" "${PLATFORM_CACHE_DIR}/${FRANKENPHP_BINARY}"
}

ensure_environment() {
    # If not running in an Upsun build environment, do nothing.
    if [ -z "${PLATFORM_CACHE_DIR}" ]; then
        echo "Not running in an Upsun build environment.  Aborting FrankenPHP installation."
        exit 0;
    fi
}

ensure_arguments() {
    # If no version was specified, don't try to guess.
    if [ -z $1 ]; then
        echo "No version of the FrankenPHP is specified. You must specify a tagged version on the command line."
        exit 1;
    fi
}

ensure_environment
ensure_arguments "$1"

run "frankenphp" "$1"