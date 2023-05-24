
set command ""
set script_path [ file dirname [ file normalize [ info script ] ] ]

if { $argc == 1 } {
  set command [lindex $argv 0]
}

puts "Running with SIMULATOR_PATH=$::env(SIMULATOR_PATH) ; GCC_PATH=$::env(GCC_PATH) ; XILINX_SIMLIB_PATH=$::env(XILINX_SIMLIB_PATH)"

# compile_simlib -simulator questa -simulator_exec_path {/usr/pack/questa-2022.3-bt/questasim/bin} -gcc_exec_path {/usr/pack/questa-2022.3-bt/questasim/gcc-7.4.0-linux_x86_64/bin} -family virtexuplus -library unisim -dir {/home/cykoenig/xlib_questa-2022.3}

if { $command == "compile_simlib" } {
  compile_simlib -simulator questa -simulator_exec_path {$::env(SIMULATOR_PATH)} \
	-gcc_exec_path {$::env(GCC_PATH)} -family all \
	-language verilog -dir {$::env(XILINX_SIMLIB_PATH)} -verbose

} elseif { $command == "export_simulation" } {
  open_project $::env(VIVADO_PROJECT)
  export_simulation -simulator questa -directory "./ips" -lib_map_path "$::env(XILINX_SIMLIB_PATH)" \
    -absolute_path -force -of_objects [get_ips *]

} else {
  puts "[$argv0] Unknown command: $command"
}
