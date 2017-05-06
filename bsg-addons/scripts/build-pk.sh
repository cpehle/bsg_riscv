#! /bin/bash
#
# Script to build RISC-V ISA simulator, proxy kernel, and GNU toolchain.
# Tools will be installed to $RISCV.

. build.common.old

echo "Starting RISC-V Toolchain build process"

CC= CXX= build_project riscv-pk --prefix=$RISCV/riscv64-unknown-elf --host=riscv64-unknown-elf

echo -e "\\nRISC-V Toolchain installation completed!"
