#!/bin/bash

###################################################################
#Script Name	:   build-newlib                                                                                            
#Description	:   build newlib for the Motorola 68000 toolchain   
#Date           :   samedi, 7 avril 2020                                                                          
#Args           :   Welcome to the next level!                                                                                        
#Author       	:   Jacques Belosoukinski (kentosama)                                                   
#Email         	:   kentosama@genku.net                                          
###################################################################

NEWLIB_VERSION=${NEWLIB_VERSION:-"4.2.0.20211231"} #set default if not set
NEWLIB_ARCHIVE="newlib-${NEWLIB_VERSION}.tar.gz"
NEWLIB_URL="ftp://sourceware.org/pub/newlib/${NEWLIB_ARCHIVE}"
NEWLIB_SHA512SUM=${NEWLIB_SHA512SUM:-"2f0c6666487520e1a0af0b6935431f85d2359e27ded0d01d02567d0d1c6479f2f0e6bbc60405e88e46b92c2a18780a01a60fc9281f7e311cfd40b8d5881d629c"}
NEWLIB_DIR="newlib-${NEWLIB_VERSION}"

# Check if user is root
if [ ${EUID} == 0 ]; then
    echo "Please don't run this script as root"
    exit
fi

# Create build folder
mkdir ${BUILD_DIR}/${NEWLIB_DIR}

# Move into download folder
cd ${DOWNLOAD_DIR}

# Download newlib if is needed
if ! [ -f "${ARCHIVE}" ]; then
    wget ${NEWLIB_URL}
fi

# Extract the newlib archive if is needed
if ! [ -d "${SRC_DIR}/${DIR}" ]; then
    if [ $(sha512sum ${ARCHIVE} | awk '{print $1}') != ${NEWLIB_SHA512SUM} ] && ![ ${CHECKSUM_IGNORE} ]; then
        echo "SHA512SUM verification of ${ARCHIVE} failed!"
        exit 1
    else
        tar -zxvf ${NEWLIB_ARCHIVE} -C ${SRC_DIR}
		if [ -v NEWLIB_APPLY_PATCH ] && [ -f ${ROOT_DIR}/patch/${NEWLIB_APPLY_PATCH} ]; then
		    echo "Applying patch ${NEWLIB_APPLY_PATCH}"
			patch -t ${SRC_DIR}/${NEWLIB_DIR}/ < ${ROOT_DIR}/patch/${NEWLIB_APPLY_PATCH}
			if [ $? -ne 0 ]; then
				"Failed to apply patch to newlib, please check build.log"
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
cd ${BUILD_DIR}/${NEWLIB_DIR}

# Configure before build
../../source/${NEWLIB_DIR}/configure   --prefix=${INSTALL_DIR} \
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
