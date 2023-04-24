# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

create_clock -period 1000     -name sys_clk  [get_ports clk_i]
create_clock -period 20000    -name jtag_clk [get_ports jtag_tck_i]
create_clock -period 30000000 -name rtc_clk  [get_ports rtc_i]
