# MBT 12-18-15
#
# 1. Ran these commands to get gcc-4.8  (on bb-91) CENTOS 6.7
#
# wget http://people.centos.org/tru/devtools-2/devtools-2.repo -O /etc/yum.repos.d/devtools-2.repo
# yum install devtoolset-2-gcc devtoolset-2-binutils
# yum install devtoolset-2-gcc-c++ devtoolset-2-gcc-gfortran
#
# /opt/rh/devtoolset-2/root/usr/bin/gcc --version
#
# did not run: scl enable devtoolset-2 bash
#              source /opt/rh/devtoolset-2/enable

# 2. yum packages
# yum install libmpc
# assumed already installed: autoconf automake libtool curl gmp gawk bison flex texinfo gperf gcc48 gsed
#
#
#
#

export RISCV:=$(PWD)/riscv-install
#export RISCV:=$(PWD)/rocket-chip/riscv-tools
#export BIN:=$(PWD)/bin
export RISCV-LINUX:=$(PWD)/linux_zedboard
export ROCKET-CHIP:=$(PWD)/rocket-chip
export LM_LICENSE_FILE      = 27000@bbfs-00.calit2.net
export SNPSLMD_LICENSE_FILE = $(LM_LICENSE_FILE)
export SYNOPSYS_DIR=/gro/cad/synopsys
export VCS_RELEASE=vcs/J-2014.12-SP2
export VCS_BIN       = $(SYNOPSYS_DIR)/$(VCS_RELEASE)/bin
export VCS_HOME      = $(SYNOPSYS_DIR)/$(VCS_RELEASE)

PATH:=/opt/rh/devtoolset-2/root/usr/bin:$(PATH):$(RISCV)/bin:$(VCS_BIN)

#export GMP_VERSION = 6.1.0
#export MPFR_VERSION = 3.1.4
#export MPC_VERSION= 1.0.3

export CC=/opt/rh/devtoolset-2/root/usr/bin/gcc
export CXX=/opt/rh/devtoolset-2/root/usr/bin/g++
export SED=sed

export PATH
export SHELL:=$(SHELL)

# does not seem to correctly simulate
#
#export BSG_VCS_OPTS=+define+MEM_BACKUP_EN +define+verbose +define+stats
export BSG_VCS_OPTS=+define+verbose +define+stats

nothing:
	which gcc
	which spike
	#which riscv64-unknown-elf-gcc
	#which gcc
	#which riscv64-unknown-linux-gnu-gcc 

checkout-all:
	git clone https://github.com/ucb-bar/rocket-chip.git
	cd rocket-chip; git checkout ba96ad2b383a97a15b2d95b1acfd551f576c8faa #hurricane chip tape-out tag 
	#cd rocket-chip; git submodule update --init --recursive
	cd rocket-chip; git submodule update --init riscv-tools
	cd rocket-chip/riscv-tools;     git submodule update --init --recursive

# XXXX various warnings for build-riscv-tools below:
#configure: WARNING: using in-tree ISL, disabling version check
#*** This configuration is not supported in the following subdirectories:
#     target-libquadmath target-libatomic target-libcilkrts target-libitm target-libsanitizer target-libvtv target-l#ibmpx gnattools gotools target-libada target-libgfortran target-libgo target-libffi target-libbacktrace target-zlib# target-libjava target-libobjc target-libgomp target-liboffloadmic target-libssp target-boehm-gc
#    (Any other directories should still work fine.)
#configure: WARNING: In the future, Autoconf will not detect cross-tools
#whose name does not start with the host triplet.  If you think this
#configuration is useful to you, please write to autoconf@gnu.org.
#configure: WARNING: decimal float is not supported for this target, ignored
#configure: WARNING: cannot check for properly working vsnprintf when cross compiling, will assume it's ok
#libtool: install: warning: remember to run `libtool --finish /homes/mbt/raw/riscv/riscv-install/libexec/gcc/riscv64#-unknown-elf/5.2.0'
#gengtype-lex.c: In function ‘int yy_get_next_buffer()’:
#gengtype-lex.c:2150:27: warning: comparison between signed and unsigned integer expressions [-Wsign-compare]
#gengtype-lex.c:1342:20: note: in definition of macro ‘YY_INPUT’
#/homes/mbt/raw/riscv/rocket-chip/riscv-tools/riscv-gnu-toolchain/build/src/newlib-gcc/gcc/config/riscv/riscv.md:2263: warning: operand 0 missing mode?
#/homes/mbt/raw/riscv/rocket-chip/riscv-tools/riscv-gnu-toolchain/build/src/newlib-gcc/gcc/config/riscv/riscv.md:2283: warning: operand 1 missing mode?
#/homes/mbt/raw/riscv/rocket-chip/riscv-tools/riscv-gnu-toolchain/build/src/newlib-gcc/gcc/config/riscv/riscv.md:2293: warning: operand 1 missing mode?
#/homes/mbt/raw/riscv/rocket-chip/riscv-tools/riscv-gnu-toolchain/build/src/newlib-gcc/gcc/config/riscv/riscv.md:2317: warning: operand 0 missing mode?
#/homes/mbt/raw/riscv/rocket-chip/riscv-tools/riscv-gnu-toolchain/build/src/newlib-gcc/gcc/config/riscv/riscv.md:2339: warning: operand 1 missing mode?
#/homes/mbt/raw/riscv/rocket-chip/riscv-tools/riscv-gnu-toolchain/build/src/newlib-gcc/gcc/config/riscv/riscv.md:2351: warning: operand 1 missing mode?
build-riscv-tools-newlib: 
	cd rocket-chip/riscv-tools; sed -i 's/JOBS=16/JOBS=8/' build.common
	cd rocket-chip/riscv-tools; ./build.sh | tee $@.log

