#!/bin/sh

cd "$(dirname "$(readlink -f "$0" || realpath "$0")")"

jplatform="${jplatform:=linux}"
j64x="${j64x:=j64}"

# gcc 5 vs 4 - killing off linux asm routines (overflow detection)
# new fast code uses builtins not available in gcc 4
# use -DC_NOMULTINTRINSIC to continue to use more standard c in version 4
# too early to move main linux release package to gcc 5

macmin="-mmacosx-version-min=10.6"

if [ "x$CC" = x'' ] ; then
if [ -f "/usr/bin/cc" ]; then
CC=cc
else
if [ -f "/usr/bin/clang" ]; then
CC=clang
else
CC=gcc
fi
fi
export CC
fi
# compiler=`$CC --version | head -n 1`
compiler=`readlink -f $(command -v $CC)`
echo "CC=$CC"
echo "compiler=$compiler"

if [ -z "${compiler##*gcc*}" ]; then
# gcc
common="-fPIC -O1 -fwrapv -fno-strict-aliasing -Wextra -Wno-maybe-uninitialized -Wno-unused-parameter -Wno-sign-compare -Wno-clobbered -Wno-empty-body -Wno-unused-value -Wno-pointer-sign -Wno-parentheses"
OVER_GCC_VER6=$(echo `$CC -dumpversion | cut -f1 -d.` \>= 6 | bc)
if [ $OVER_GCC_VER6 -eq 1 ] ; then
common="$common -Wno-shift-negative-value"
else
common="$common -Wno-type-limits"
fi
# alternatively, add comment /* fall through */
OVER_GCC_VER7=$(echo `$CC -dumpversion | cut -f1 -d.` \>= 7 | bc)
if [ $OVER_GCC_VER7 -eq 1 ] ; then
common="$common -Wno-implicit-fallthrough"
fi
OVER_GCC_VER8=$(echo `$CC -dumpversion | cut -f1 -d.` \>= 8 | bc)
if [ $OVER_GCC_VER8 -eq 1 ] ; then
common="$common -Wno-cast-function-type"
fi
else
# clang 3.5 .. 5.0
common="-Werror -fPIC -O1 -fwrapv -fno-strict-aliasing -Wextra -Wno-consumed -Wno-uninitialized -Wno-unused-parameter -Wno-sign-compare -Wno-empty-body -Wno-unused-value -Wno-pointer-sign -Wno-parentheses -Wno-unsequenced -Wno-string-plus-int"
fi
darwin="-fPIC -O1 -fwrapv -fno-strict-aliasing -Wno-string-plus-int -Wno-empty-body -Wno-unsequenced -Wno-unused-value -Wno-pointer-sign -Wno-parentheses -Wno-return-type -Wno-constant-logical-operand -Wno-comment -Wno-unsequenced"

case $jplatform\_$j64x in

linux_j32)
TARGET=libjnative.so
CFLAGS="$common -m32 -I$JAVA_HOME/include -I$JAVA_HOME/include/linux "
LDFLAGS=" -shared -Wl,-soname,libjnative.so  -m32 "
;;
linux_j64)
TARGET=libjnative.so
CFLAGS="$common -I$JAVA_HOME/include -I$JAVA_HOME/include/linux "
LDFLAGS=" -shared -Wl,-soname,libjnative.so "
;;
raspberry_j32)
TARGET=libjnative.so
CFLAGS="$common -marm -march=armv6 -mfloat-abi=hard -mfpu=vfp -I$JAVA_HOME/include -I$JAVA_HOME/include/linux "
LDFLAGS=" -shared -Wl,-soname,libjnative.so "
;;
raspberry_j64)
TARGET=libjnative.so
CFLAGS="$common -march=armv8-a+crc -I$JAVA_HOME/include -I$JAVA_HOME/include/linux "
LDFLAGS=" -shared -Wl,-soname,libjnative.so "
;;
darwin_j32)
TARGET=libjnative.dylib
CFLAGS="$darwin -m32 $macmin -I$JAVA_HOME/include -I$JAVA_HOME/include/darwin "
LDFLAGS=" -m32 $macmin -dynamiclib "
;;
darwin_j64)
TARGET=libjnative.dylib
CFLAGS="$darwin $macmin -I$JAVA_HOME/include -I$JAVA_HOME/include/darwin "
LDFLAGS=" $macmin -dynamiclib "
;;
*)
echo no case for those parameters
exit
esac

echo "CFLAGS=$CFLAGS"

mkdir -p ../bin/$jplatform/$j64x
mkdir -p obj/$jplatform/$j64x/
cp makefile-jnative obj/$jplatform/$j64x/.
export CFLAGS LDFLAGS TARGET jplatform j64x
cd obj/$jplatform/$j64x/
make -f makefile-jnative
cd -