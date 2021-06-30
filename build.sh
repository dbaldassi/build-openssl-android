#!/bin/bash

# Exit on error
set -e

# Default parameters
ANDROID_API=28
OPENSSL_VERSION=1_1_1a
PARALLEL_LEVEL=4

function help {
    echo ""
    echo "Help"
    echo ""
    echo "Build openssl for android arm64,arm,x86 and x86_64"
    echo "./build.sh --ndk /path/to/ndk [-j jobs] [-a api] [-s ssl_version]"
    echo ""
    echo "Options : "
    echo ""
    echo "-n --ndk  Set the NDK root path. This is mandatory."
    echo "-s --ssl  Set the openssl version to build. (Default $OPENSSL_VERSION)"
    echo "-j --jobs Number of jobs to run in parallel during compilation (default $PARALLEL_LEVEL)"
    echo "-a --api  android target api (default API $ANDROID_API)"
    echo "-h --help Display the help"
    echo ""
}

function log_out {
    echo "--- $1 ---"
}

function log_err {
    echo "> Error : $1" 1>&2
}

# Options
SHORT=s:n:j:a:h
LONG=ssl:,ndk:,jobs:,api:,help

OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")

if [ $? != 0 ] ; then log_err "Failed to parse options...exiting." ;help; exit 1 ; fi

eval set -- "$OPTS"

NDK=
# extract options and their arguments into variables.
while true ; do
    case "$1" in
	-s | --ssl )
	    OPENSSL_VERSION=$2
	    shift 2
	    ;;
	-n | --ndk )
	    NDK=$2
	    shift 2
	    ;;
	-j | --jobs )
	    PARALLEL_LEVEL=$2
	    shift 2
	    ;;
	-a | --api )
	    ANDROID_API=$2
	    shift
	    ;;
	-h | --help )
	    help
	    exit 0
	    ;;
	-- )
	    shift
	    break
	    ;;
	*)
	    log_err "Internal error!"
	    exit 1
	    ;;
    esac
done

# Directory and log file settings
OUTPUT_DIR=$PWD/out
SRC_DIR=$PWD/openssl_src
LOG_FILE=$PWD/log.txt

# NDK config
if [ -z "$NDK" ]
then
    log_err "You must provide a path for android ndk"
    help
    exit 1
fi

export ANDROID_NDK_ROOT=$NDK
export ANDROID_NDK=$NDK
export PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$PATH

# arch for which openssl will be built
TARGET_ARCH=(android-arm android-arm64 android-x86 android-x86_64)

# First remove source if it exists
rm -rf $SRC_DIR

# Create and move to the source dir
mkdir $SRC_DIR
cd $SRC_DIR

# Split the log file in a new section
echo "################################################################################\n\n" >> $LOG_FILE

# Download openssl
log_out "Downloading OpenSSL_$OPENSSL_VERSION"
wget https://github.com/openssl/openssl/archive/refs/tags/OpenSSL_$OPENSSL_VERSION.zip >> $LOG_FILE

unzip OpenSSL_$OPENSSL_VERSION.zip >> log.txt
cd openssl-OpenSSL_$OPENSSL_VERSION

# Build and install for every arch
for arch in ${TARGET_ARCH[@]}
do
    log_out "Building for $arch"
    ./Configure $arch -D__ANDROID_API__=$ANDROID_API --prefix=$OUTPUT_DIR/$arch no-shared >> $LOG_FILE
    make -j$PARALLEL_LEVEL >> $LOG_FILE
    log_out "Intalling in $OUTPUT_DIR/$arch"
    make install >> $LOG_FILE
    make clean >> $LOG_FILE
done
