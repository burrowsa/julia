#!/bin/sh
# script to build Julia in Cygwin assuming the following packages are installed
# - make
# - mingw64-x86_64-gcc-g++ (for 64 bit)
# - mingw64-x86_64-gcc-fortran (for 64 bit)
# - mingw-gcc-g++ (for 32 bit)
# - mingw-gcc-fortran (for 32 bit)
# - dos2unix

dos2unix contrib/relative_path.sh

if [ `arch` = x86_64 ]; then
  XC_HOST=x86_64-w64-mingw32 make
else
  XC_HOST=i686-pc-mingw32 make
fi
