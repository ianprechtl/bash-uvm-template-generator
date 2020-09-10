#!/bin/bash

# directories and paths
# --------------------------------------------------------------------------------------
GCC_PATH="/usr/bin/gcc"
TOP_DIR="../../top/"
SRC_DIR="../src/"
DPI_DIR="../cpp/"
LOG_DIR="log/"
UVM_DIR="/home/ian/intelFPGA_lite/18.1/modelsim_ase/verilog_src/uvm-1.2/"
WRK_DIR="work"

TOP_PATH=$TOP_DIR"top.v"
TESTBENCH_PATH=$SRC_DIR"testbench.sv"
DPI_SRC_DIR=$DPI_DIR"src"
DPI_LIB_DIR=$DPI_DIR"lib"
LOG_PATH=$LOG_DIR"test.log"

UVM_SRC_DIR=$UVM_DIR"src/"
UVM_PCK_PATH=$UVM_SRC_DIR"uvm_pkg.sv"
UVM_LIB_PATH=$UVM_DIR"lib/uvm_dpi"


# get options
# --------------------------------------------------------------------------------------
OPTS=""
OPT_COMPILE="true"
OPT_UVM="false"
while getopts "cdhu" opt; do	
  case ${opt} in
    c)	OPTS=$OPTS"-c "
      	;;
    d) 	OPT_COMPILE="false"
		;;
	u) 	OPT_UVM="true"
		;;
	h|\?)	echo "Usage:"
		echo " 	-h: Show this menu"
		echo "	-c: Run from terminal (no GUI)"
		echo " 	-d: Simulate without pre-compile"
		echo " 	-u: Compile/Run with UVM package"
		exit
      	;;
  esac
done

# script vlog -work work ../../top/top.v +incdir+../../top/
# --------------------------------------------------------------------------------------
if [ "$OPT_COMPILE" == "true" ]; then
	# compile top, need to remove working directory if already exists
	vlog -work work $TOP_PATH +incdir+$TOP_DIR

	# compile testbench along with packages (UVM, etc.)
	# if using UVM, etc. the package needs to be compiled first
	if [ "$OPT_UVM" == "false" ]; then
		vlog -work work $TESTBENCH_PATH +incdir+$SRC_DIR
	else
		vlog -work work $UVM_PCK_PATH +incdir+$UVM_SRC_DIR
		vlog -work work $TESTBENCH_PATH +incdir+$SRC_DIR +incdir+$UVM_SRC_DIR
	fi

	# compile dpi functions, write as 32-bit shared libraries
	# only compile if not empty
	if [ -f "$DPI_SRC_DIR/"*.cpp ]; then
		for file in $DPI_SRC_DIR/*.cpp; do g++ -shared -m32 $file -o $DPI_LIB_DIR/$(basename $file .cpp).so; done
	fi
fi

# run modelsim in terminal
# need to specify library .so's so collect all as string without extensions
lib_str=""
if [ -f "$DPI_LIB_DIR/"*.so ]; then
	for file in $DPI_LIB_DIR/*.so; do lib_str+=$(basename $file .so)\ ; done
fi

do_str="run -all"
if [[ $OPTS == "" ]]; then
	do_str="add wave /testbench/intf/*;""$do_str"
fi

if [ "$OPT_UVM" == "false" ]; then
	if [ "$lib_str" == "" ]; then
		vsim -work work $OPTS testbench -dpicpppath $GCC_PATH -do "$do_str" -l $LOG_PATH
	else
		vsim -work work $OPTS testbench -dpicpppath $GCC_PATH -sv_lib $DPI_LIB_DIR/$lib_str -do "$do_str" -l $LOG_PATH
	fi
else
	if [ "$lib_str" == "" ]; then
		vsim -work work $OPTS testbench -dpicpppath $GCC_PATH -sv_lib $UVM_LIB_PATH -do "$do_str" -l $LOG_PATH
	else
		vsim -work work $OPTS testbench -dpicpppath $GCC_PATH -sv_lib $UVM_LIB_PATH -sv_lib $DPI_LIB_DIR/$lib_str -do "$do_str" -l $LOG_PATH
	fi
fi

# clean up files
if test -f "tr_db.log"; then
	rm "tr_db.log"
fi