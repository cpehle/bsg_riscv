#! /bin/bash
echo "PATH=$PATH"
echo "RISCV=$RISCV"
echo "CC=$CC"
echo "CXX=$CXX"
rm -rf $TOP/rocket-chip/riscv-tools/riscv-gnu-toolchain/build-linux 
mkdir $TOP/rocket-chip/riscv-tools/riscv-gnu-toolchain/build-linux 
cd $TOP/rocket-chip/riscv-tools/riscv-gnu-toolchain/build-linux 
#cd $TOP/rocket-chip/riscv-tools/riscv-gnu-toolchain/build-linux; ../configure --enable-linux --prefix=$RISCV | tee configure-linux.log; make -j1 | tee build-linux.log
../configure --enable-linux --prefix=$RISCV CC=gcc
make -j1
