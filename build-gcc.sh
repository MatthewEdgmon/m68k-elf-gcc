#!/bin/bash

###################################################################
#Script Name    :   build-gcc
#Description    :   build gcc for the Motorola 68000 toolchain
#Date           :   Monday, 11 November 2022
#Author         :   5inf, Jacques Belosoukinski (kentosama)
##################################################################

GCC_VERSION=${GCC_VERSION:-"12.2.0"}
GCC_ARCHIVE="gcc-${GCC_VERSION}.tar.gz"
GCC_URL="https://gcc.gnu.org/pub/gcc/releases/gcc-${GCC_VERSION}/${GCC_ARCHIVE}"
GCC_SHA512SUM=${GCC_SHA512SUM:-"36ab2267540f205b148037763b3806558e796d564ca7831799c88abcf03393c6dc2cdc9d53e8f094f6dc1245e47a406e1782604eb9d119410d406032f59c1544"}
GCC_DIR="gcc-${GCC_VERSION}"

# Check if user is root
if [ ${EUID} == 0 ]; then
    echo "Please don't run this script as root"
    exit
fi

# Create build folder
mkdir -p ${BUILD_DIR}/${GCC_DIR}

cd ${DOWNLOAD_DIR}

# Download gcc if is needed
if ! [ -f "${GCC_ARCHIVE}" ]; then
    wget ${GCC_URL}
fi

# Extract gcc archive if is needed
if ! [ -d "${SRC_DIR}/${GCC_DIR}" ]; then
    if [ $(sha512sum ${GCC_ARCHIVE} | awk '{print $1}') != ${GCC_SHA512SUM} ] && ![ ${CHECKSUM_IGNORE} ]; then
        echo "SHA512SUM verification of ${GCC_ARCHIVE} failed!"
        exit 1
    else
        tar xvf ${GCC_ARCHIVE} -C ${SRC_DIR}
		echo "Checking for patch to apply ${GCC_APPLY_PATCH}"
		if [ -v GCC_APPLY_PATCH ] && [ -f ${ROOT_DIR}/patch/${GCC_APPLY_PATCH} ]; then
		    echo "Applying patch ${GCC_APPLY_PATCH}"
			patch -t --forward -p0 -d ${SRC_DIR}/${GCC_DIR}/  < ${ROOT_DIR}/patch/${GCC_APPLY_PATCH}
			if [ $? -ne 0 ]; then
				"Failed to apply patch to gcc, please check build.log"
				exit 1
			fi
                elif [ -v GCC_APPLY_PATCH ]; then
                        echo "patch specified but patch file not found"
			exit 1
		fi
    fi
fi



cd ${SRC_DIR}/${GCC_DIR}

echo ${PWD}

# Download prerequisites
./contrib/download_prerequisites

cd ${BUILD_DIR}/${GCC_DIR}

# Configure before build
../../source/${GCC_DIR}/configure   --prefix=${INSTALL_DIR}             \
                                --build=${BUILD_MACH}               \
                                --host=${HOST_MACH}                 \
                                --target=${TARGET}                  \
                                --program-prefix=${PROGRAM_PREFIX}  \
                                --enable-languages=c,c++            \
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
