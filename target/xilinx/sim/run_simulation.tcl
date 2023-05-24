#source ips/xlnx_mig_ddr4_ex/questa/compile.do
#source ips/xlnx_mig_ddr4/questa/compile.do
source ../scripts/add_sources_vsim.tcl


vlog -work work -L xil_defaultlib -64 -incr -sv "./ips/xlnx_mig_ddr4_ex/questa/srcs/sim_tb_top.sv"


# Note : this testbench does not implenent the ddr4 memory model
set TESTBENCH "work.sim_tb_top xil_defaultlib.glbl"

set XLIB_ARGS "-L secureip -L xpm -L unisims_ver -L unimacro_ver -L work -L xil_defaultlib"

if {![info exists VOPTARGS]} {
    set VOPTARGS "+acc"
}

set flags "-permissive -suppress 3009 -suppress 8386 -error 7"

set pargs ""
if {[info exists BOOTMODE]} { append pargs "+BOOTMODE=${BOOTMODE} " }
if {[info exists PRELMODE]} { append pargs "+PRELMODE=${PRELMODE} " }
if {[info exists BINARY]}   { append pargs "+BINARY=${BINARY} " }
if {[info exists IMAGE]}    { append pargs "+IMAGE=${IMAGE} " }

eval "vsim ${TESTBENCH} -t 1ps -vopt -voptargs=\"${VOPTARGS}\"" ${XLIB_ARGS} ${pargs} ${flags}

set StdArithNoWarnings 1
set NumericStdNoWarnings 1