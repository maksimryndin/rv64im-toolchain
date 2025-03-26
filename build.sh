#!/bin/bash
set -e

if [ "$(uname -s)" = "Darwin" ]; then
	MOUNT_POINT="/Volumes/RISCVToolchain"
	WORK_DIR="$MOUNT_POINT/workdir"

	hdiutil create -size 8g -fs "Case-sensitive APFS" -volname RISCVToolchain -type SPARSE ~/RISCVToolchain.sparseimage
	hdiutil attach ~/RISCVToolchain.sparseimage

	mkdir -p "$WORK_DIR"
	cd "$WORK_DIR"
else
    WORK_DIR="$(pwd)/workdir"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
fi

HOST=$1
PREFIX=$WORK_DIR/.dist/$HOST

# Extract bit size from host name
if [[ $HOST =~ riscv32im ]]; then
  ARCH="rv32im"
  ABI="ilp32"
elif [[ $HOST =~ riscv64ima ]]; then
  ARCH="rv64ima"
  ABI="lp64"
else
  echo "Unknown host: $HOST"
  exit 1
fi

if command -v gsed &>/dev/null; then
  SED=gsed
else
  SED=sed
fi

# set up the gnu toolchain
git clone https://github.com/riscv-collab/riscv-gnu-toolchain
cd riscv-gnu-toolchain

# Use $SED with appropriate syntax based on whether it's BSD sed on macOS
if [ "$SED" = "sed" ] && [ "$(uname -s)" = "Darwin" ]; then
    # BSD sed on macOS requires an empty string after -i
    $SED -i '' '/shallow = true/d' .gitmodules
    $SED -i '' 's/--depth 1//g' Makefile.in
else
    # GNU sed syntax (works for gsed on macOS or sed on Linux)
    $SED -i '/shallow = true/d' .gitmodules
    $SED -i 's/--depth 1//g' Makefile.in
fi

echo "building toolchain for host: $HOST, arch: $ARCH, abi: $ABI"
./configure --prefix=$PREFIX --with-cmodel=medany --disable-gdb --with-arch=$ARCH --with-abi=$ABI
make -j$(nproc 2>/dev/null || sysctl -n hw.logicalcpu)

cd ..

cd .dist

tar cvJf $HOST.tar.xz $HOST

cd ..
