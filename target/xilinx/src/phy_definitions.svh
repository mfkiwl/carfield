`ifdef TARGET_VCU128
`define USE_RESET
`define USE_JTAG
`define USE_JTAG_VDDGND
`define USE_DDR4
// DRAM runs at 200MHz
`define DDR_CLK_DIVIDER 4'h4
`endif

`define DDR4_INTF                       \
/* Diff clock */                        \
input                 c0_sys_clk_p,     \
input                 c0_sys_clk_n,     \
/* DDR4 intf */                         \
output                c0_ddr4_act_n,    \
output [16:0]         c0_ddr4_adr,      \
output [1:0]          c0_ddr4_ba,       \
output [0:0]          c0_ddr4_bg,       \
output [0:0]          c0_ddr4_cke,      \
output [0:0]          c0_ddr4_odt,      \
output [1:0]          c0_ddr4_cs_n,     \
output [0:0]          c0_ddr4_ck_t,     \
output [0:0]          c0_ddr4_ck_c,     \
output                c0_ddr4_reset_n,  \
inout  [8:0]          c0_ddr4_dm_dbi_n, \
inout  [71:0]         c0_ddr4_dq,       \
inout  [8:0]          c0_ddr4_dqs_c,    \
inout  [8:0]          c0_ddr4_dqs_t,

`define DDR3_INTF                       \
/* Diff clock */                        \
input                 sys_clk_p,        \
input                 sys_clk_n,        \
/* DDR4 intf */                         \
output [14:0]         ddr3_addr,        \
output [2:0]          ddr3_ba,          \
output                ddr3_ras_n,       \
output                ddr3_cas_n,       \
output                ddr3_we_n,        \
output                ddr3_reset_n,     \
output [0:0]          ddr3_ck_p,        \
output [0:0]          ddr3_ck_n,        \
output [0:0]          ddr3_cke,         \
output [0:0]          ddr3_cs_n,        \
output [3:0]          ddr3_dm,          \
output [0:0]          ddr3_odt,         \
inout  [31:0]         ddr3_dq,          \
inout  [3:0]          ddr3_dqs_n,       \
inout  [3:0]          ddr3_dqs_p,

`define ila(__name, __signal)  \
    (* dont_touch = "yes" *) (* mark_debug = "true" *) logic [$bits(__signal)-1:0] __name; \
    assign __name = __signal;