build-riscv-tools-spike-only: 
	cd rocket-chip/riscv-tools; sed -i 's/JOBS=16/JOBS=8/' build.common
	cd rocket-chip/riscv-tools; ./build-spike-only.sh | tee $@.log

build-riscv-tools-linux: build-riscv-tools-newlib
	cd rocket-chip/riscv-tools/riscv-gnu-toolchain; ./configure --prefix=$(RISCV) | tee config.log
	#make -C rocket-chip/riscv-tools/riscv-gnu-toolchain clean
	make -C rocket-chip/riscv-tools/riscv-gnu-toolchain -j16 linux | tee $@.log

clean:
	rm -rf rocket-chip

emulator: 
	cd rocket-chip/emulator; make clean
	cd rocket-chip/emulator; make
	#cd rocket-chip/emulator; make run-asm-tests
	#cd rocket-chip/emulator; make run-bmark-tests	
	
	cd rocket-chip/emulator; time ./emulator-Top-DefaultCPPConfig +dramsim +max-cycles=1000000000 +verbose \
	  +disk=../../linux_zedboard/root.bin \
		 	bbl ../../linux_zedboard/vmlinux \
				3>&1 1>&2 2>&3 | spike-dasm > /dev/null

emulator-rocc-linux:
	#cd $(ROCKET-CHIP)/riscv-tools/riscv-isa-sim/dummy_rocc && riscv64-unknown-elf-gcc dummy_rocc_test.c -I. -o dummy_rocc_test.rv 
	#riscv64-unknown-elf-objdump -d $(ROCKET-CHIP)/riscv-tools/riscv-isa-sim/dummy_rocc/dummy_rocc_test.rv > $(ROCKET-CHIP)/riscv-tools/riscv-isa-sim/dummy_rocc/dummy_rocc_test.S
	#elf2hex 16 16384 dummy_rocc_test > dummy_rocc_test.hex
	cd rocket-chip/emulator; make clean
	cd rocket-chip/emulator; make CONFIG=RoccExampleConfig
	cd rocket-chip/emulator; make CONFIG=RoccExampleConfig run-asm-tests
	cd rocket-chip/emulator; make CONFIG=RoccExampleConfig run-bmark-tests	
#	cd rocket-chip/emulator; ./emulator-Top-RoccExampleConfig pk $(ROCKET-CHIP)/riscv-tools/riscv-isa-sim/dummy_rocc/dummy_rocc_test.rv +dramsim
	cd rocket-chip/emulator; time ./emulator-Top-RoccExampleConfig +dramsim +max-cycles=1000000000 +verbose \
	  +disk=../../linux_zedboard/root.bin \
		 	bbl ../../linux_zedboard/vmlinux \
				3>&1 1>&2 2>&3 | spike-dasm > /dev/null
	
rocket-chip/rocc-template:
	git clone -b update https://github.com/anujnr/rocc-template.git rocket-chip/rocc-template

build-sha: rocket-chip/rocc-template
	#cd rocket-chip/rocc-template; ./install-symlinks
	#mkdir -p rocket-chip/riscv-tools/riscv-isa-sim/build-sha
	#cd rocket-chip/riscv-tools/riscv-isa-sim/build-sha; ../configure --prefix=$(RISCV) --with-fesvr=$(RISCV) | tee config.log
	cd rocket-chip/riscv-tools; ./build-spike-only.sh
	#make -C rocket-chip/riscv-tools/riscv-isa-sim/build-sha
	#make -C rocket-chip/riscv-tools/riscv-isa-sim/build-sha install

