#!/bin/bash

###################################################################
#Script Name	:   build-gcc                                                                                           
#Description	:   build gcc for the Motorola 68000 toolchain   
#Date           :   samedi, 4 avril 2020                                                                          
#Args           :   Welcome to the next level!                                                                                        
#Author       	:   Jacques Belosoukinski (kentosama)                                                   
#Email         	:   kentosama@genku.net                                          
##################################################################

VERSION="12.2.0"
ARCHIVE="gcc-${VERSION}.tar.gz"
URL="https://gcc.gnu.org/pub/gcc/releases/gcc-${VERSION}/${ARCHIVE}"
SHA512SUM="36ab2267540f205b148037763b3806558e796d564ca7831799c88abcf03393c6dc2cdc9d53e8f094f6dc1245e47a406e1782604eb9d119410d406032f59c1544"
DIR="gcc-${VERSION}"

# Check if user is root
if [ ${EUID} == 0 ]; then
    echo "Please don't run this script as root"
    exit
fi

# Create build folder
mkdir -p ${BUILD_DIR}/${DIR}

cd ${DOWNLOAD_DIR}

# Download gcc if is needed
if ! [ -f "${ARCHIVE}" ]; then
    wget ${URL}
fi

# Extract gcc archive if is needed
if ! [ -d "${SRC_DIR}/${DIR}" ]; then
    if [ $(sha512sum ${ARCHIVE} | awk '{print $1}') != ${SHA512SUM} ]; then
        echo "SHA512SUM verification of ${ARCHIVE} failed!"
        exit
    else
        tar xvf ${ARCHIVE} -C ${SRC_DIR}
    fi
fi

cd ${SRC_DIR}/${DIR}

echo ${PWD}

# Download prerequisites
./contrib/download_prerequisites

cd ${BUILD_DIR}/${DIR}

# Configure before build
../../source/${DIR}/configure   --prefix=${INSTALL_DIR}             \
                                --build=${BUILD_MACH}               \
                                --host=${HOST_MACH}                 \
                                --target=${TARGET}                  \
                                --program-prefix=${PROGRAM_PREFIX}  \
                                --enable-languages=c                \
                                --enable-obsolete                   \
                                --enable-lto                        \
                                --disable-threads                   \
                                --disable-libmudflap                \
                                --disable-libgomp                   \
                                --disable-nls                       \
                                --disable-werror                    \
                                --disable-libssp                    \
                                --disable-shared                    \
                                --disable-multilib                  \
                                --disable-libgcj                    \
                                --disable-libstdcxx                 \
                                --disable-gcov                      \
                                --without-headers                   \
                                --without-included-gettext          \
                                --with-cpu=${WITH_CPU}              \
                                ${WITH_NEWLIB}                      


# build and install gcc
make -j${NUM_PROC} 2<&1 | tee build.log

# Install
if [ $? -eq 0 ]; then
    make install
    make -j${NUM_PROC} all-target-libgcc
    make install-target-libgcc
fi


