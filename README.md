# GCC toolchain for the Motorola 68000

This is a set of bash scripts for build gcc toolchain on unix environment for the Motorola 68000 family (m68k) was mainly used in **SEGA Mega Drive**, **SEGA Mega CD**, **SNK NeoGeo**, **Atari ST**, **Amiga** and older computers.

## Build the toolchain

First, you need to install devel environment was come with your Linux distro for build the toolchain. 

**ArchLinux**
```bash
$ sudo pacman -Syu
$ sudo pacman -S base-devel
```

**Debian**
```bash
$ sudo apt update
$ sudo apt install build-essential texinfo
```

**Ubuntu**
```bash
$ sudo apt update
$ sudo apt install build-essential texinfo
```

**Fedora**
```bash
$ sudo dnf update
$ sudo dnf groupinstall "Development Tools"
$ sudo dnf groupinstall "C Development Tools and Libraries"
```

After, going into your workspace where you want build the toolchain (for example ~/workspace/source) and clone this repository:

```bash
cd ~/workspace/source
git clone https://github.com/kentosama/m68k-elf-gcc.git
cd m68k-elf-gcc
```
Now, you can run **build-toolchain.sh** for start the build. The process should take approximately 15 min or several hours depending on your computer. **Please, don't run this script as root!**

```bash
$ ./build-toolchain.sh
```

For build the toolchain with the newlib, use `--with-newlib` argument:

```bash
$ ./build-toolchain.sh --with-newlib
```

For build the toolchain with other processors of the Motrola 68000 family, use `--with-cpu` argument:

```bash
$ ./build-toolchain.sh --with-cpu=68000,68030...
```

For change the program prefix, use `--program-prefix` argument:

```bash
$ ./build-toolchain.sh --program-prefix=sega-genesis-
```

By default the script currently builds

binutils 	2.39
gcc			12.2.0
newlib		4.2.0.20211231
picolibc 	1.7.9

For building the toolchain with different versions of newlib, picolibc, gcc and binutils specify e.g.:

```bash
$ BINUTILS_VERSION=2.25.1  GCC_VERSION=5.2.0 NEWLIB_VERSION=2.2.0.20151023 PICOLIBC_VERSION=1.7.9 ./build-toolchain.sh --with-newlib --with-picolibc --with-cpu=68000,68060
```

For the SHA checksum verification not to fail you also need to specify the binarys SHA sums with

BINUTILS_SHA512SUM, GCC_SHA512SUM, NEWLIB_SHA256SUM and PICOLIBC_SHA256SUM,

or specify to ignore the checksums with CHECKSUM_IGNORE=TRUE

```bash
$ BINUTILS_VERSION=2.25.1  GCC_VERSION=5.2.0 NEWLIB_VERSION=2.2.0.20151023 PICOLIBC_VERSION=1.7.9 CHECKSUM_IGNORE=TRUE ./build-toolchain.sh --with-newlib --with-picolibc --with-cpu=68000,68060
```

Pathes to be applied to binutils, gcc, newlib or picolibc an be specified with

BINUTILS_APPLY_PATCH, GCC_APPLY_PATCH, NEWLIB_APPLY_PATCH and PICOLIBC_PATCH

The patch specified here is searched for in the patch subdirectory.

E.g. to build gcc 5.2.0 with a gcc 6.3.0 the patch to apply is gcc5.2.0_libc_name_p.patch.
Building gcc 5.2.0 with gcc 12.2.0 still fails and needs more patches.

```bash
$ BINUTILS_VERSION=2.25.1  GCC_VERSION=5.2.0 GCC_APPLY_PATCH=gcc6.4_to_gcc5.2.0.patch NEWLIB_VERSION=2.2.0.20151023 CHECKSUM_IGNORE=TRUE ./build-toolchain.sh --with-newlib --with-cpu=68000,68060
```

Building gcc 5.2.0 with gcc 12.2.0 still fails and needs more changes to the gcc 5.2 sources.
There is another patch provided wich allows building gcc 5.2 with a current gcc 12.2.
This patch fixes:

* libc_name_p definition
* multiple template definitions in wide-int.h 
* x_spill_indirect_levels boolean increment which does no longer work with stdc++17 and breaks compiling whith a recent gcc


```bash
$ BINUTILS_VERSION=2.25.1  GCC_VERSION=5.2.0 GCC_APPLY_PATCH=gcc12.2_to_gcc5.2.0.patch NEWLIB_VERSION=2.2.0.20151023 CHECKSUM_IGNORE=TRUE ./build-toolchain.sh --with-newlib --with-cpu=68000,68060
```

The version of this script originally forked from https://github.com/kentosama/m68k-elf-gcc which build gcc 6.3.0 can be run with:

```bash
$ BINUTILS_VERSION=2.34 GCC_VERSION=6.3.0 GCC_APPLY_PATCH=ubsan-fix-check-empty-string.patch NEWLIB_VERSION=3.3.0 CHECKSUM_IGNORE=TRUE ./build-toolchain.sh --with-newlib --with-cpu=68000,68060
```

The file target_versions.txt lists versions of utils and patches which have been successfully tested.

## Install

Once the Motorola 68000 toolchain was successful built, you can process to the installation. Move or copy the "m68k-toolchain" folder in "/opt" or "/usr/local":

```bash
$ sudo cp -R m68k-toolchain /opt
```

If you want, add the Motorola 68000 toolchain to your path environment:

```bash
$ echo export PATH="${PATH}:/opt/m68k-toolchain/bin" >> ~/.bashrc
$ source ~/.bash_profile
```

Finally, check that m68k-elf-gcc is working properly:

```bash
$ m68k-elf-gcc -v
```

The result should display something like this:

```bash
Using built-in specs.
COLLECT_GCC=./m68k-elf-gcc
COLLECT_LTO_WRAPPER=/home/kentosama/Workspace/m68-elf-gcc/m68k-toolchain/libexec/gcc/m68k-elf/6.3.0/lto-wrapper
Target: m68k-elf
Configured with: ../../source/gcc-6.3.0/configure --prefix=/home/kentosama/Workspace/m68-elf-gcc/m68k-toolchain --build=x86_64-pc-linux-gnu --host=x86_64-pc-linux-gnu --target=m68k-elf --program-prefix=m68k-elf- --enable-languages=c --enable-obsolete --enable-lto --disable-threads --disable-libmudflap --disable-libgomp --disable-nls --disable-werror --disable-libssp --disable-shared --disable-multilib --disable-libgcj --disable-libstdcxx --disable-gcov --without-headers --without-included-gettext --with-cpu=m68000
Thread model: single
gcc version 6.3.0 (GCC) 
```

For backup, you can store the Motorola 68000 toolchain in external drive:
```bash
$ tar -Jcvf sh2-gcc-6.3.0-toolchain.tar.xz m68k-toolchain
$ mv m68k-gcc-6.3.0-toolchain.tar.xz /storage/toolchains/
```
