#!/bin/bash

###################################################################
#Script Name	:   build-picolib                                                                                            
#Description	:   build picolib for the Motorola 68000 toolchain   
#Date           :   2022-10-31                                                                          
#Args           :   TODO                                                                                        
#Author       	:   5inf                                                   
###################################################################

PICOLIBC_VERSION=${PICOLIBC_VERSION:-"1.7.9"}
PICOLIBC_ARCHIVE="picolibc-${VERSION}.tar.xz"
PICOLIBC_URL="https://keithp.com/picolibc/dist/${ARCHIVE}"
PICOLIBC_SHA256SUM=${PICOLIBC_SHA256SUM:-"4b0042344fe7be61adf44ae098f94e21a90ac5179152b3a5ea779451c8e914ab"}
PICOLIBC_DIR="picolib-${VERSION}"


####added temporarily, done by build-toolchain
# Export
export ARCH=$(uname -m)
export TARGET="m68k-elf"
export BUILD_MACH="${ARCH}-pc-linux-gnu"
export HOST_MACH="${ARCH}-pc-linux-gnu"
export NUM_PROC=$(nproc)
export PROGRAM_PREFIX=${PREFIX}
export INSTALL_DIR="${PWD}/m68k-toolchain"
export DOWNLOAD_DIR="${PWD}/download"
export ROOT_DIR="${PWD}"
export BUILD_DIR="${ROOT_DIR}/build"
export SRC_DIR="${ROOT_DIR}/source"
export WITH_CPU=${CPU}


# Check if user is root
if [ ${EUID} == 0 ]; then
    echo "Please don't run this script as root"
    exit
fi

# Create build folder
mkdir ${BUILD_DIR}/${PICOLIBC_DIR}

# Move into download folder
cd ${DOWNLOAD_DIR}

# Download picolib if is needed
if ! [ -f "${PICOLIBC_ARCHIVE}" ]; then
    wget ${PICOLIBC_URL}
fi

# Extract the newlib archive if is needed
if ! [ -d "${SRC_DIR}/${DIR}" ]; then
    if [ $(sha256sum ${PICOLIBC_ARCHIVE} | awk '{print $1}') != ${PICOLIBC_SHA256SUM} ] && ![ ${CHECKSUM_IGNORE} ]; then
        echo "SHA256SUM verification of ${ARCHIVE} failed!"
        exit 1
    else
        tar -xvf ${PICOLIBC_ARCHIVE} -C ${SRC_DIR}
		if [ -v PICOLIBC_APPLY_PATCH ] && [ -f ${ROOT_DIR}/patch/${PICOLIBC_APPLY_PATCH} ]; then
		    echo "Applying patch ${PICOLIBC_APPLY_PATCH}"
			patch -p0 -d ${SRC_DIR}/${PICOLIBC_DIR}/ < ${ROOT_DIR}/patch/${PICOLIBC_APPLY_PATCH}
			if [ $? -ne 0 ]; then
				"Failed to apply patch to picolibc, please check build.log"
				exit 1
			fi
		fi
    fi
fi

# Export
PREFIX=${PROGRAM_PREFIX}
export CC_FOR_TARGET=${PREFIX}gcc
export LD_FOR_TARGET=${PREFIX}ld
export AS_FOR_TARGET=${PREFIX}as
export AR_FOR_TARGET=${PREFIX}ar
export RANLIB_FOR_TARGET=${PREFIX}ranlib
export newlib_cflags="${newlib_cflags} -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__"

# Move into build dir
cd ${BUILD_DIR}/${PICOLIBC_DIR}


###below is not up to date yet! Thus we exit.

exit

#https://github.com/picolibc/picolibc
#
#sudo apt-get install meson
#sudo apt-get install ninja-build
#mkdir picolibc-build
#cd picolibc-build/
#git clone https://github.com/picolibc/picolibc.git
#cd picolibc/
#mkdir build-m68k-elf
#cd build-m68k-elf
#
#cd ../scripts/
#cp scripts/cross-m68k-linux-gnu.txt ./cross-m68k-elf.txt
#cp do-m68k-configure do-m68k-elf-configure
#
#Change the compiler prefixes
#
#Wir brauchen einen GCC, der C18 versteht um picolibc zu bauen! Unser GCC (hier version 6.3 aus 2016, https://gcc.gnu.org/releases.html) kann aber nur c11.
#
#Watch for endianness
#
#exec "$(dirname "$0")"/do-configure m68k-elf -Dtests=true -Dfake-semihost=true "$@"
#exec "$(dirname "$0")"/do-configure m68k-elf -Dtests=true -Dfake-semihost=true "$@"
#
#../scripts/do-m68k-elf-configure -Dprefix=/home/holger/work/picolibc-build/install
#
#ninja
#ninja install


# Configure before build
../../source/${PICOLIBC_DIR}/configure   --prefix=${INSTALL_DIR} \
                                --build=${BUILD_MACH} \
                                --host=${HOST_MACH} \
                                --target=${TARGET} \
                                --program-prefix=${PREFIX} \
                                --disable-newlib-multithread \
                                --disable-newlib-io-float \
                                --enable-lite-exit \
                                --disable-newlib-supplied-syscalls \

# Build and install newlib
make -j${NUM_PROC} 2<&1 | tee build.log

# Install newlib
if [ $? -eq 0 ]; then
    make install
fi
