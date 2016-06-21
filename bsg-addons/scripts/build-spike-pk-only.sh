#! /bin/bash
#
# Script to build RISC-V ISA simulator, proxy kernel, and GNU toolchain.
# Tools will be installed to $RISCV.

. build.common

#if [ ! `which riscv64-unknown-elf-gcc` ]
#then
#  echo "riscv64-unknown-elf-gcc doesn't appear to be installed; use the full-on build.sh"
#  exit 1
#fi

echo "Starting Spike-only build process"

build_project riscv-fesvr --prefix=$RISCV
build_project riscv-isa-sim --prefix=$RISCV --with-fesvr=$RISCV
#CC=riscv64-unknown-linux-gnu-gcc build_project riscv-pk --prefix=$RISCV/riscv64-unknown-linux-gnu --host=riscv64-unknown-linux-gnu
CC=riscv64-unknown-elf-gcc build_project riscv-pk --prefix=$RISCV/riscv64-unknown-elf --host=riscv64-unknown-elf

echo -e "\\nSpike-only build completed!"
