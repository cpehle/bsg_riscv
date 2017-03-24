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
CONFIG?=DefaultVLSIConfig
export TOP=$(PWD)

export RISCV=$(TOP)/riscv-install
export ROCKET_CHIP=$(TOP)/rocket-chip
export PATCHES_DIR=$(TOP)/patches
export BSG_REPO=$(TOP)/bsg-addons
export RISCV_TOOLS=$(ROCKET_CHIP)/riscv-tools
export ROCKET_CORE=$(ROCKET_CHIP)/rocket
export VSIM=$(ROCKET_CHIP)/vsim

export BSG_TESTS=$(BSG_REPO)/tests
export TEST_SRCS=$(wildcard $(BSG_TESTS)/*.c)
export TEST_OBJS=$(TEST_SRCS:.c=.o)
export RISCV_LINUX=$(BSG_REPO)/riscv-linux
export BSG_SCRIPTS=$(BSG_REPO)/scripts
export BSG_PATCHES=$(BSG_REPO)/patches
export ROOT_MNT=/root/mount-dir/mnt
export SHA_TESTS=$(ROCKET_CHIP)/sha3/tests
export BSG_ACCEL_TESTS=$(ROCKET_CHIP)/bsg-accel/tests
export BSG_ACCEL_PATCHES=$(ROCKET_CHIP)/bsg-accel/patches

export LM_LICENSE_FILE?=27020@132.239.15.56
export SNPSLMD_LICENSE_FILE?=$(LM_LICENSE_FILE)
export SYNOPSYS_DIR?=/gro/cad/synopsys
export VCS_RELEASE?=vcs/J-2014.12-SP2
export VCS_BIN?=$(SYNOPSYS_DIR)/$(VCS_RELEASE)/bin
export VCS_HOME?=$(SYNOPSYS_DIR)/$(VCS_RELEASE)
PATH:=$(RISCV)/bin:/opt/rh/devtoolset-2/root/usr/bin:$(PATH):$(VCS_BIN)

export CC=/opt/rh/devtoolset-2/root/usr/bin/gcc
export CXX=/opt/rh/devtoolset-2/root/usr/bin/g++
export SED=sed
export PATH
export SHELL:=$(SHELL)

# does not seem to correctly simulate
#
#export BSG_VCS_OPTS=+define+MEM_BACKUP_EN +define+verbose +define+stats
export BSG_VCS_OPTS=+define+verbose +define+stats

dve:
	dve -full64 -vpd $(VSIM)/vcdplus.vpd

nothing:
	#which pk
	#@echo "$(PATH)"
	#which riscv64-unknown-linux-gnu-gcc
	#which gcc
	#spike -h
	#which riscv64-unknown-elf-gcc
	#riscv64-unknown-elf-gcc -o $(BSG_TESTS)/hello.rv $(BSG_TESTS)/hello.c
	#riscv64-unknown-linux-gnu-gcc -o $(BSG_TESTS)/hello.o $(BSG_TESTS)/hello.c


#-------------------------------
#Setup Rocket core and toolchain
#-------------------------------

rocket-chip:
	@echo
	@echo "#Cloning repositories recursively.."
	@git clone https://github.com/ucb-bar/rocket-chip.git
	@cd $(ROCKET_CHIP); git checkout ba96ad2b383a97a15b2d95b1acfd551f576c8faa -b bsg_hurricane #hurricane chip tape-out tag
	@cd $(ROCKET_CHIP); git submodule update --init --recursive
	@cd $(RISCV_TOOLS); git submodule update --init --recursive

clean-rocket-chip:
	rm -rf rocket-chip
	rm -rf riscv-install

#moves rocc to the RocketChipTop & changes memBackup config to false
rocc-to-top: 
	-cd $(ROCKET_CHIP); git apply --ignore-whitespace --ignore-space-change $(PATCHES_DIR)/rocket-chip-src/RocketChip.scala.patch
	-cd $(ROCKET_CORE); git apply  $(PATCHES_DIR)/rocket-src/tile.scala.patch

#reverses rocc-to-top patch
clean-rocc-to-top:
	-cd $(ROCKET_CHIP); git apply -R  $(PATCHES_DIR)/rocket-chip-src/RocketChip.scala.patch
	-cd $(ROCKET_CORE); git apply -R  $(PATCHES_DIR)/rocket-src/tile.scala.patch

#resolves the dcache
default-patch:
	-cd $(ROCKET_CHIP); git apply $(PATCHES_DIR)/vsim/Makefrag.patch
	-cd $(ROCKET_CHIP); git apply $(PATCHES_DIR)/vsim/Makefrag-verilog.patch
	-cd $(ROCKET_CHIP); git apply $(PATCHES_DIR)/rocket-chip-src/Configs.scala.patch
	-cd $(ROCKET_CORE); git apply $(PATCHES_DIR)/rocket-src/nbdcache.scala.patch
	-cd $(ROCKET_CORE); git apply $(PATCHES_DIR)/rocket-src/btb.scala.patch
	-cd $(ROCKET_CORE); git apply $(PATCHES_DIR)/rocket-src/csr.scala.patch
	-cd $(ROCKET_CORE); git apply $(PATCHES_DIR)/rocket-src/dpath_alu.scala.patch

#reverses default-patch
clean-default-patch:
	-cd $(ROCKET_CHIP); git apply -R $(PATCHES_DIR)/vsim/Makefrag.patch
	-cd $(ROCKET_CHIP); git apply -R $(PATCHES_DIR)/vsim/Makefrag-verilog.patch
	-cd $(ROCKET_CHIP); git apply -R $(PATCHES_DIR)/rocket-chip-src/Configs.scala.patch
	-cd $(ROCKET_CORE); git apply -R $(PATCHES_DIR)/rocket-src/nbdcache.scala.patch
	-cd $(ROCKET_CORE); git apply -R $(PATCHES_DIR)/rocket-src/btb.scala.patch
	-cd $(ROCKET_CORE); git apply -R $(PATCHES_DIR)/rocket-src/csr.scala.patch
	-cd $(ROCKET_CORE); git apply -R $(PATCHES_DIR)/rocket-src/dpath_alu.scala.patch

#rocc-to-top patch added by default before checkout
checkout-all: rocket-chip default-patch
	@echo
	@echo "#Checking repositories"
	@echo "#Patching building system"
	@(stat $(RISCV_TOOLS)/build.common.old > /dev/null 2>&1) || cp $(RISCV_TOOLS)/build.common $(RISCV_TOOLS)/build.common.old
	@(((patch --dry-run -N $(RISCV_TOOLS)/build.common patches/build.common.patch) > /dev/null 2>&1) && \
		patch -N $(RISCV_TOOLS)/build.common patches/build.common.patch) || echo "#Patch already applied ... skipping!"

#Toolchain for building spike and pk only
build-spike-pk:
	@echo
	@echo "#Building spike and pk only.."
	cd $(RISCV_TOOLS); sed -i 's/JOBS=16/JOBS=8/' build.common
	cd $(RISCV_TOOLS); $(BSG_SCRIPTS)/build-spike-pk-only.sh | tee $@.log

#Newlib toolchain build
build-riscv-tools-newlib:
	@echo
	@echo "#Building riscv tools (newlib).."
	@cd $(RISCV_TOOLS); sed -i 's/JOBS=16/JOBS=8/' build.common
	@cd $(RISCV_TOOLS); ./build.sh | tee $@.log

#Linux toolchain build
build-riscv-tools-linux:
	@echo
	@echo "#Building riscv tools (linux).."
	CC= CXX= bash -c '$(BSG_SCRIPTS)/build-linux.sh > build.log'

#clean toolchain
clean-riscv-tools:
	@for i in `find $(RISCV_TOOLS) -type d -maxdepth 1 -mindepth 1`; do make -C $$i/build clean; done

#Compilation for running bare metal
%.rv: %.c
	@echo
	@echo "#Compiling test code $(notdir $<).."
	riscv64-unknown-elf-gcc -o $@ $<

#Compilation for running on linux
%.o: %.c
	@echo
	@echo "#Compiling test code $(notdir $<).."
	riscv64-unknown-linux-gnu-gcc -static -I. -o $@ $<

%.S: %.rv
	riscv64-unknown-elf-objdump -d $< > $@


#---------------------------------
#Rockets versions
#---------------------------------

#Alpaca: Rocket default RTL
alpaca: clean-rocc-to-top clean-bsg-accel
	make -C $(VSIM) clean verilog NO_SRAM=1
	sed -i 's/\<Top\>/rocket_chip/g' rocket-chip/vsim/generated-src/Top.DefaultVLSIConfig.v
	sed -i 's/\<Top\>/test_bsg/g' rocket-chip/vsim/generated-src/Top.DefaultVLSIConfig.tb.vfrag
	sed -i 's/\.clk(clk)\,/\.core_clk_i(clk)\, \.io_clk_i(io_clk)\,/g' rocket-chip/vsim/generated-src/Top.DefaultVLSIConfig.tb.vfrag
	sed -i 's/\.reset(reset)\,/\0 \.gateway_async_reset_i(gateway_async_reset)\,/g' rocket-chip/vsim/generated-src/Top.DefaultVLSIConfig.tb.vfrag
	sed -i 's/gateway_async_reset)\,/\0 \.boot_done_o(boot_done)\,/g' rocket-chip/vsim/generated-src/Top.DefaultVLSIConfig.tb.vfrag

# Runs all asm and benchmark tests in VCS
alpaca-test: clean-rocc-to-top clean-bsg-accel
	make -C $(VSIM) clean verilog run

alpaca-test-debug: clean-rocc-to-top clean-bsg-accel verilog-debug

#Generates Rocket+Accum RTL with rocc moved to the top
bison: rocc-to-top build-bsg-accel
	make -C $(VSIM) clean verilog NO_SRAM=1 CONFIG=Bsg1AccelVLSIConfig
	sed -i 's/\<Top\>/rocket_chip/g' rocket-chip/vsim/generated-src/Top.Bsg1AccelVLSIConfig.v
	sed -i 's/\<Top\>/test_bsg/g' rocket-chip/vsim/generated-src/Top.Bsg1AccelVLSIConfig.tb.vfrag
	sed -i 's/\.clk(clk)\,/\.core_clk_i(clk)\, \.io_clk_i(io_clk)\,/g' rocket-chip/vsim/generated-src/Top.Bsg1AccelVLSIConfig.tb.vfrag
	sed -i 's/\.reset(reset)\,/\0 \.gateway_async_reset_i(gateway_async_reset)\,/g' rocket-chip/vsim/generated-src/Top.Bsg1AccelVLSIConfig.tb.vfrag
	sed -i 's/gateway_async_reset)\,/\0 \.boot_done_o(boot_done)\,/g' rocket-chip/vsim/generated-src/Top.Bsg1AccelVLSIConfig.tb.vfrag

#Runs all asm and bmark + Accelerator test
bison-test: rocc-to-top build-bsg-accel
	make verilog-run-acc num=1 test=accum

coyote: rocc-to-top build-bsg-accel
	make -C $(VSIM) clean verilog NO_SRAM=1 CONFIG=Bsg1AccelVLSIConfig
	sed -i 's/\<RocketChipTop\>/rocket_chip/g' rocket-chip/vsim/generated-src/Top.Bsg1AccelVLSIConfig.v
	sed -i 's/\<Top\>/test_bsg/g' rocket-chip/vsim/generated-src/Top.Bsg1AccelVLSIConfig.tb.vfrag
	sed -i 's/\.clk(clk)\,/\.core_clk_i(clk)\, \.io_clk_i(io_clk)\,/g' rocket-chip/vsim/generated-src/Top.Bsg1AccelVLSIConfig.tb.vfrag
	sed -i 's/\.reset(reset)\,/\0 \.gateway_async_reset_i(gateway_async_reset)\,/g' rocket-chip/vsim/generated-src/Top.Bsg1AccelVLSIConfig.tb.vfrag
	sed -i 's/gateway_async_reset)\,/\0 \.boot_done_o(boot_done)\,/g' rocket-chip/vsim/generated-src/Top.Bsg1AccelVLSIConfig.tb.vfrag
	sed -i 's/\.boot_done_o(boot_done)\,/\0 \.manycore_clk_i(manycore_clk)\,/g' rocket-chip/vsim/generated-src/Top.Bsg1AccelVLSIConfig.tb.vfrag
	sed -i 's/ifndef SYNTHESIS/ifdef ROCKET_INITREG_SIM/g' rocket-chip/vsim/generated-src/Top.Bsg1AccelVLSIConfig.v

coyote-test: bison-test



#---------------------------------
#Rocket testing using Spike
#---------------------------------

test-spike-hello: $(BSG_TESTS)/bsg_hello.rv
	@echo
	@echo "#Running $(notdir $<) on spike with pk.."
	spike pk $<
	@echo "sucess!"

test-spike-rocc: $(BSG_TESTS)/dummy_rocc_test.rv
	spike --extension=dummy_rocc pk $<

test-spike-rocc-linux:
	cd $(RISCV_LINUX); spike --extension=dummy_rocc +disk=root.bin bbl vmlinux

spike-linux-test-setup: $(TEST_OBJS)
	@echo
	@echo "#Placing compiled objects in the file system for linux boot on RISC-V (Need root privileges for writable mount!!).."
	su -c '	mkdir -p $(ROOT_MNT); \
					cp $(RISCV_LINUX)/original_root.bin $(ROOT_MNT)/../root.bin; \
					mount -o loop $(ROOT_MNT)/../root.bin $(ROOT_MNT); \
					$(foreach i, $(TEST_OBJS), cp $(i) $(ROOT_MNT)/bin/$(basename $(notdir $(i)));) \
					umount $(ROOT_MNT); \
					cd $(ROOT_MNT)/../; \
					su -c "cp root.bin $(RISCV_LINUX)"'

spike-linux-test:
	@echo
	@echo "#Booting linux on RISC-V (spike).."
	cd $(RISCV_LINUX); spike -p2 +disk=root.bin bbl vmlinux

test-clean:
	rm -rf $(BSG_TESTS)/*.o
	rm -rf $(BSG_TESTS)/*.rv
	rm -rf $(RISCV_LINUX)/root.bin

#fetch-riscv-linux:
#	make -C rocket-chip/fpga-zynq/zybo fetch-riscv-linux-deliver
#	cp -r rocket-chip/fpga-zynq/zybo/deliver_output/riscv riscv-linux/


#------------------------------------
#Rocket testing using Chisel emulator
#------------------------------------

emulator-tests:
	cd rocket-chip/emulator; make clean
	cd rocket-chip/emulator; make
	cd rocket-chip/emulator; make run-asm-tests
	cd rocket-chip/emulator; make run-bmark-tests

emulator-linux:
	cd rocket-chip/emulator; time ./emulator-Top-DefaultCPPConfig +dramsim +max-cycles=1000000000 +verbose \
	  +disk=$(RISCV_LINUX)/root.bin \
			bbl $(RISCV_LINUX)/vmlinux \
				3>&1 1>&2 2>&3 | spike-dasm > /dev/null

emulator-rocc-linux:
	#cd $(ROCKET-CHIP)/riscv-tools/riscv-isa-sim/dummy_rocc && riscv64-unknown-elf-gcc dummy_rocc_test.c -I. -o dummy_rocc_test.rv
	#elf2hex 16 16384 dummy_rocc_test > dummy_rocc_test.hex
	cd rocket-chip/emulator; make clean
	cd rocket-chip/emulator; make CONFIG=RoccExampleConfig
	#cd rocket-chip/emulator; make CONFIG=RoccExampleConfig run-asm-tests
	#cd rocket-chip/emulator; make CONFIG=RoccExampleConfig run-bmark-tests
	#	cd rocket-chip/emulator; ./emulator-Top-RoccExampleConfig pk $(ROCKET-CHIP)/riscv-tools/riscv-isa-sim/dummy_rocc/dummy_rocc_test.rv +dramsim
	cd rocket-chip/emulator; time ./emulator-Top-RoccExampleConfig +dramsim +max-cycles=1000000000 +verbose \
	  +disk=$(RISCV_LINUX)/root.bin \
			bbl $(RISCV_LINUX)/vmlinux \
				3>&1 1>&2 2>&3 | spike-dasm > /dev/null

rocket-chip/bsg-accel:
	git clone https://github.com/anujnr/bsg_accel.git $@

emulator-rocc: $(BSG_TESTS)/dummy_rocc_test.rv
	cd rocket-chip/emulator; make clean
	cd rocket-chip/emulator; make CONFIG=RoccExampleConfig;
# can use -j 4 here
	#cd rocket-chip/emulator; make CONFIG=RoccExampleConfig output/rv64ui-p-add.out
	#cd rocket-chip/emulator; make CONFIG=Sha3CPPConfig run-bmark-tests
# to test hardware acelerated implementations of sha3 vs the sha3 software algorithm
	cd rocket-chip/emulator; ./emulator-Top-RoccExampleConfig -q +ntb_random_seed_automatic +dramsim +verbose +max-cycles=100000000 pk $< 3>&1 1>&2 2>&3 | spike-dasm > $@.out

verilog-rocc: $(BSG_TESTS)/dummy_rocc_test.rv
	make -C $(VSIM) clean
	make -C $(VSIM) CONFIG=RoccExampleConfig
	cd $(VSIM) && ./simv-Top-RoccExampleConfig -q +ntb_random_seed_automatic +dramsim +verbose +max-cycles=100000000 pk $< 3>&1 1>&2 2>&3 | spike-dasm > $@.out

output_dir?=$(TOP)/$(VSIM)/output
test?=rv64ui-p-add
$(output_dir)/$(test).out:
	cd $(VSIM)/ && make output/$(test).out CONFIG=RoccExampleConfig

verilog-test: $(output_dir)/$(test).out

clean-vsim:
	touch $(BSG_TESTS)/dummy_rocc_test.c
	cd $(VSIM); make clean
	#make -C $(VSIM) clean



#------------------------------------
#Rocket + SHA3 Accel
#------------------------------------

rocket-chip/rocc-template:
	git clone https://bitbucket.org/taylor-bsg/bsg_riscv_rocc.git $@

RISCV_ISA_SIM= $(RISCV_TOOLS)/riscv-isa-sim
build-sha: rocket-chip/rocc-template clean-default-patch
	cd rocket-chip/rocc-template; ./install-symlinks
	-rm -rf $(RISCV_ISA_SIM)/build-sha
	mkdir -p $(RISCV_ISA_SIM)/build-sha
	cd $(RISCV_ISA_SIM); cp configure configure.old
	cd $(RISCV_ISA_SIM); autoreconf -i
	cd $(RISCV_ISA_SIM)/build-sha; ../configure --prefix=$(RISCV) --with-fesvr=$(RISCV)
	make -C $(RISCV_ISA_SIM)/build-sha > $(RISCV_TOOLS)/$@.log
	make -C $(RISCV_ISA_SIM)/build-sha install >> $(RISCV_TOOLS)/$@.log

clean-sha:
	rm rocket-chip/src/main/scala/PrivateConfigs.scala
	cd $(RISCV_ISA_SIM); rm sha3 riscv-sha3.pc.in configure.ac; mv configure.ac.old configure.ac; mv configure.old configure
	cd $(ROCKET_CHIP); rm sha3 Makefrag; mv Makefrag.old Makefrag
	cd $(RISCV_ISA_SIM); rm -rf build-sha; #build;
	cd $(RISCV_TOOLS); ./build-spike-only.sh
	#TODO: make build-sha replace build directory and clean-sha recreate it

test-spike-sha: $(SHA_TESTS)/sha3-rocc.rv
	spike --extension=sha3 pk $<

test-sha-linux-setup:
	cp $(SHA_TESTS)/* $(BSG_TESTS)
	make spike-linux-test-setup

test-spike-sha-linux:
	cd $(RISCV_LINUX); spike --extension=sha3 +disk=root.bin bbl vmlinux

#cd rocket-chip/emulator; ./emulator-Top-Sha3CPPConfig pk ../sha3/tests/sha3-sw.rv +dramsim
emulator-sha: $(SHA_TESTS)/sha3-rocc.rv
	cd rocket-chip/emulator; make clean
	cd rocket-chip/emulator; make CONFIG=Sha3CPPConfig;
	#cd rocket-chip/emulator; make CONFIG=Sha3CPPConfig run; #Uncomment to run all RISC-V assembly tests
	cd rocket-chip/emulator; ./emulator-Top-Sha3CPPConfig pk -s $< #Runs the accelerator test

#4 hours
emulator-sha-linux:
	cd rocket-chip/emulator; make clean
	cd rocket-chip/emulator; make CONFIG=Sha3CPPConfig
	cd rocket-chip/emulator; time ./emulator-Top-Sha3CPPConfig +dramsim +max-cycles=1000000000 +verbose \
	  +disk=$(RISCV_LINUX)/root.bin \
		  bbl $(RISCV_LINUX)/vmlinux \
			  3>&1 1>&2 2>&3 | spike-dasm  > /dev/null

verilog-run-sha: $(SHA_TESTS)/sha3-rocc.rv
	make -C $(VSIM) clean
	make -C $(VSIM) CONFIG=Sha3VLSIConfig;
	#make -C $(VSIM) CONFIG=Sha3VLSIConfig run; #Uncomment to run all RISC-V assembly tests
	cd $(VSIM) && ./simv-Top-Sha3VLSIConfig -q +ntb_random_seed_automatic +dramsim +verbose +max-cycles=100000000 pk $< 3>&1 1>&2 2>&3 | spike-dasm > $@.out #Runs the accelerator test


#9 hours
verilog-sha-linux:
	make -C $(VSIM) clean
	make -C $(VSIM) CONFIG=Sha3VLSIConfig
	#make -C $(VSIM) CONFIG=Sha3VLSIConfig run
	cd $(VSIM); time ./simv-Top-Sha3VLSIConfig -q +ntb_random_seed_automatic +dramsim +verbose +max-cycles=1000000000 +disk=$(RISCV_LINUX)/root.bin bbl $(RISCV_LINUX)/vmlinux 3>&1 1>&2 2>&3 | spike-dasm > /dev/null


#------------------------------------
#Rocket + verilog Accel
#------------------------------------

build-bsg-accel: rocket-chip/bsg-accel
	cd $<; ./install-symlinks

clean-bsg-accel:
	-mv $(ROCKET_CHIP)/Makefrag.old $(ROCKET_CHIP)/Makefrag 2>/dev/null
	-rm $(ROCKET_CHIP)/src/main/scala/PrivateConfigs.scala
	-rm $(ROCKET_CHIP)/accel
	-patch -Rf $(VSIM)/Makefile $(BSG_ACCEL_PATCHES)/vsim/Makefile.patch
	-patch -Rf $(VSIM)/Makefrag $(BSG_ACCEL_PATCHES)/vsim/Makefrag.patch

num?=1
verilog-run-acc: $(BSG_ACCEL_TESTS)/$(test).rv
	make verilog-run CONFIG=Bsg$(num)AccelVLSIConfig
	#cd $(VSIM) && ./simv-Top-Bsg$(num)AccelVLSIConfig -gui -q +ntb_random_seed_automatic +dramsim +verbose +max-cycles=100000000 pk $< 3>&1 1>&2 2>&3 | spike-dasm > $@.out
	cd $(VSIM) && ./simv-Top-Bsg$(num)AccelVLSIConfig -q +ntb_random_seed_automatic +dramsim +verbose +max-cycles=100000000 pk $< 3>&1 1>&2 2>&3 | spike-dasm > $@.out

emulator-bsg-accel: $(BSG_ACCEL_TESTS)/sha3-accum.rv
	make -C rocket-chip/emulator clean
	make -C rocket-chip/emulator CONFIG=Bsg$(num)AccelCPPConfig
	cd rocket-chip/emulator && ./emulator-Top-Bsg$(num)AccelCPPConfig -q +ntb_random_seed_automatic +dramsim +max-cycles=100000000 pk -s $<

verilog-clean:
	make -C $(VSIM) clean

emulator-debug:
	cd rocket-chip/emulator; make debug

verilog:
	cd $(VSIM); make clean
	cd $(VSIM); make verilog
#	grep "^module" $(VSIM)/generated-src/Top.$(CONFIG).v
#	@echo "# See $(VSIM)/generated-src for outputed source."
#	@echo "# Behavorial SRAMs have been appended to end of vsim/generated-src/Top.$(CONFIG).v"
#	@echo "# unless $(mem_gen) script is changed."
#	@echo "# src/main/scala/PublicConfigs.scala sets base configuration-- can be overridden"
#	@echo "# --see ExampleSmallConfig--"

verilog-run: verilog-clean
	make -C $(VSIM) run
	#cd $(VSIM)/output; for t in `ls *.out`; do echo $$t `cat $$t | tail -1 | awk '{print $$2}'` >> $@.stats; done

verilog-debug: verilog-clean
	make -C $(VSIM) run-debug


#------------------------------------
#Linux
#------------------------------------

linux-4.1.15:
	curl -L https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.1.15.tar.xz | tar -xJ
	cd linux-4.1.15; git init
	cd linux-4.1.15; git remote add origin https://github.com/riscv/riscv-linux.git
	cd linux-4.1.15; git fetch
	cd linux-4.1.15; git checkout -f 9b53d11c935d22f2a8bd996904694c2b83bcfccf #working linux tag

linux: linux-4.1.15
	make -C linux-4.1.15 ARCH=riscv defconfig
	make -C linux-4.1.15 ARCH=riscv menuconfig
	make -C linux-4.1.15 -j4 ARCH=riscv vmlinux

busy-box:
	curl -L http://busybox.net/downloads/busybox-1.21.1.tar.bz2 | tar -xj
	make -C busybox-1.21.1 allnoconfig
	make -C busybox-1.21.1 menuconfig
	make -C busybox-1.21.1 -j4


#gmp-$(GMP_VERSION):
#	wget http://ftp.gnu.org/gnu/gmp/gmp-$(GMP_VERSION).tar.bz2
#	bunzip2 gmp-$(GMP_VERSION).tar.bz2
#	tar xvf gmp-$(GMP_VERSION).tar
#	cd gmp-$(GMP_VERSION);	./configure --disable-shared --enable-static --prefix=$(BIN)
#	cd gmp-$(GMP_VERSION); make && make check && make install
#
#mpfr-$(MPFR_VERSION): gmp-$(GMP_VERSION)
#	wget http://ftp.gnu.org/gnu/mpfr/mpfr-$(MPFR_VERSION).tar.bz2
#	bunzip2 mpfr-$(MPFR_VERSION).tar.bz2
#	tar xvf mpfr-$(MPFR_VERSION).tar
#	cd mpfr-$(MPFR_VERSION); ./configure --disable-shared --enable-static --prefix=$(BIN) --with-gmp=$(BIN)
#	cd mpfr-$(MPFR_VERSION); make && make check && make install
#
#mpc-$(MPC_VERSION): mpfr-$(MPFR_VERSION) gmp-$(GMP_VERSION)
#	wget http://ftp.gnu.org/gnu/mpc/mpc-$(MPC_VERSION).tar.gz
#	tar zxvf mpc-$(MPC_VERSION).tar.gz
#	cd mpc-$(MPC_VERSION); ./configure --disable-shared --enable-static --prefix=$(BIN) --with-gmp=$(BIN) --with-mpfr=$(BIN)
#	make -C mpc-$(MPC_VERSION) #make check && make install
#
#http://stackoverflow.com/questions/9450394/how-to-install-gcc-piece-by-piece-with-gmp-mpfr-mpc-elf-without-shared-libra

#linux-3.14.41:
#	curl -L https://cdn.kernel.org/pub/linux/kernel/v3.x/linux-3.14.41.tar.xz | tar -xJ
#	cd linux-3.14.41; git init
#	cd linux-3.14.41; git remote add -t linux-3.14.y-riscv origin https://github.com/riscv/riscv-linux.git
#	cd linux-3.14.41; git fetch
#	cd linux-3.14.41; git checkout -f -t origin/linux-3.14.y-riscv
