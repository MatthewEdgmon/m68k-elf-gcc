#!/bin/bash

###################################################################
#Script Name	:   build-binutils                                                                                            
#Description	:   build binutils for the Motorola 68000 toolchain   
#Date           :   samedi, 4 avril 2020                                                                          
#Args           :   Welcome to the next level!                                                                                        
#Author       	:   Jacques Belosoukinski (kentosama)                                                   
#Email         	:   kentosama@genku.net                                          
###################################################################

BINUTILS_VERSION=${BINUTILS_VERSION:-"2.39"}
BINUTILS_ARCHIVE="binutils-${BINUTILS_VERSION}.tar.bz2"
BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/${BINUTILS_ARCHIVE}"
BINUTILS_SHA512SUM=${BINUTILS_SHA512SUM:-"faa592dd48fc715901ad704ac96dbd34b1792c51e77c7a92a387964b0700703c74be07de45cc4751945c8c0674368c73dc17bbc563d1d2cd235b5ebd8c6e7efb"}
BINUTILS_DIR="binutils-${BINUTILS_VERSION}"

# Check if user is root
if [ ${EUID} == 0 ]; then
    echo "Please don't run this script as root"
    exit 1
fi

echo "BUILDING: ${BINUTILS_VERSION}"

# Create build folder
mkdir -p ${BUILD_DIR}/${BINUTILS_DIR}

cd ${DOWNLOAD_DIR}

# Download binutils if is needed
if ! [ -f "${BINUTILS_ARCHIVE}" ]; then
    wget ${BINUTILS_URL}
fi

# Extract binutils archive if is needed
if ! [ -d "${SRC_DIR}/${BINUTILS_DIR}" ]; then
    if [ $(sha512sum ${BINUTILS_ARCHIVE} | awk '{print $1}') != ${BINUTILS_SHA512SUM} ] && ![ ${CHECKSUM_IGNORE}]; then
        echo "SHA512SUM verification of ${BINUTILS_ARCHIVE} failed!"
        exit 1
    else
        tar jxvf ${BINUTILS_ARCHIVE} -C ${SRC_DIR}
		if [ -v BINUTILS_APPLY_PATCH ] && [ -f ${ROOT_DIR}/patch/${BINUTILS_APPLY_PATCH} ]; then
		    echo "Applying patch ${BINUTILS_APPLY_PATCH}"
			patch -t --forward -p0 -d ${SRC_DIR}/${BINUTILS_DIR}/ < ${ROOT_DIR}/patch/${BINUTILS_APPLY_PATCH}
			if [ $? -ne 0 ]; then
				"Failed to apply patch to binutils, please check build.log"
				exit 1
			fi
		fi
    fi
fi

cd ${BUILD_DIR}/${BINUTILS_DIR}

# Enable gold for 64bit
if [ ${ARCH} != "i386" ] && [ ${ARCH} != "i686" ]; then
    GOLD="--enable-gold=yes"
fi

# Configure before build
../../source/${BINUTILS_DIR}/configure       --prefix=${INSTALL_DIR} \
                                    --build=${BUILD_MACH} \
                                    --host=${HOST_MACH} \
                                    --target=${TARGET} \
                                    --disable-werror \
                                    --disable-nls \
                                    --disable-threads \
                                    --disable-multilib \
                                    --enable-libssp \
                                    --enable-lto \
                                    --enable-languages=c,c++
                                    --program-prefix=${PROGRAM_PREFIX} \
                                    ${GOD}


# build and install binutils
make -j${NUM_PROC} 2<&1 | tee build.log

# Install binutils
if [ $? -eq 0 ]; then
    make install -j${NUM_PROC}
fi
