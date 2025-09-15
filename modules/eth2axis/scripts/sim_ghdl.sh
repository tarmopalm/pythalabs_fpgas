#!/bin/bash
export OSVVM_VER="2020.05"
export VIVADO_VER="2021.2"

export GHDL_LIBLIST="unisim spi_top_lib"
ghdl -i --std=08 --work=eth2axis_lib ../src/packetram.vhd
ghdl -i --std=08 --work=eth2axis_lib ../src/eth2axis.vhd

ln -s ../../../pythalabs_precompiled_libs/ghdl/xilinx/$VIVADO_VER/secureip/v08/secureip-obj08.cf secureip-obj08.cf
ln -s ../../../pythalabs_precompiled_libs/ghdl/xilinx/$VIVADO_VER/unifast/v08/unifast-obj08.cf  unifast-obj08.cf
ln -s ../../../pythalabs_precompiled_libs/ghdl/xilinx/$VIVADO_VER/unimacro/v08/unimacro-obj08.cf unimacro-obj08.cf
ln -s ../../../pythalabs_precompiled_libs/ghdl/xilinx/$VIVADO_VER/unisim/v08/unisim-obj08.cf   unisim-obj08.cf
ln -s ../../../pythalabs_precompiled_libs/ghdl/osvvm/$OSVVM_VER/osvvm/v08/osvvm-obj08.cf            osvvm-obj08.cf
#
#ghdl -m --work="testbench" -g -P"$GHDL_LIBLIST" --std=08 -fexplicit  -frelaxed-rules --ieee=synopsys "tb"
#ghdl -r -frelaxed-rules  --ieee=synopsys --std=08 --work="testbench" tb  --disp-tree=inst --ieee-asserts=disable --stop-time=100ms --vcd=tb.vcd
#
#gtkwave tb.vcd ../wave/GTKWaveSignals.sav