clean-sha:
	rm rocket-chip/src/main/scala/PrivateConfigs.scala
	cd rocket-chip/riscv-tools/riscv-isa-sim; rm sha3 riscv-sha3.pc.in configure.ac; mv configure.ac.old configure.ac
	cd rocket-chip; rm sha3 Makefrag; mv Makefrag.old Makefrag
	cd rocket-chip/riscv-tools/riscv-isa-sim; rm -rf build-sha; #build; 
	mkdir -p rocket-chip/riscv-tools/riscv-isa-sim/build 
	#cd rocket-chip/riscv-tools/riscv-isa-sim/build; ../configure --prefix=$(RISCV) --with-fesvr=$(RISCV) | tee config.log; 
	#make -C rocket-chip/riscv-tools/riscv-isa-sim/build | tee $@.log ;
	make -C rocket-chip/riscv-tools/riscv-isa-sim/build install ;
	
emulator-sha:
	cd rocket-chip/emulator; make clean
	cd rocket-chip/emulator; make CONFIG=Sha3CPPConfig;
# can use -j 4 here
	cd rocket-chip/emulator; make CONFIG=Sha3CPPConfig run-asm-tests
	cd rocket-chip/emulator; make CONFIG=Sha3CPPConfig run-bmark-tests
# to test software and hardware aacelerated implementations of sha3
	cd rocket-chip/emulator; ./emulator-Top-Sha3CPPConfig pk ../sha3/tests/sha3-sw.rv +dramsim
	cd rocket-chip/emulator; ./emulator-Top-Sha3CPPConfig pk ../sha3/tests/sha3-rocc.rv +dramsim

#	cd rocket-chip/emulator; make clean
#	cd rocket-chip/emulator; make CONFIG=Sha3CPPConfig;
emulator-sha-linux:
	cd rocket-chip/emulator; ./emulator-Top-Sha3CPPConfig +dramsim +max-cycles=1000000000 +verbose \
	  +disk=../../linux-4.1.17/root.bin \
		  ../../linux-4.1.17/vmlinux \
			  3>&1 1>&2 2>&3 | spike-dasm  > /dev/null

emulator-debug:
	cd rocket-chip/emulator; make debug

test:
	make $@.run

test.run:
	echo $(PATH)
	echo '#include <stdio.h>' > hello.c
	echo ' int main(void) { printf("Hello world!\n"); return 0; }' >> hello.c
	riscv64-unknown-elf-gcc -o hello hello.c
	spike pk hello

test-rocc:
	riscv64-unknown-elf-gcc -o dummy_rocc_test /homes/anr044/raw/riscv/rocket-chip/riscv-tools/riscv-isa-sim/dummy_rocc/dummy_rocc_test.c
	spike --extension=dummy_rocc pk dummy_rocc_test

compile-rocc-linux:
	riscv64-unknown-linux-gnu-gcc -static -o dummy_rocc_test /homes/anr044/raw/riscv/rocket-chip/riscv-tools/riscv-isa-sim/dummy_rocc/dummy_rocc_test.c
	
test-rocc-linux:
	cd linux_zedboard; spike --extension=dummy_rocc +disk=root.bin bbl vmlinux

verilog:
	cd rocket-chip/vsim; make verilog
	grep "^module" rocket-chip/vsim/generated-src/Top.DefaultVLSIConfig.v
	@echo "# See rocket-chip/vsim/generated-src for outputed source."
	@echo "# Behavorial SRAMs have been appended to end of vsim/generated-src/Top.DefaultVLSIConfig.v"
	@echo "# unless $(mem_gen) script is changed."
	@echo "# src/main/scala/PublicConfigs.scala sets base configuration-- can be overridden"
	@echo "# --see ExampleSmallConfig--"

verilog-rocc:
	cd rocket-chip/vsim; make CONFIG=RoccExampleConfig verilog

verilog-clean:
	make -C rocket-chip/vsim clean

verilog-run: 
	make -C rocket-chip/vsim clean
	make -C rocket-chip/vsim
	make -C rocket-chip/vsim run
	
verilog-run-linux: #verilog-run
	cd rocket-chip/vsim; time ./simv-Top-DefaultVLSIConfig -q +ntb_random_seed_automatic +dramsim +verbose +max-cycles=1000000000 +disk=$(RISCV-LINUX)/root.bin $(RISCV)/riscv64-unknown-elf/bin/bbl $(RISCV-LINUX)/vmlinux 3>&1 1>&2 2>&3 | spike-dasm > /dev/null

