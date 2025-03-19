#!/bin/bash
set -e

HOST=$1
PREFIX=$PWD/.dist/$HOST

# Extract bit size from host name
if [[ $HOST =~ riscv32im ]]; then
  ARCH="rv32im"
  ABI="ilp32"
elif [[ $HOST =~ riscv64im ]]; then
  ARCH="rv64im"
  ABI="lp64"
else
  echo "Unknown host: $HOST"
  exit 1
fi

pushd riscv-gnu-toolchain

echo "building toolchain for host: $HOST, arch: $ARCH, abi: $ABI"
./configure --prefix=$PREFIX --with-cmodel=medany --disable-gcc-checking --disable-gdb --with-arch=$ARCH --with-abi=$ABI
make -j$(nproc 2>/dev/null || sysctl -n hw.logicalcpu)

popd

pushd .dist

tar cvJf $HOST.tar.xz $HOST

popd
