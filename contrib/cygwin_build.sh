#!/bin/sh
# Script to cross-compile Julia from Cygwin to MinGW assuming the following packages are installed:
# - dos2unix
# - make
# - wget
# - mingw64-x86_64-gcc-g++ (for 64 bit)
# - mingw64-x86_64-gcc-fortran (for 64 bit)
# - mingw-gcc-g++ (for 32 bit)
# - mingw-gcc-fortran (for 32 bit)
#
# This script is intended to be executed from the base julia directory as contrib/cygwin_build.sh

# stop on error
set -e

if [ -n "$APPVEYOR" ]; then
  git config core.eol
  git config --global core.eol
  git config --global core.eol lf
fi
dos2unix contrib/relative_path.sh deps/jldownload

if [ `arch` = x86_64 ]; then
  XC_HOST=x86_64-w64-mingw32 make
else
  XC_HOST=i686-pc-mingw32 make
fi