verilog-run-rocc: verilog-clean
	make -C rocket-chip/vsim CONFIG=RoccExampleConfig
	#make -C rocket-chip/vsim CONFIG=RoccExampleConfig run
	cd rocket-chip/vsim; time ./simv-Top-RoccExampleConfig -q +ntb_random_seed_automatic +dramsim +verbose +max-cycles=1000000000 +disk=$(RISCV-LINUX)/root.bin $(RISCV)/riscv64-unknown-elf/bin/bbl $(RISCV-LINUX)/vmlinux 3>&1 1>&2 2>&3 | spike-dasm > /dev/null

verilog-run-sha: verilog-clean
	make -C rocket-chip/vsim CONFIG=Sha3VLSIConfig
	make -C rocket-chip/vsim CONFIG=Sha3VLSIConfig run
	riscv64-unknown-elf-gcc -o sha3-rocc.rv $(ROCKETCHIP)/sha3/tests/sha3-rocc.c
	cd rocket-chip/vsim && ./simv-Top-Sha3VLSIConfig -q +ntb_random_seed_automatic +dramsim +verbose +max-cycles=100000000 pk ../sha3/tests/sha3-rocc.rv 3>&1 1>&2 2>&3 > sha3.out

verilog-debug: verilog-clean
	make -C rocket-chip/vsim run-debug

gmp-$(GMP_VERSION):
	wget http://ftp.gnu.org/gnu/gmp/gmp-$(GMP_VERSION).tar.bz2
	bunzip2 gmp-$(GMP_VERSION).tar.bz2
	tar xvf gmp-$(GMP_VERSION).tar
	cd gmp-$(GMP_VERSION);	./configure --disable-shared --enable-static --prefix=$(BIN)
	cd gmp-$(GMP_VERSION); make && make check && make install

mpfr-$(MPFR_VERSION): gmp-$(GMP_VERSION)
	wget http://ftp.gnu.org/gnu/mpfr/mpfr-$(MPFR_VERSION).tar.bz2
	bunzip2 mpfr-$(MPFR_VERSION).tar.bz2
	tar xvf mpfr-$(MPFR_VERSION).tar
	cd mpfr-$(MPFR_VERSION); ./configure --disable-shared --enable-static --prefix=$(BIN) --with-gmp=$(BIN)
	cd mpfr-$(MPFR_VERSION); make && make check && make install

mpc-$(MPC_VERSION): mpfr-$(MPFR_VERSION) gmp-$(GMP_VERSION)
	wget http://ftp.gnu.org/gnu/mpc/mpc-$(MPC_VERSION).tar.gz
	tar zxvf mpc-$(MPC_VERSION).tar.gz
	cd mpc-$(MPC_VERSION); ./configure --disable-shared --enable-static --prefix=$(BIN) --with-gmp=$(BIN) --with-mpfr=$(BIN)
	make -C mpc-$(MPC_VERSION) #make check && make install

#http://stackoverflow.com/questions/9450394/how-to-install-gcc-piece-by-piece-with-gmp-mpfr-mpc-elf-without-shared-libra

linux-3.14.41: 
	curl -L https://cdn.kernel.org/pub/linux/kernel/v3.x/linux-3.14.41.tar.xz | tar -xJ
	cd linux-3.14.41; git init
	cd linux-3.14.41; git remote add -t linux-3.14.y-riscv origin https://github.com/riscv/riscv-linux.git
	cd linux-3.14.41; git fetch
	cd linux-3.14.41; git checkout -f -t origin/linux-3.14.y-riscv

linux-4.1.17: 
	curl -L https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.1.17.tar.xz | tar -xJ
	cd linux-4.1.17; git init
	cd linux-4.1.17; git remote add -t master origin https://github.com/riscv/riscv-linux.git
	cd linux-4.1.17; git fetch
	cd linux-4.1.17; git checkout -f -t origin/master

linux1: linux-3.14.41
	make -C linux-3.14.41 ARCH=riscv defconfig
	make -C linux-3.14.41 -j4 ARCH=riscv vmlinux

linux: linux-4.1.17
	make -C linux-4.1.17 ARCH=riscv defconfig
	make -C linux-4.1.17 -j4 ARCH=riscv vmlinux

busy-box:
	#curl -L http://busybox.net/downloads/busybox-1.21.1.tar.bz2 | tar -xj
	#make -C busybox-1.21.1 allnoconfig
	#make -C busybox-1.21.1 menuconfig
	make -C busybox-1.21.1 -j4

spike-linux:
	cd linux_zedboard; spike +disk=root.bin bbl vmlinux
