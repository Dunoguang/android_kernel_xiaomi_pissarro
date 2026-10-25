#!/bin/bash
# pissarro 4.14 + BakaSU + SUSFS v2.3.0 构建脚本
# 用法: ./build-bakasu.sh            默认用 proton-clang
#       USE_SYSTEM_CLANG=1 ./build-bakasu.sh   用系统 clang 22 + GNU ld
set -e
cd "$(dirname "$0")"

PROXY=${PROXY:-http://127.0.0.1:7890}
export https_proxy=$PROXY http_proxy=$PROXY
export LC_ALL=C
export ARCH=arm64
export KBUILD_BUILD_HOST=pissarro
export KBUILD_BUILD_USER=dunoguang

OUT=${OUT:-out-bakasu}
JOBS=${JOBS:-$(nproc)}
CROSS=${CROSS:-aarch64-linux-gnu-}

command -v "${CROSS}gcc" >/dev/null || { echo "缺少 ${CROSS}gcc，请先装 aarch64 交叉 gcc"; exit 1; }

if [ "${USE_SYSTEM_CLANG:-0}" = "1" ]; then
    TOOL=(CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=$CROSS
          LD=${CROSS}ld AS=${CROSS}as AR=${CROSS}ar NM=${CROSS}nm
          OBJCOPY=${CROSS}objcopy OBJDUMP=${CROSS}objdump STRIP=${CROSS}strip)
else
    [ -d clang/bin ] || git clone --depth=1 https://github.com/kdrag0n/proton-clang clang
    export PATH="$PWD/clang/bin:$PATH"
    TOOL=(CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=$CROSS
          LD=ld.lld AS=llvm-as AR=llvm-ar NM=llvm-nm
          OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip)
fi

ARGS=(O=$OUT ARCH=arm64 "${TOOL[@]}"
      KCFLAGS="-Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -Wno-error=int-conversion"
      CONFIG_SECTION_MISMATCH_WARN_ONLY=y)

make "${ARGS[@]}" pissarro_user_defconfig
make -j"$JOBS" "${ARGS[@]}"

echo "=== 产物 ==="
ls -l "$OUT/arch/arm64/boot/" 2>/dev/null || true
