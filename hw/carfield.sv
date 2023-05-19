// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Thomas Benz     <tbenz@ethz.ch>
// Luca Valente    <luca.valente@unibo.it>
// Yvan Tortorella <yvan.tortorella@unibo.it>
// Alessandro Ottaviano <aottaviano@iis.ee.ethz.ch>

`include "cheshire/typedef.svh"
`include "axi/typedef.svh"
`include "apb/typedef.svh"

/// Top-level implementation of Carfield
module carfield
  import carfield_pkg::*;
  import carfield_reg_pkg::*;
  import cheshire_pkg::*;
  import safety_island_pkg::*;
  import tlul_ot_pkg::*;
#(
  parameter cheshire_cfg_t Cfg = carfield_pkg::CarfieldCfgDefault,
  parameter int unsigned HypNumPhys  = 2,
  parameter int unsigned HypNumChips = 2,
  parameter type reg_req_t           = logic,
  parameter type reg_rsp_t           = logic
) (
  // host clock
  input   logic                                       host_clk_i,
  // peripheral clock
  input   logic                                       periph_clk_i,
  // accelerator and island clock
  input   logic                                       alt_clk_i,
  // external reference clock for timers (CLINT, islands)
  input   logic                                       rt_clk_i,

  input   logic                                       pwr_on_rst_ni,

  // testmode pin
  input   logic                                       test_mode_i,
  // Cheshire BOOT pins (3 pins)
  input   logic [1:0]                                 boot_mode_i,
  // Cheshire JTAG Interface
  input   logic                                       jtag_tck_i,
  input   logic                                       jtag_trst_ni,
  input   logic                                       jtag_tms_i,
  input   logic                                       jtag_tdi_i,
  output  logic                                       jtag_tdo_o,
  output  logic                                       jtag_tdo_oe_o,
  // Secure Subsystem JTAG Interface
  input   logic                                       jtag_ot_tck_i,
  input   logic                                       jtag_ot_trst_ni,
  input   logic                                       jtag_ot_tms_i,
  input   logic                                       jtag_ot_tdi_i,
  output  logic                                       jtag_ot_tdo_o,
  output  logic                                       jtag_ot_tdo_oe_o,
  // Safety Island JTAG Interface
  input   logic                                       jtag_safety_island_tck_i,
  input   logic                                       jtag_safety_island_trst_ni,
  input   logic                                       jtag_safety_island_tms_i,
  input   logic                                       jtag_safety_island_tdi_i,
  output  logic                                       jtag_safety_island_tdo_o,
  // Secure Subsystem BOOT pins
  input   logic [1:0]                                 bootmode_ot_i,
  // unused by safety island -- tdo pad always out mode
  output  logic                                       jtag_safe_isln_tdo_oe_o,
  // Safety Island BOOT pins
  input   logic [1:0]                                 bootmode_safe_isln_i,
  // Host UART Interface
  output logic                                        uart_tx_o,
  input  logic                                        uart_rx_i,
  // Secure Subsystem UART Interface
  output logic                                        uart_ot_tx_o,
  input  logic                                        uart_ot_rx_i,
  // Host I2C Interface pins
  output logic                                        i2c_sda_o,
  input  logic                                        i2c_sda_i,
  output logic                                        i2c_sda_en_o,
  output logic                                        i2c_scl_o,
  input  logic                                        i2c_scl_i,
  output logic                                        i2c_scl_en_o,
  // Host SPI Master Interface
  output logic                                        spih_sck_o,
  output logic                                        spih_sck_en_o,
  output logic [SpihNumCs-1:0]                        spih_csb_o,
  output logic [SpihNumCs-1:0]                        spih_csb_en_o,
  output logic [ 3:0]                                 spih_sd_o,
  output logic [ 3:0]                                 spih_sd_en_o,
  input  logic [ 3:0]                                 spih_sd_i,
  // Secure Subsystem QSPI Master Interface
  output logic                                        spih_ot_sck_o,
  output logic                                        spih_ot_sck_en_o,
  output logic                                        spih_ot_csb_o,
  output logic                                        spih_ot_csb_en_o,
  output logic [ 3:0]                                 spih_ot_sd_o,
  output logic [ 3:0]                                 spih_ot_sd_en_o,
  input  logic [ 3:0]                                 spih_ot_sd_i,
  // ETHERNET interface
  input  logic                                        eth_rxck_i,
  input  logic                                        eth_rxctl_i,
  input  logic  [ 3:0]                                eth_rxd_i,
  input  logic                                        eth_md_i,
  output logic                                        eth_txck_o,
  output logic                                        eth_txctl_o,
  output logic  [ 3:0]                                eth_txd_o,
  output logic                                        eth_md_o,
  output logic                                        eth_md_oe,
  output logic                                        eth_mdc_o,
  output logic                                        eth_rst_n_o,
  // CAN interface
  input  logic                                        can_rx_i,
  output logic                                        can_tx_o,
  // GPIOs
  input  logic [31:0]                                 gpio_i,
  output logic [31:0]                                 gpio_o,
  output logic [31:0]                                 gpio_en_o,
  // Serial link interface
  input  logic [SlinkNumChan-1:0]                     slink_rcv_clk_i,
  output logic [SlinkNumChan-1:0]                     slink_rcv_clk_o,
  input  logic [SlinkNumChan-1:0][SlinkNumLanes-1:0]  slink_i,
  output logic [SlinkNumChan-1:0][SlinkNumLanes-1:0]  slink_o,
  // HyperBus clocks
  input  logic                                        hyp_clk_phy_i,
  input  logic                                        hyp_rst_phy_ni,
  // HyperBus interface
  output logic [HypNumPhys-1:0][HypNumChips-1:0]      hyper_cs_no,
  output logic [HypNumPhys-1:0]                       hyper_ck_o,
  output logic [HypNumPhys-1:0]                       hyper_ck_no,
  output logic [HypNumPhys-1:0]                       hyper_rwds_o,
  input  logic [HypNumPhys-1:0]                       hyper_rwds_i,
  output logic [HypNumPhys-1:0]                       hyper_rwds_oe_o,
  input  logic [HypNumPhys-1:0][7:0]                  hyper_dq_i,
  output logic [HypNumPhys-1:0][7:0]                  hyper_dq_o,
  output logic [HypNumPhys-1:0]                       hyper_dq_oe_o,
  output logic [HypNumPhys-1:0]                       hyper_reset_no,
  // PLL configuration
  output reg_req_t                                    pll_cfg_reg_req_o,
  input  reg_rsp_t                                    pll_cfg_reg_rsp_i,
  // padframe configuration
  output reg_req_t                                    padframe_cfg_reg_req_o,
  input  reg_rsp_t                                    padframe_cfg_reg_rsp_i
);

/*********************************
* General parameters and defines *
**********************************/
`CHESHIRE_TYPEDEF_ALL(carfield_, Cfg)

// Generate indices and get maps for all ports
localparam axi_in_t   AxiIn   = gen_axi_in(Cfg);
localparam axi_out_t  AxiOut  = gen_axi_out(Cfg);

/*****************************/
/* Wide Parameters: A48, D32 */
/*****************************/
localparam int unsigned AxiStrbWidth  = Cfg.AxiDataWidth / 8;
localparam int unsigned AxiSlvIdWidth = Cfg.AxiMstIdWidth + $clog2(AxiIn.num_in);

// Wide AXI types
typedef logic [       Cfg.AddrWidth-1:0] car_addrw_t;
typedef logic [    Cfg.AxiDataWidth-1:0] car_dataw_t;
typedef logic [(Cfg.AxiDataWidth)/8-1:0] car_strb_t;
typedef logic [    Cfg.AxiUserWidth-1:0] car_usr_t;
typedef logic [       AxiSlvIdWidth-1:0] car_slv_id_t;

// Slave CDC parameters
localparam int unsigned CarfieldAxiSlvAwWidth =
                        (2**LogDepth)*axi_pkg::aw_width(Cfg.AddrWidth   ,
                                                        AxiSlvIdWidth   ,
                                                        Cfg.AxiUserWidth);
localparam int unsigned CarfieldAxiSlvWWidth  =
                        (2**LogDepth)*axi_pkg::w_width(Cfg.AxiDataWidth,
                                                       Cfg.AxiUserWidth);
localparam int unsigned CarfieldAxiSlvBWidth  =
                        (2**LogDepth)*axi_pkg::b_width(AxiSlvIdWidth   ,
                                                       Cfg.AxiUserWidth);
localparam int unsigned CarfieldAxiSlvArWidth =
                        (2**LogDepth)*axi_pkg::ar_width(Cfg.AddrWidth   ,
                                                        AxiSlvIdWidth   ,
                                                        Cfg.AxiUserWidth);
localparam int unsigned CarfieldAxiSlvRWidth  =
                        (2**LogDepth)*axi_pkg::r_width(Cfg.AxiDataWidth,
                                                       AxiSlvIdWidth   ,
                                                       Cfg.AxiUserWidth);

// Master CDC parameters
localparam int unsigned CarfieldAxiMstAwWidth =
                        (2**LogDepth)*axi_pkg::aw_width(Cfg.AddrWidth    ,
                                                        Cfg.AxiMstIdWidth,
                                                        Cfg.AxiUserWidth );
localparam int unsigned CarfieldAxiMstWWidth  =
                        (2**LogDepth)*axi_pkg::w_width(Cfg.AxiDataWidth,
                                                       Cfg.AxiUserWidth);
localparam int unsigned CarfieldAxiMstBWidth  =
                        (2**LogDepth)*axi_pkg::b_width(Cfg.AxiMstIdWidth,
                                                      Cfg.AxiUserWidth  );
localparam int unsigned CarfieldAxiMstArWidth =
                        (2**LogDepth)*axi_pkg::ar_width(Cfg.AddrWidth    ,
                                                        Cfg.AxiMstIdWidth,
                                                        Cfg.AxiUserWidth );
localparam int unsigned CarfieldAxiMstRWidth  =
                        (2**LogDepth)*axi_pkg::r_width(Cfg.AxiDataWidth ,
                                                       Cfg.AxiMstIdWidth,
                                                       Cfg.AxiUserWidth );
// Integer Cluster Slave CDC Parameters
localparam int unsigned IntClusterAxiSlvAwWidth =
                        (2**LogDepth)*axi_pkg::aw_width(Cfg.AddrWidth         ,
                                                        IntClusterAxiIdInWidth,
                                                        Cfg.AxiUserWidth      );
localparam int unsigned IntClusterAxiSlvWWidth  =
                        (2**LogDepth)*axi_pkg::w_width(Cfg.AxiDataWidth,
                                                       Cfg.AxiUserWidth);
localparam int unsigned IntClusterAxiSlvBWidth  =
                        (2**LogDepth)*axi_pkg::b_width(IntClusterAxiIdInWidth,
                                                       Cfg.AxiUserWidth      );
localparam int unsigned IntClusterAxiSlvArWidth =
                        (2**LogDepth)*axi_pkg::ar_width(Cfg.AddrWidth         ,
                                                        IntClusterAxiIdInWidth,
                                                        Cfg.AxiUserWidth      );
localparam int unsigned IntClusterAxiSlvRWidth  =
                        (2**LogDepth)*axi_pkg::r_width(Cfg.AxiDataWidth      ,
                                                       IntClusterAxiIdInWidth,
                                                       Cfg.AxiUserWidth      );
// Integer Cluster Master CDC Parameters
localparam int unsigned IntClusterAxiMstAwWidth =
                        (2**LogDepth)*axi_pkg::aw_width(Cfg.AddrWidth          ,
                                                        IntClusterAxiIdOutWidth,
                                                        Cfg.AxiUserWidth       );
localparam int unsigned IntClusterAxiMstWWidth  =
                        (2**LogDepth)*axi_pkg::w_width(Cfg.AxiDataWidth,
                                                       Cfg.AxiUserWidth);
localparam int unsigned IntClusterAxiMstBWidth  =
                        (2**LogDepth)*axi_pkg::b_width(IntClusterAxiIdOutWidth,
                                                      Cfg.AxiUserWidth        );
localparam int unsigned IntClusterAxiMstArWidth =
                        (2**LogDepth)*axi_pkg::ar_width(Cfg.AddrWidth          ,
                                                        IntClusterAxiIdOutWidth,
                                                        Cfg.AxiUserWidth       );
localparam int unsigned IntClusterAxiMstRWidth  =
                        (2**LogDepth)*axi_pkg::r_width(Cfg.AxiDataWidth       ,
                                                       IntClusterAxiIdOutWidth,
                                                       Cfg.AxiUserWidth       );

// Slave and Master Sides
// verilog_lint: waive-start line-length
`AXI_TYPEDEF_ALL_CT(axi_intcluster_slv, axi_intcluster_slv_req_t, axi_intcluster_slv_rsp_t, car_addrw_t, intclust_idin_t, car_dataw_t, car_strb_t, car_usr_t)
`AXI_TYPEDEF_ALL_CT(axi_intcluster_mst, axi_intcluster_mst_req_t, axi_intcluster_mst_rsp_t, car_addrw_t, intclust_idout_t, car_dataw_t, car_strb_t, car_usr_t)
// verilog_lint: waive-stop line-length

// Local DRAM buses and parameter
carfield_reg_req_t [Cfg.RegExtNumSlv-1:0] ext_reg_req;
carfield_reg_rsp_t [Cfg.RegExtNumSlv-1:0] ext_reg_rsp;

localparam int unsigned LlcIdWidth = Cfg.AxiMstIdWidth   +
                                     $clog2(AxiIn.num_in)+
                                     Cfg.LlcNotBypass    ;
localparam int unsigned LlcArWidth = (2**LogDepth)*
                                     axi_pkg::ar_width(Cfg.AddrWidth   ,
                                                       LlcIdWidth      ,
                                                       Cfg.AxiUserWidth);
localparam int unsigned LlcAwWidth = (2**LogDepth)*
                                      axi_pkg::aw_width(Cfg.AddrWidth  ,
                                                       LlcIdWidth      ,
                                                       Cfg.AxiUserWidth);
localparam int unsigned LlcBWidth  = (2**LogDepth)*
                                      axi_pkg::b_width(LlcIdWidth     ,
                                                       Cfg.AxiUserWidth);
localparam int unsigned LlcRWidth  = (2**LogDepth)*
                                      axi_pkg::r_width(Cfg.AxiDataWidth,
                                                      LlcIdWidth      ,
                                                      Cfg.AxiUserWidth);
localparam int unsigned LlcWWidth  = (2**LogDepth)*
                                      axi_pkg::w_width(Cfg.AxiDataWidth,
                                                       Cfg.AxiUserWidth );

logic hyper_isolate_req, hyper_isolated_rsp;
logic [iomsb(Cfg.AxiExtNumSlv):0] slave_isolate_req, slave_isolated_rsp, slave_isolated;
logic [iomsb(Cfg.AxiExtNumMst):0] master_isolated_rsp;

logic [LlcArWidth-1:0] llc_ar_data;
logic [    LogDepth:0] llc_ar_wptr;
logic [    LogDepth:0] llc_ar_rptr;
logic [LlcAwWidth-1:0] llc_aw_data;
logic [    LogDepth:0] llc_aw_wptr;
logic [    LogDepth:0] llc_aw_rptr;
logic [ LlcBWidth-1:0] llc_b_data;
logic [    LogDepth:0] llc_b_wptr;
logic [    LogDepth:0] llc_b_rptr;
logic [ LlcRWidth-1:0] llc_r_data;
logic [    LogDepth:0] llc_r_wptr;
logic [    LogDepth:0] llc_r_rptr;
logic [ LlcWWidth-1:0] llc_w_data;
logic [    LogDepth:0] llc_w_wptr;
logic [    LogDepth:0] llc_w_rptr;

// All AXI Slaves (except the Integer Cluster)
logic [iomsb(Cfg.AxiExtNumSlv-1):0][CarfieldAxiSlvAwWidth-1:0] axi_slv_ext_aw_data;
logic [iomsb(Cfg.AxiExtNumSlv-1):0][               LogDepth:0] axi_slv_ext_aw_wptr;
logic [iomsb(Cfg.AxiExtNumSlv-1):0][               LogDepth:0] axi_slv_ext_aw_rptr;
logic [iomsb(Cfg.AxiExtNumSlv-1):0][ CarfieldAxiSlvWWidth-1:0] axi_slv_ext_w_data ;
logic [iomsb(Cfg.AxiExtNumSlv-1):0][               LogDepth:0] axi_slv_ext_w_wptr ;
logic [iomsb(Cfg.AxiExtNumSlv-1):0][               LogDepth:0] axi_slv_ext_w_rptr ;
logic [iomsb(Cfg.AxiExtNumSlv-1):0][ CarfieldAxiSlvBWidth-1:0] axi_slv_ext_b_data ;
logic [iomsb(Cfg.AxiExtNumSlv-1):0][               LogDepth:0] axi_slv_ext_b_wptr ;
logic [iomsb(Cfg.AxiExtNumSlv-1):0][               LogDepth:0] axi_slv_ext_b_rptr ;
logic [iomsb(Cfg.AxiExtNumSlv-1):0][CarfieldAxiSlvArWidth-1:0] axi_slv_ext_ar_data;
logic [iomsb(Cfg.AxiExtNumSlv-1):0][               LogDepth:0] axi_slv_ext_ar_wptr;
logic [iomsb(Cfg.AxiExtNumSlv-1):0][               LogDepth:0] axi_slv_ext_ar_rptr;
logic [iomsb(Cfg.AxiExtNumSlv-1):0][ CarfieldAxiSlvRWidth-1:0] axi_slv_ext_r_data ;
logic [iomsb(Cfg.AxiExtNumSlv-1):0][               LogDepth:0] axi_slv_ext_r_wptr ;
logic [iomsb(Cfg.AxiExtNumSlv-1):0][               LogDepth:0] axi_slv_ext_r_rptr ;

// All AXI Slaves (except the Integer Cluster)
logic [iomsb(Cfg.AxiExtNumMst-1):0][CarfieldAxiMstAwWidth-1:0] axi_mst_ext_aw_data;
logic [iomsb(Cfg.AxiExtNumMst-1):0][               LogDepth:0] axi_mst_ext_aw_wptr;
logic [iomsb(Cfg.AxiExtNumMst-1):0][               LogDepth:0] axi_mst_ext_aw_rptr;
logic [iomsb(Cfg.AxiExtNumMst-1):0][ CarfieldAxiMstWWidth-1:0] axi_mst_ext_w_data ;
logic [iomsb(Cfg.AxiExtNumMst-1):0][               LogDepth:0] axi_mst_ext_w_wptr ;
logic [iomsb(Cfg.AxiExtNumMst-1):0][               LogDepth:0] axi_mst_ext_w_rptr ;
logic [iomsb(Cfg.AxiExtNumMst-1):0][ CarfieldAxiMstBWidth-1:0] axi_mst_ext_b_data ;
logic [iomsb(Cfg.AxiExtNumMst-1):0][               LogDepth:0] axi_mst_ext_b_wptr ;
logic [iomsb(Cfg.AxiExtNumMst-1):0][               LogDepth:0] axi_mst_ext_b_rptr ;
logic [iomsb(Cfg.AxiExtNumMst-1):0][CarfieldAxiMstArWidth-1:0] axi_mst_ext_ar_data;
logic [iomsb(Cfg.AxiExtNumMst-1):0][               LogDepth:0] axi_mst_ext_ar_wptr;
logic [iomsb(Cfg.AxiExtNumMst-1):0][               LogDepth:0] axi_mst_ext_ar_rptr;
logic [iomsb(Cfg.AxiExtNumMst-1):0][ CarfieldAxiMstRWidth-1:0] axi_mst_ext_r_data ;
logic [iomsb(Cfg.AxiExtNumMst-1):0][               LogDepth:0] axi_mst_ext_r_wptr ;
logic [iomsb(Cfg.AxiExtNumMst-1):0][               LogDepth:0] axi_mst_ext_r_rptr ;

// Integer Cluster Slave Bus
logic [IntClusterAxiSlvAwWidth-1:0] axi_slv_intcluster_aw_data;
logic [                 LogDepth:0] axi_slv_intcluster_aw_wptr;
logic [                 LogDepth:0] axi_slv_intcluster_aw_rptr;
logic [ IntClusterAxiSlvWWidth-1:0] axi_slv_intcluster_w_data ;
logic [                 LogDepth:0] axi_slv_intcluster_w_wptr ;
logic [                 LogDepth:0] axi_slv_intcluster_w_rptr ;
logic [ IntClusterAxiSlvBWidth-1:0] axi_slv_intcluster_b_data ;
logic [                 LogDepth:0] axi_slv_intcluster_b_wptr ;
logic [                 LogDepth:0] axi_slv_intcluster_b_rptr ;
logic [IntClusterAxiSlvArWidth-1:0] axi_slv_intcluster_ar_data;
logic [                 LogDepth:0] axi_slv_intcluster_ar_wptr;
logic [                 LogDepth:0] axi_slv_intcluster_ar_rptr;
logic [ IntClusterAxiSlvRWidth-1:0] axi_slv_intcluster_r_data ;
logic [                 LogDepth:0] axi_slv_intcluster_r_wptr ;
logic [                 LogDepth:0] axi_slv_intcluster_r_rptr ;

// Integer Cluster Master Bus
logic [IntClusterAxiMstAwWidth-1:0] axi_mst_intcluster_aw_data;
logic [                 LogDepth:0] axi_mst_intcluster_aw_wptr;
logic [                 LogDepth:0] axi_mst_intcluster_aw_rptr;
logic [ IntClusterAxiMstWWidth-1:0] axi_mst_intcluster_w_data ;
logic [                 LogDepth:0] axi_mst_intcluster_w_wptr ;
logic [                 LogDepth:0] axi_mst_intcluster_w_rptr ;
logic [ IntClusterAxiMstBWidth-1:0] axi_mst_intcluster_b_data ;
logic [                 LogDepth:0] axi_mst_intcluster_b_wptr ;
logic [                 LogDepth:0] axi_mst_intcluster_b_rptr ;
logic [IntClusterAxiMstArWidth-1:0] axi_mst_intcluster_ar_data;
logic [                 LogDepth:0] axi_mst_intcluster_ar_wptr;
logic [                 LogDepth:0] axi_mst_intcluster_ar_rptr;
logic [ IntClusterAxiMstRWidth-1:0] axi_mst_intcluster_r_data ;
logic [                 LogDepth:0] axi_mst_intcluster_r_wptr ;
logic [                 LogDepth:0] axi_mst_intcluster_r_rptr ;

// irq for Secure Subsytem and Cheshire
logic        ibex_mbox_irq;
logic        ches_mbox_irq;

// soc reg signals
carfield_reg2hw_t car_regs_reg2hw;
carfield_hw2reg_t car_regs_hw2reg;

// Clocking and reset strategy
// We have three clock domains
// host (host_clk_i), periph (periph_clk_i) and accelerators (alt_clk_i)
//
// and six reset domains
// host           (contained in host clock domain)
// periph         (contained in periph clock domain, sw reset 0)
// safety         (contained in accelerator clock domain, sw reset 1)
// security       (contained in accelerator clock domain, sw reset 2)
// pulp_cluster   (contained in accelerator clock domain, sw reset 3)
// spatz_cluster  (contained in accelerator clock domain, sw reset 4)

logic    periph_rst_n;
logic    safety_rst_n;
logic    security_rst_n;
logic    pulp_rst_n;
logic    spatz_rst_n;

logic    host_pwr_on_rst_n;
logic    periph_pwr_on_rst_n;
logic    safety_pwr_on_rst_n;
logic    security_pwr_on_rst_n;
logic    pulp_pwr_on_rst_n;
logic    spatz_pwr_on_rst_n;

// Reset generation for power-on reset for host domain. For the other domain we
// get this from carfield_rstgen
rstgen i_host_rstgen (
  .clk_i  (host_clk_i),
  .rst_ni (pwr_on_rst_ni),
  .test_mode_i,
  .rst_no (host_pwr_on_rst_n),
  .init_no () // TODO: connect ?
);


// Reset generation combining software and power-on reset. These are software
// controllable resets. The matching of clock and reset domain is according to
// the description above

// Note that each accelerator has two resets: One for the combined
// software/power-on reset and a power-on reset only
logic [4:0] pwr_on_rsts_n;
logic [4:0] rsts_n;

carfield_rstgen #(
  .NumRstDomains (5)
) i_carfield_rstgen (
  .clks_i({periph_clk_i, alt_clk_i, alt_clk_i, alt_clk_i, alt_clk_i}),
  .pwr_on_rst_ni,
  .sw_rsts_ni(~{car_regs_reg2hw.periph_rst.q,
                car_regs_reg2hw.safety_island_rst.q,
                car_regs_reg2hw.security_island_rst.q,
                car_regs_reg2hw.pulp_cluster_rst.q,
                car_regs_reg2hw.spatz_cluster_rst.q}),
  .test_mode_i,
  .rsts_no(rsts_n),
  .pwr_on_rsts_no(pwr_on_rsts_n),
  .inits_no() // TODO: connect ?
);

assign periph_rst_n = rsts_n[0];
assign safety_rst_n = rsts_n[1];
assign security_rst_n = rsts_n[2];
assign pulp_rst_n = rsts_n[3];
assign spatz_rst_n = rsts_n[4];

assign periph_pwr_on_rst_n = pwr_on_rsts_n[0];
assign safety_pwr_on_rst_n = pwr_on_rsts_n[1];
assign security_pwr_on_rst_n = pwr_on_rsts_n[2];
assign pulp_pwr_on_rst_n = pwr_on_rsts_n[3];
assign spatz_pwr_on_rst_n = pwr_on_rsts_n[4];

//
// Carfield Control and Status registers
//

carfield_reg_top #(
  .reg_req_t(carfield_reg_req_t),
  .reg_rsp_t(carfield_reg_rsp_t)
) i_carfield_reg_top (
  .clk_i (host_clk_i),
  .rst_ni (host_pwr_on_rst_n),
  .reg_req_i(ext_reg_req[CarRegsIdx]),
  .reg_rsp_o(ext_reg_rsp[CarRegsIdx]),
  .reg2hw (car_regs_reg2hw),
  .hw2reg (car_regs_hw2reg),
  .devmode_i (1'b1)
);

// TODO: these still need to be connected but can't at this point in time since RTL is missing
// car_regs_reg2hw.host_isolate // dummy
// car_regs_reg2hw.periph_isolate
// car_regs_reg2hw.security_island_isolate

// car_regs_reg2hw.host_fetch_enable // dummy (?)
// car_regs_reg2hw.spatz_cluster_fetch_enable

// car_regs_reg2hw.host_boot_addr // dummy (?)
// car_regs_reg2hw.safety_island_boot_addr
// car_regs_reg2hw.security_island_boot_addr
// car_regs_reg2hw.pulp_cluster_boot_addr
// car_regs_reg2hw.spatz_cluster_boot_addr

// car_regs_reg2hw.l2_sram_config0...x

// car_regs_hw2reg.host_isolate_status // dummy
// car_regs_hw2reg.periph_isolate_status
// car_regs_hw2reg.security_island_isolate_status


// Temporary assign
// TODO: add ethernet and hyperbus isolate?
assign hyper_isolate_req = '0;


//
// Isolate and Isolate status
//
assign slave_isolate_req[SafetyIslandSlvIdx] = car_regs_reg2hw.safety_island_isolate.q;
assign slave_isolate_req[IntClusterSlvIdx]   = car_regs_reg2hw.pulp_cluster_isolate.q;
assign slave_isolate_req[FPClusterSlvIdx]    = car_regs_reg2hw.spatz_cluster_isolate.q;
assign slave_isolate_req[L2Port1SlvIdx]      = 'd0;
assign slave_isolate_req[L2Port2SlvIdx]      = 'd0;
assign slave_isolate_req[OTMailboxSlvIdx]    = 'd0;
assign slave_isolate_req[EthernetSlvIdx]     = 'd0;
assign slave_isolate_req[PeriphsSlvIdx]      = 'd0;

always_comb begin: assign_isolated_responses
  slave_isolated = '0;
  for (int i = 0; i < Cfg.AxiExtNumSlv; i++) begin
    if (i == SafetyIslandSlvIdx)
      slave_isolated [i] = slave_isolated_rsp [i] & master_isolated_rsp [SafetyIslandMstIdx];
    else if (i == IntClusterSlvIdx)
      slave_isolated [i] = slave_isolated_rsp [i] & master_isolated_rsp [IntClusterMstIdx];
    else
      slave_isolated [i] = slave_isolated_rsp [i];
  end
end

assign car_regs_hw2reg.safety_island_isolate_status.d = slave_isolated[SafetyIslandSlvIdx];
assign car_regs_hw2reg.safety_island_isolate_status.de = 1'b1;

assign car_regs_hw2reg.pulp_cluster_isolate_status.d = slave_isolated[IntClusterSlvIdx];
assign car_regs_hw2reg.pulp_cluster_isolate_status.de = 1'b1;

assign car_regs_hw2reg.spatz_cluster_isolate_status.d = slave_isolated[FPClusterSlvIdx];
assign car_regs_hw2reg.spatz_cluster_isolate_status.de = 1'b1;

// hyperbus reg req/rsp
carfield_a32_d32_reg_req_t reg_hyper_req;
carfield_a32_d32_reg_rsp_t reg_hyper_rsp;

// wdt reg req/rsp
carfield_a32_d32_reg_req_t reg_wdt_req;
carfield_a32_d32_reg_rsp_t reg_wdt_rsp;

/***************
* Carfield IPs *
***************/
// Cheshire SoC
// Host Clock Domain
cheshire_wrap #(
  .Cfg                            ( Cfg                          ),
  .ExtHartinfo                    ( '0                           ),
  .cheshire_axi_ext_llc_ar_chan_t ( carfield_axi_llc_ar_chan_t   ),
  .cheshire_axi_ext_llc_aw_chan_t ( carfield_axi_llc_aw_chan_t   ),
  .cheshire_axi_ext_llc_b_chan_t  ( carfield_axi_llc_b_chan_t    ),
  .cheshire_axi_ext_llc_r_chan_t  ( carfield_axi_llc_r_chan_t    ),
  .cheshire_axi_ext_llc_w_chan_t  ( carfield_axi_llc_w_chan_t    ),
  .cheshire_axi_ext_llc_req_t     ( carfield_axi_llc_req_t       ),
  .cheshire_axi_ext_llc_rsp_t     ( carfield_axi_llc_rsp_t       ),
  .cheshire_axi_ext_mst_ar_chan_t ( carfield_axi_mst_ar_chan_t   ),
  .cheshire_axi_ext_mst_aw_chan_t ( carfield_axi_mst_aw_chan_t   ),
  .cheshire_axi_ext_mst_b_chan_t  ( carfield_axi_mst_b_chan_t    ),
  .cheshire_axi_ext_mst_r_chan_t  ( carfield_axi_mst_r_chan_t    ),
  .cheshire_axi_ext_mst_w_chan_t  ( carfield_axi_mst_w_chan_t    ),
  .cheshire_axi_ext_mst_req_t     ( carfield_axi_mst_req_t       ),
  .cheshire_axi_ext_mst_rsp_t     ( carfield_axi_mst_rsp_t       ),
  .cheshire_axi_ext_slv_ar_chan_t ( carfield_axi_slv_ar_chan_t   ),
  .cheshire_axi_ext_slv_aw_chan_t ( carfield_axi_slv_aw_chan_t   ),
  .cheshire_axi_ext_slv_b_chan_t  ( carfield_axi_slv_b_chan_t    ),
  .cheshire_axi_ext_slv_r_chan_t  ( carfield_axi_slv_r_chan_t    ),
  .cheshire_axi_ext_slv_w_chan_t  ( carfield_axi_slv_w_chan_t    ),
  .cheshire_axi_ext_slv_req_t     ( carfield_axi_slv_req_t       ),
  .cheshire_axi_ext_slv_rsp_t     ( carfield_axi_slv_rsp_t       ),
  .axi_intcluster_slv_ar_chan_t   ( axi_intcluster_slv_ar_chan_t ),
  .axi_intcluster_slv_aw_chan_t   ( axi_intcluster_slv_aw_chan_t ),
  .axi_intcluster_slv_b_chan_t    ( axi_intcluster_slv_b_chan_t  ),
  .axi_intcluster_slv_r_chan_t    ( axi_intcluster_slv_r_chan_t  ),
  .axi_intcluster_slv_w_chan_t    ( axi_intcluster_slv_w_chan_t  ),
  .axi_intcluster_slv_req_t       ( axi_intcluster_slv_req_t     ),
  .axi_intcluster_slv_rsp_t       ( axi_intcluster_slv_rsp_t     ),
  .axi_intcluster_mst_ar_chan_t   ( axi_intcluster_mst_ar_chan_t ),
  .axi_intcluster_mst_aw_chan_t   ( axi_intcluster_mst_aw_chan_t ),
  .axi_intcluster_mst_b_chan_t    ( axi_intcluster_mst_b_chan_t  ),
  .axi_intcluster_mst_r_chan_t    ( axi_intcluster_mst_r_chan_t  ),
  .axi_intcluster_mst_w_chan_t    ( axi_intcluster_mst_w_chan_t  ),
  .axi_intcluster_mst_req_t       ( axi_intcluster_mst_req_t     ),
  .axi_intcluster_mst_rsp_t       ( axi_intcluster_mst_rsp_t     ),
  .cheshire_reg_ext_req_t         ( carfield_reg_req_t           ),
  .cheshire_reg_ext_rsp_t         ( carfield_reg_rsp_t           ),
  .LogDepth                       ( LogDepth                     ),
  .AxiIn                          ( AxiIn                        ),
  .AxiOut                         ( AxiOut                       )
) i_cheshire_wrap                 (
  .clk_i              ( host_clk_i         ),
  .rst_ni             ( host_pwr_on_rst_n  ),
  .test_mode_i                    ,
  .boot_mode_i                    ,
  .rtc_i              ( rt_clk_i          ),
  // External AXI LLC (DRAM) port
  .axi_llc_isolate_i  ( hyper_isolate_req  ),
  .axi_llc_isolated_o ( hyper_isolated_rsp ),
  .llc_mst_ar_data_o  ( llc_ar_data        ),
  .llc_mst_ar_wptr_o  ( llc_ar_wptr        ),
  .llc_mst_ar_rptr_i  ( llc_ar_rptr        ),
  .llc_mst_aw_data_o  ( llc_aw_data        ),
  .llc_mst_aw_wptr_o  ( llc_aw_wptr        ),
  .llc_mst_aw_rptr_i  ( llc_aw_rptr        ),
  .llc_mst_b_data_i   ( llc_b_data         ),
  .llc_mst_b_wptr_i   ( llc_b_wptr         ),
  .llc_mst_b_rptr_o   ( llc_b_rptr         ),
  .llc_mst_r_data_i   ( llc_r_data         ),
  .llc_mst_r_wptr_i   ( llc_r_wptr         ),
  .llc_mst_r_rptr_o   ( llc_r_rptr         ),
  .llc_mst_w_data_o   ( llc_w_data         ),
  .llc_mst_w_wptr_o   ( llc_w_wptr         ),
  .llc_mst_w_rptr_i   ( llc_w_rptr         ),
  // External AXI slave devices (except the Integer Cluster)
  .axi_ext_slv_isolate_i  ( slave_isolate_req   ),
  .axi_ext_slv_isolated_o ( slave_isolated_rsp  ),
  .axi_ext_slv_ar_data_o  ( axi_slv_ext_ar_data ),
  .axi_ext_slv_ar_wptr_o  ( axi_slv_ext_ar_wptr ),
  .axi_ext_slv_ar_rptr_i  ( axi_slv_ext_ar_rptr ),
  .axi_ext_slv_aw_data_o  ( axi_slv_ext_aw_data ),
  .axi_ext_slv_aw_wptr_o  ( axi_slv_ext_aw_wptr ),
  .axi_ext_slv_aw_rptr_i  ( axi_slv_ext_aw_rptr ),
  .axi_ext_slv_b_data_i   ( axi_slv_ext_b_data  ),
  .axi_ext_slv_b_wptr_i   ( axi_slv_ext_b_wptr  ),
  .axi_ext_slv_b_rptr_o   ( axi_slv_ext_b_rptr  ),
  .axi_ext_slv_r_data_i   ( axi_slv_ext_r_data  ),
  .axi_ext_slv_r_wptr_i   ( axi_slv_ext_r_wptr  ),
  .axi_ext_slv_r_rptr_o   ( axi_slv_ext_r_rptr  ),
  .axi_ext_slv_w_data_o   ( axi_slv_ext_w_data  ),
  .axi_ext_slv_w_wptr_o   ( axi_slv_ext_w_wptr  ),
  .axi_ext_slv_w_rptr_i   ( axi_slv_ext_w_rptr  ),
  // External AXI master devices (except the Integer Cluster)
  .axi_ext_mst_ar_data_i ( axi_mst_ext_ar_data ),
  .axi_ext_mst_ar_wptr_i ( axi_mst_ext_ar_wptr ),
  .axi_ext_mst_ar_rptr_o ( axi_mst_ext_ar_rptr ),
  .axi_ext_mst_aw_data_i ( axi_mst_ext_aw_data ),
  .axi_ext_mst_aw_wptr_i ( axi_mst_ext_aw_wptr ),
  .axi_ext_mst_aw_rptr_o ( axi_mst_ext_aw_rptr ),
  .axi_ext_mst_b_data_o  ( axi_mst_ext_b_data  ),
  .axi_ext_mst_b_wptr_o  ( axi_mst_ext_b_wptr  ),
  .axi_ext_mst_b_rptr_i  ( axi_mst_ext_b_rptr  ),
  .axi_ext_mst_r_data_o  ( axi_mst_ext_r_data  ),
  .axi_ext_mst_r_wptr_o  ( axi_mst_ext_r_wptr  ),
  .axi_ext_mst_r_rptr_i  ( axi_mst_ext_r_rptr  ),
  .axi_ext_mst_w_data_i  ( axi_mst_ext_w_data  ),
  .axi_ext_mst_w_wptr_i  ( axi_mst_ext_w_wptr  ),
  .axi_ext_mst_w_rptr_o  ( axi_mst_ext_w_rptr  ),
  // Integer Cluster Slave Port
  .axi_slv_intcluster_aw_data_o ( axi_slv_intcluster_aw_data ),
  .axi_slv_intcluster_aw_wptr_o ( axi_slv_intcluster_aw_wptr ),
  .axi_slv_intcluster_aw_rptr_i ( axi_slv_intcluster_aw_rptr ),
  .axi_slv_intcluster_w_data_o  ( axi_slv_intcluster_w_data  ),
  .axi_slv_intcluster_w_wptr_o  ( axi_slv_intcluster_w_wptr  ),
  .axi_slv_intcluster_w_rptr_i  ( axi_slv_intcluster_w_rptr  ),
  .axi_slv_intcluster_b_data_i  ( axi_slv_intcluster_b_data  ),
  .axi_slv_intcluster_b_wptr_i  ( axi_slv_intcluster_b_wptr  ),
  .axi_slv_intcluster_b_rptr_o  ( axi_slv_intcluster_b_rptr  ),
  .axi_slv_intcluster_ar_data_o ( axi_slv_intcluster_ar_data ),
  .axi_slv_intcluster_ar_wptr_o ( axi_slv_intcluster_ar_wptr ),
  .axi_slv_intcluster_ar_rptr_i ( axi_slv_intcluster_ar_rptr ),
  .axi_slv_intcluster_r_data_i  ( axi_slv_intcluster_r_data  ),
  .axi_slv_intcluster_r_wptr_i  ( axi_slv_intcluster_r_wptr  ),
  .axi_slv_intcluster_r_rptr_o  ( axi_slv_intcluster_r_rptr  ),
  // Integer Cluster Slave Port
  .axi_mst_intcluster_aw_data_i ( axi_mst_intcluster_aw_data ),
  .axi_mst_intcluster_aw_wptr_i ( axi_mst_intcluster_aw_wptr ),
  .axi_mst_intcluster_aw_rptr_o ( axi_mst_intcluster_aw_rptr ),
  .axi_mst_intcluster_w_data_i  ( axi_mst_intcluster_w_data  ),
  .axi_mst_intcluster_w_wptr_i  ( axi_mst_intcluster_w_wptr  ),
  .axi_mst_intcluster_w_rptr_o  ( axi_mst_intcluster_w_rptr  ),
  .axi_mst_intcluster_b_data_o  ( axi_mst_intcluster_b_data  ),
  .axi_mst_intcluster_b_wptr_o  ( axi_mst_intcluster_b_wptr  ),
  .axi_mst_intcluster_b_rptr_i  ( axi_mst_intcluster_b_rptr  ),
  .axi_mst_intcluster_ar_data_i ( axi_mst_intcluster_ar_data ),
  .axi_mst_intcluster_ar_wptr_i ( axi_mst_intcluster_ar_wptr ),
  .axi_mst_intcluster_ar_rptr_o ( axi_mst_intcluster_ar_rptr ),
  .axi_mst_intcluster_r_data_o  ( axi_mst_intcluster_r_data  ),
  .axi_mst_intcluster_r_wptr_o  ( axi_mst_intcluster_r_wptr  ),
  .axi_mst_intcluster_r_rptr_i  ( axi_mst_intcluster_r_rptr  ),
  // External reg demux slaves
  .reg_ext_slv_req_o ( ext_reg_req     ),
  .reg_ext_slv_rsp_i ( ext_reg_rsp     ),
  // Interrupts from external devices
  .intr_ext_i        ( ches_mbox_irq   ),
  // Interrupts to external harts
  .meip_ext_o        (           ),
  .seip_ext_o        (           ),
  .mtip_ext_o        (           ),
  .msip_ext_o        (           ),
  // Debug interface to external harts
  .dbg_active_o      (           ),
  .dbg_ext_req_o     (           ),
  .dbg_ext_unavail_i ( '0        ),
  // JTAG interface
  .jtag_tck_i                     ,
  .jtag_trst_ni                   ,
  .jtag_tms_i                     ,
  .jtag_tdi_i                     ,
  .jtag_tdo_o                     ,
  .jtag_tdo_oe_o                  ,
  // UART interface
  .uart_tx_o                      ,
  .uart_rx_i                      ,
  // UART Modem flow control
  .uart_rts_no       (            ),
  .uart_dtr_no       (            ),
  .uart_cts_ni       ( '0         ),
  .uart_dsr_ni       ( '0         ),
  .uart_dcd_ni       ( '0         ),
  .uart_rin_ni       ( '0         ),
  // I2C interface
  .i2c_sda_o                      ,
  .i2c_sda_i                      ,
  .i2c_sda_en_o                   ,
  .i2c_scl_o                      ,
  .i2c_scl_i                      ,
  .i2c_scl_en_o                   ,
  // SPI host interface
  .spih_sck_o                     ,
  .spih_sck_en_o                  ,
  .spih_csb_o                     ,
  .spih_csb_en_o                  ,
  .spih_sd_o                      ,
  .spih_sd_en_o                   ,
  .spih_sd_i                      ,
  // GPIO interface
  .gpio_i                         ,
  .gpio_o                         ,
  .gpio_en_o                      ,
  // Serial link interface
  .slink_rcv_clk_i                ,
  .slink_rcv_clk_o                ,
  .slink_i                        ,
  .slink_o                        ,
  // VGA interface
  .vga_hsync_o (                 ),
  .vga_vsync_o (                 ),
  .vga_red_o   (                 ),
  .vga_green_o (                 ),
  .vga_blue_o  (                 )
);

// Hyperbus
hyperbus_wrap      #(
  .NumChips         ( HypNumChips                           ),
  .NumPhys          ( HypNumPhys                            ),
  .IsClockODelayed  ( 1'b0                                  ),
  .AxiAddrWidth     ( Cfg.AddrWidth                         ),
  .AxiDataWidth     ( Cfg.AxiDataWidth                      ),
  .AxiIdWidth       ( LlcIdWidth                            ),
  .AxiUserWidth     ( Cfg.AxiUserWidth                      ),
  .axi_req_t        ( carfield_axi_llc_req_t                ),
  .axi_rsp_t        ( carfield_axi_llc_rsp_t                ),
  .axi_w_chan_t     ( carfield_axi_llc_w_chan_t             ),
  .axi_b_chan_t     ( carfield_axi_llc_b_chan_t             ),
  .axi_ar_chan_t    ( carfield_axi_llc_ar_chan_t            ),
  .axi_r_chan_t     ( carfield_axi_llc_r_chan_t             ),
  .axi_aw_chan_t    ( carfield_axi_llc_aw_chan_t            ),
  .RegAddrWidth     ( AxiNarrowAddrWidth                    ),
  .RegDataWidth     ( AxiNarrowDataWidth                    ),
  .reg_req_t        ( carfield_a32_d32_reg_req_t            ),
  .reg_rsp_t        ( carfield_a32_d32_reg_rsp_t            ),
  .RxFifoLogDepth   ( 32'd2                                 ),
  .TxFifoLogDepth   ( 32'd2                                 ),
  .RstChipBase      ( Cfg.LlcOutRegionStart                 ),
  .RstChipSpace     ( HypNumPhys * HypNumChips * 'h800_0000 ),
  .PhyStartupCycles ( 300 * 200                             ),
  .AxiLogDepth      ( LogDepth                              ),
  .AxiSlaveArWidth  ( LlcArWidth                            ),
  .AxiSlaveAwWidth  ( LlcAwWidth                            ),
  .AxiSlaveBWidth   ( LlcBWidth                             ),
  .AxiSlaveRWidth   ( LlcRWidth                             ),
  .AxiSlaveWWidth   ( LlcWWidth                             ),
  .AxiMaxTrans      ( Cfg.AxiMaxSlvTrans                    )
) i_hyperbus_wrap   (
  .clk_i               ( hyp_clk_phy_i      ),
  .rst_ni              ( hyp_rst_phy_ni     ),
  .test_mode_i         ( test_mode_i        ),
  .axi_slave_ar_data_i ( llc_ar_data        ),
  .axi_slave_ar_wptr_i ( llc_ar_wptr        ),
  .axi_slave_ar_rptr_o ( llc_ar_rptr        ),
  .axi_slave_aw_data_i ( llc_aw_data        ),
  .axi_slave_aw_wptr_i ( llc_aw_wptr        ),
  .axi_slave_aw_rptr_o ( llc_aw_rptr        ),
  .axi_slave_b_data_o  ( llc_b_data         ),
  .axi_slave_b_wptr_o  ( llc_b_wptr         ),
  .axi_slave_b_rptr_i  ( llc_b_rptr         ),
  .axi_slave_r_data_o  ( llc_r_data         ),
  .axi_slave_r_wptr_o  ( llc_r_wptr         ),
  .axi_slave_r_rptr_i  ( llc_r_rptr         ),
  .axi_slave_w_data_i  ( llc_w_data         ),
  .axi_slave_w_wptr_i  ( llc_w_wptr         ),
  .axi_slave_w_rptr_o  ( llc_w_rptr         ),
  .rbus_req_addr_i     ( reg_hyper_req.addr  ),
  .rbus_req_write_i    ( reg_hyper_req.write ),
  .rbus_req_wdata_i    ( reg_hyper_req.wdata ),
  .rbus_req_wstrb_i    ( reg_hyper_req.wstrb ),
  .rbus_req_valid_i    ( reg_hyper_req.valid ),
  .rbus_rsp_rdata_o    ( reg_hyper_rsp.rdata ),
  .rbus_rsp_ready_o    ( reg_hyper_rsp.ready ),
  .rbus_rsp_error_o    ( reg_hyper_rsp.error ),
  .hyper_cs_no,
  .hyper_ck_o,
  .hyper_ck_no,
  .hyper_rwds_o,
  .hyper_rwds_i,
  .hyper_rwds_oe_o,
  .hyper_dq_i,
  .hyper_dq_o,
  .hyper_dq_oe_o,
  .hyper_reset_no
);

// Reconfigurable L2 Memory
// Host Clock Domain
logic l2_ecc_err;

l2_wrap #(
  .NumPort      ( NumL2Ports             ),
  .AxiAddrWidth ( Cfg.AddrWidth          ),
  .AxiDataWidth ( Cfg.AxiDataWidth       ),
  .AxiIdWidth   ( AxiSlvIdWidth          ),
  .AxiUserWidth ( Cfg.AxiUserWidth       ),
  .AxiMaxTrans  ( Cfg.AxiMaxSlvTrans     ),
  .LogDepth     ( LogDepth               ),
  .NumRules     ( L2NumRules             ),
  .L2MemSize    ( L2MemSize              )
) i_reconfigrurable_l2 (
  .clk_i               ( host_clk_i                           ),
  .rst_ni              ( host_pwr_on_rst_n                    ),
  .slvport_ar_data_i   ( axi_slv_ext_ar_data [NumL2Ports-1:0] ),
  .slvport_ar_wptr_i   ( axi_slv_ext_ar_wptr [NumL2Ports-1:0] ),
  .slvport_ar_rptr_o   ( axi_slv_ext_ar_rptr [NumL2Ports-1:0] ),
  .slvport_aw_data_i   ( axi_slv_ext_aw_data [NumL2Ports-1:0] ),
  .slvport_aw_wptr_i   ( axi_slv_ext_aw_wptr [NumL2Ports-1:0] ),
  .slvport_aw_rptr_o   ( axi_slv_ext_aw_rptr [NumL2Ports-1:0] ),
  .slvport_b_data_o    ( axi_slv_ext_b_data  [NumL2Ports-1:0] ),
  .slvport_b_wptr_o    ( axi_slv_ext_b_wptr  [NumL2Ports-1:0] ),
  .slvport_b_rptr_i    ( axi_slv_ext_b_rptr  [NumL2Ports-1:0] ),
  .slvport_r_data_o    ( axi_slv_ext_r_data  [NumL2Ports-1:0] ),
  .slvport_r_wptr_o    ( axi_slv_ext_r_wptr  [NumL2Ports-1:0] ),
  .slvport_r_rptr_i    ( axi_slv_ext_r_rptr  [NumL2Ports-1:0] ),
  .slvport_w_data_i    ( axi_slv_ext_w_data  [NumL2Ports-1:0] ),
  .slvport_w_wptr_i    ( axi_slv_ext_w_wptr  [NumL2Ports-1:0] ),
  .slvport_w_rptr_o    ( axi_slv_ext_w_rptr  [NumL2Ports-1:0] ),
  .ecc_error_o         ( l2_ecc_err                           )
);

// Safety Island
// Alt Clock Domain
safety_island_pkg::bootmode_e safety_island_bootmode;
assign safety_island_bootmode = safety_island_pkg::Preloaded;

safety_island_synth_wrapper #(
  .AxiAddrWidth             ( Cfg.AddrWidth              ),
  .AxiDataWidth             ( Cfg.AxiDataWidth           ),
  .AxiUserWidth             ( Cfg.AxiUserWidth           ),
  .AxiInIdWidth             ( AxiSlvIdWidth              ),
  .AxiOutIdWidth            ( Cfg.AxiMstIdWidth          ),
  .LogDepth                 ( LogDepth                   ),
  .SafetyIslandBaseAddr     ( SafetyIslandBase           ),
  .SafetyIslandAddrRange    ( SafetyIslandSize           ),
  .SafetyIslandMemOffset    ( SafetyIslandMemOffset      ),
  .SafetyIslandPeriphOffset ( SafetyIslandPerOffset      ),
  .axi_in_aw_chan_t         ( carfield_axi_slv_aw_chan_t ),
  .axi_in_w_chan_t          ( carfield_axi_slv_w_chan_t  ),
  .axi_in_b_chan_t          ( carfield_axi_slv_b_chan_t  ),
  .axi_in_ar_chan_t         ( carfield_axi_slv_ar_chan_t ),
  .axi_in_r_chan_t          ( carfield_axi_slv_r_chan_t  ),
  .axi_in_req_t             ( carfield_axi_slv_req_t     ),
  .axi_in_resp_t            ( carfield_axi_slv_rsp_t     ),
  .axi_out_aw_chan_t        ( carfield_axi_mst_aw_chan_t ),
  .axi_out_w_chan_t         ( carfield_axi_mst_w_chan_t  ),
  .axi_out_b_chan_t         ( carfield_axi_mst_b_chan_t  ),
  .axi_out_ar_chan_t        ( carfield_axi_mst_ar_chan_t ),
  .axi_out_r_chan_t         ( carfield_axi_mst_r_chan_t  ),
  .axi_out_req_t            ( carfield_axi_mst_req_t     ),
  .axi_out_resp_t           ( carfield_axi_mst_rsp_t     ),
  .AsyncAxiInAwWidth        ( CarfieldAxiSlvAwWidth      ),
  .AsyncAxiInWWidth         ( CarfieldAxiSlvWWidth       ),
  .AsyncAxiInBWidth         ( CarfieldAxiSlvBWidth       ),
  .AsyncAxiInArWidth        ( CarfieldAxiSlvArWidth      ),
  .AsyncAxiInRWidth         ( CarfieldAxiSlvRWidth       ),
  .AsyncAxiOutAwWidth       ( CarfieldAxiMstAwWidth      ),
  .AsyncAxiOutWWidth        ( CarfieldAxiMstWWidth       ),
  .AsyncAxiOutBWidth        ( CarfieldAxiMstBWidth       ),
  .AsyncAxiOutArWidth       ( CarfieldAxiMstArWidth      ),
  .AsyncAxiOutRWidth        ( CarfieldAxiMstRWidth       )
) i_safety_island_wrap    (
  .clk_i                  ( alt_clk_i                                ),
  .ref_clk_i              ( rt_clk_i                                 ),
  .rst_ni                 ( safety_rst_n                             ),
  .pwr_on_rst_ni          ( safety_pwr_on_rst_n                      ),
  .test_enable_i          ( '0                                       ),
  .bootmode_i             ( safety_island_bootmode                   ),
  .fetch_en_i             ( car_regs_reg2hw.safety_island_fetch_enable ), // To SoC Bus
  .axi_isolate_i          ( slave_isolate_req [SafetyIslandSlvIdx]   ), // To SoC Bus
  .axi_isolated_o         ( master_isolated_rsp [SafetyIslandMstIdx] ),
  .irqs_i                 ( '0                                       ),
  .debug_req_o            (                                          ),
  .jtag_tck_i             ( jtag_safety_island_tck_i                 ),
  .jtag_trst_ni           ( jtag_safety_island_trst_ni               ),
  .jtag_tms_i             ( jtag_safety_island_tms_i                 ),
  .jtag_tdi_i             ( jtag_safety_island_tdi_i                 ),
  .jtag_tdo_o             ( jtag_safety_island_tdo_o                 ),
  // Slave port
  .async_axi_in_aw_data_i ( axi_slv_ext_aw_data [SafetyIslandSlvIdx] ),
  .async_axi_in_aw_wptr_i ( axi_slv_ext_aw_wptr [SafetyIslandSlvIdx] ),
  .async_axi_in_aw_rptr_o ( axi_slv_ext_aw_rptr [SafetyIslandSlvIdx] ),
  .async_axi_in_w_data_i  ( axi_slv_ext_w_data  [SafetyIslandSlvIdx] ),
  .async_axi_in_w_wptr_i  ( axi_slv_ext_w_wptr  [SafetyIslandSlvIdx] ),
  .async_axi_in_w_rptr_o  ( axi_slv_ext_w_rptr  [SafetyIslandSlvIdx] ),
  .async_axi_in_b_data_o  ( axi_slv_ext_b_data  [SafetyIslandSlvIdx] ),
  .async_axi_in_b_wptr_o  ( axi_slv_ext_b_wptr  [SafetyIslandSlvIdx] ),
  .async_axi_in_b_rptr_i  ( axi_slv_ext_b_rptr  [SafetyIslandSlvIdx] ),
  .async_axi_in_ar_data_i ( axi_slv_ext_ar_data [SafetyIslandSlvIdx] ),
  .async_axi_in_ar_wptr_i ( axi_slv_ext_ar_wptr [SafetyIslandSlvIdx] ),
  .async_axi_in_ar_rptr_o ( axi_slv_ext_ar_rptr [SafetyIslandSlvIdx] ),
  .async_axi_in_r_data_o  ( axi_slv_ext_r_data  [SafetyIslandSlvIdx] ),
  .async_axi_in_r_wptr_o  ( axi_slv_ext_r_wptr  [SafetyIslandSlvIdx] ),
  .async_axi_in_r_rptr_i  ( axi_slv_ext_r_rptr  [SafetyIslandSlvIdx] ),
  // Master port
  .async_axi_out_aw_data_o ( axi_mst_ext_aw_data [SafetyIslandMstIdx] ),
  .async_axi_out_aw_wptr_o ( axi_mst_ext_aw_wptr [SafetyIslandMstIdx] ),
  .async_axi_out_aw_rptr_i ( axi_mst_ext_aw_rptr [SafetyIslandMstIdx] ),
  .async_axi_out_w_data_o  ( axi_mst_ext_w_data  [SafetyIslandMstIdx] ),
  .async_axi_out_w_wptr_o  ( axi_mst_ext_w_wptr  [SafetyIslandMstIdx] ),
  .async_axi_out_w_rptr_i  ( axi_mst_ext_w_rptr  [SafetyIslandMstIdx] ),
  .async_axi_out_b_data_i  ( axi_mst_ext_b_data  [SafetyIslandMstIdx] ),
  .async_axi_out_b_wptr_i  ( axi_mst_ext_b_wptr  [SafetyIslandMstIdx] ),
  .async_axi_out_b_rptr_o  ( axi_mst_ext_b_rptr  [SafetyIslandMstIdx] ),
  .async_axi_out_ar_data_o ( axi_mst_ext_ar_data [SafetyIslandMstIdx] ),
  .async_axi_out_ar_wptr_o ( axi_mst_ext_ar_wptr [SafetyIslandMstIdx] ),
  .async_axi_out_ar_rptr_i ( axi_mst_ext_ar_rptr [SafetyIslandMstIdx] ),
  .async_axi_out_r_data_i  ( axi_mst_ext_r_data  [SafetyIslandMstIdx] ),
  .async_axi_out_r_wptr_i  ( axi_mst_ext_r_wptr  [SafetyIslandMstIdx] ),
  .async_axi_out_r_rptr_o  ( axi_mst_ext_r_rptr  [SafetyIslandMstIdx] )
);

// PULP integer cluster
// Alt Clock Domain
pulp_cluster #(
  .NB_CORES                       ( IntClusterNumCores        ),
  .NB_HWPE_PORTS                  ( IntClusterNumHwpePorts    ),
  .NB_DMAS                        ( IntClusterNumDmas         ),
  .NB_MPERIPHS                    ( IntClusterNumMstPer       ),
  .NB_SPERIPHS                    ( IntClusterNumSlvPer       ),
  .CLUSTER_ALIAS                  ( IntClusterAlias           ),
  .CLUSTER_ALIAS_BASE             ( IntClusterAliasBase       ),
  .TCDM_SIZE                      ( IntClusterTcdmSize        ),
  .NB_TCDM_BANKS                  ( IntClusterTcdmBanks       ),
  .HWPE_PRESENT                   ( IntClusterHwpePresent     ),
  .USE_HETEROGENEOUS_INTERCONNECT ( IntClusterUseHci          ),
  .SET_ASSOCIATIVE                ( IntClusterSetAssociative  ),
  .NB_CACHE_BANKS                 ( IntClusterNumCacheBanks   ),
  .CACHE_LINE                     ( IntClusterNumCacheLines   ),
  .CACHE_SIZE                     ( IntClusterCacheSize       ),
  .L0_BUFFER_FEATURE              ( "DISABLED"                ),
  .MULTICAST_FEATURE              ( "DISABLED"                ),
  .SHARED_ICACHE                  ( "ENABLED"                 ),
  .DIRECT_MAPPED_FEATURE          ( "DISABLED"                ),
  .L2_SIZE                        ( L2MemSize                 ),
  .USE_REDUCED_TAG                ( "TRUE"                    ),
  .DEBUG_START_ADDR               ( IntClusterDbgStart        ),
  .ROM_BOOT_ADDR                  ( IntClusterRomBoot         ),
  .BOOT_ADDR                      ( IntClusterBootAddr        ),
  .INSTR_RDATA_WIDTH              ( IntClusterInstrRdataWidth ),
  .CLUST_FPU                      ( IntClusterFpu             ),
  .CLUST_FP_DIVSQRT               ( IntClusterFpuDivSqrt      ),
  .CLUST_SHARED_FP                ( IntClusterFpu             ),
  .CLUST_SHARED_FP_DIVSQRT        ( IntClusterFpuDivSqrt      ),
  .NumAxiMst                      ( IntClusterNumAxiMst       ),
  .NumAxiSlv                      ( IntClusterNumAxiSlv       ),
  .AXI_ADDR_WIDTH                 ( Cfg.AddrWidth             ),
  .AXI_DATA_C2S_WIDTH             ( Cfg.AxiDataWidth          ),
  .AXI_DATA_S2C_WIDTH             ( Cfg.AxiDataWidth          ),
  .AXI_USER_WIDTH                 ( Cfg.AxiUserWidth          ),
  .AXI_ID_IN_WIDTH                ( IntClusterAxiIdInWidth    ),
  .AXI_ID_OUT_WIDTH               ( IntClusterAxiIdOutWidth   ),
  .LOG_DEPTH                      ( LogDepth                  ),
  .BaseAddr                       ( IntClusterBase            )
) i_integer_cluster            (
  .clk_i                       ( alt_clk_i                              ),
  .rst_ni                      ( pulp_rst_n                             ),
  .pwr_on_rst_ni               ( pulp_pwr_on_rst_n                      ),
  .ref_clk_i                   ( rt_clk_i                               ),
  .pmu_mem_pwdn_i              ( '0                                     ),
  .base_addr_i                 ( '0                                     ),
  .test_mode_i                 ( test_mode_i                            ),
  .cluster_id_i                ( IntClusterIndex                        ),
  .en_sa_boot_i                ( '0                                     ), // To Soc Control
  .fetch_en_i                  ( car_regs_reg2hw.pulp_cluster_fetch_enable ), // To Soc Control
  .eoc_o                       (                                        ), // To Soc Control
  .busy_o                      (                                        ), // To Soc Control
  .axi_isolate_i               ( slave_isolate_req [IntClusterSlvIdx]   ), // To SoC Control
  .axi_isolated_o              ( master_isolated_rsp [IntClusterMstIdx] ), // To SoC Control
  .dma_pe_evt_ack_i            ( '0                                     ), // To edge propagator
  .dma_pe_evt_valid_o          (                                        ), // To edge propagator
  .dma_pe_irq_ack_i            ( '1                                     ), // To edge propagator (?)
  .dma_pe_irq_valid_o          (                                        ), // To edge propagator (?)
  .dbg_irq_valid_i             ( '0                                     ), // To edge propagator (?)
  .mbox_irq_i                  ( '0                                     ),
  .pf_evt_ack_i                ( '1                                     ), // To edge propagator (?)
  .pf_evt_valid_o              (                                        ), // To edge propagator (?)
  .async_cluster_events_wptr_i ( '0                                     ), // To edge propagator (?)
  .async_cluster_events_rptr_o (                                        ), // To edge propagator (?)
  .async_cluster_events_data_i ( '0                                     ), // To edge propagator (?)
  // AXI4 Slave port
  .async_data_slave_aw_data_i  ( axi_slv_intcluster_aw_data ),
  .async_data_slave_aw_wptr_i  ( axi_slv_intcluster_aw_wptr ),
  .async_data_slave_aw_rptr_o  ( axi_slv_intcluster_aw_rptr ),
  .async_data_slave_ar_data_i  ( axi_slv_intcluster_ar_data ),
  .async_data_slave_ar_wptr_i  ( axi_slv_intcluster_ar_wptr ),
  .async_data_slave_ar_rptr_o  ( axi_slv_intcluster_ar_rptr ),
  .async_data_slave_w_data_i   ( axi_slv_intcluster_w_data  ),
  .async_data_slave_w_wptr_i   ( axi_slv_intcluster_w_wptr  ),
  .async_data_slave_w_rptr_o   ( axi_slv_intcluster_w_rptr  ),
  .async_data_slave_r_data_o   ( axi_slv_intcluster_r_data  ),
  .async_data_slave_r_wptr_o   ( axi_slv_intcluster_r_wptr  ),
  .async_data_slave_r_rptr_i   ( axi_slv_intcluster_r_rptr  ),
  .async_data_slave_b_data_o   ( axi_slv_intcluster_b_data  ),
  .async_data_slave_b_wptr_o   ( axi_slv_intcluster_b_wptr  ),
  .async_data_slave_b_rptr_i   ( axi_slv_intcluster_b_rptr  ),
  // AXI4 Master Port
  .async_data_master_aw_data_o ( axi_mst_intcluster_aw_data ),
  .async_data_master_aw_wptr_o ( axi_mst_intcluster_aw_wptr ),
  .async_data_master_aw_rptr_i ( axi_mst_intcluster_aw_rptr ),
  .async_data_master_ar_data_o ( axi_mst_intcluster_ar_data ),
  .async_data_master_ar_wptr_o ( axi_mst_intcluster_ar_wptr ),
  .async_data_master_ar_rptr_i ( axi_mst_intcluster_ar_rptr ),
  .async_data_master_w_data_o  ( axi_mst_intcluster_w_data  ),
  .async_data_master_w_wptr_o  ( axi_mst_intcluster_w_wptr  ),
  .async_data_master_w_rptr_i  ( axi_mst_intcluster_w_rptr  ),
  .async_data_master_r_data_i  ( axi_mst_intcluster_r_data  ),
  .async_data_master_r_wptr_i  ( axi_mst_intcluster_r_wptr  ),
  .async_data_master_r_rptr_o  ( axi_mst_intcluster_r_rptr  ),
  .async_data_master_b_data_i  ( axi_mst_intcluster_b_data  ),
  .async_data_master_b_wptr_i  ( axi_mst_intcluster_b_wptr  ),
  .async_data_master_b_rptr_o  ( axi_mst_intcluster_b_rptr  )
);

// Floating Point Spatz Cluster
// Alt Clock Domain
spatz_cluster_wrapper #(
    .AxiAddrWidth             ( Cfg.AddrWidth     ),
    .AxiDataWidth             ( Cfg.AxiDataWidth  ),
    .AxiUserWidth             ( Cfg.AxiUserWidth  ),
    .AxiInIdWidth             ( AxiSlvIdWidth   ),
    .AxiOutIdWidth            ( Cfg.AxiMstIdWidth ),
    .LogDepth                 ( LogDepth ),

    // AXI type IN
    .axi_in_resp_t            ( carfield_axi_slv_rsp_t     ),
    .axi_in_req_t             ( carfield_axi_slv_req_t     ),

    .axi_in_aw_chan_t         ( carfield_axi_slv_aw_chan_t ),
    .axi_in_w_chan_t          ( carfield_axi_slv_w_chan_t  ),
    .axi_in_b_chan_t          ( carfield_axi_slv_b_chan_t  ),
    .axi_in_ar_chan_t         ( carfield_axi_slv_ar_chan_t ),
    .axi_in_r_chan_t          ( carfield_axi_slv_r_chan_t  ),

    // AXI type OUT
    .axi_out_resp_t           ( carfield_axi_mst_rsp_t     ),
    .axi_out_req_t            ( carfield_axi_mst_req_t     ),

    .axi_out_aw_chan_t        ( carfield_axi_mst_aw_chan_t ),
    .axi_out_w_chan_t         ( carfield_axi_mst_w_chan_t  ),
    .axi_out_b_chan_t         ( carfield_axi_mst_b_chan_t  ),
    .axi_out_ar_chan_t        ( carfield_axi_mst_ar_chan_t ),
    .axi_out_r_chan_t         ( carfield_axi_mst_r_chan_t  ),
    //CDC AXI Slv parameters
    .AsyncAxiInAwWidth        ( CarfieldAxiSlvAwWidth  ),
    .AsyncAxiInWWidth         ( CarfieldAxiSlvWWidth   ),
    .AsyncAxiInBWidth         ( CarfieldAxiSlvBWidth   ),
    .AsyncAxiInArWidth        ( CarfieldAxiSlvArWidth  ),
    .AsyncAxiInRWidth         ( CarfieldAxiSlvRWidth   ),
    //CDC AXI Mst parameters
    .AsyncAxiOutAwWidth       ( CarfieldAxiMstAwWidth ),
    .AsyncAxiOutWWidth        ( CarfieldAxiMstWWidth  ),
    .AsyncAxiOutBWidth        ( CarfieldAxiMstBWidth  ),
    .AsyncAxiOutArWidth       ( CarfieldAxiMstArWidth ),
    .AsyncAxiOutRWidth        ( CarfieldAxiMstRWidth  )
    )i_fp_cluster_wrapper(
    .clk_i           ( alt_clk_i            ),
    .rst_ni          ( spatz_rst_n          ),
  // TODO: add pwr_on_rst (!)
  // TODO: add synth wrapper and isolate stuff like safety island
    .testmode_i      ( 1'b0                 ), // TODO: connect
    .scan_enable_i   ( 1'b0                 ),
    .scan_data_i     ( 1'b0                 ),
    .scan_data_o     (  /* Unused */        ),
    .meip_i          ( '0                   ),
    .msip_i          ( '0                   ),
    .mtip_i          ( '0                   ),
    .debug_req_i     ( '0                   ),
    //AXI Isolate
    .axi_isolate_i         ( slave_isolate_req [FPClusterSlvIdx]   ),
    .axi_isolated_o        ( master_isolated_rsp [FPClusterMstIdx] ),

    //AXI FP Cluster Slave Port <- Carfield Master Port
   .async_axi_in_aw_data_i ( axi_slv_ext_aw_data [FPClusterSlvIdx] ),
   .async_axi_in_aw_wptr_i ( axi_slv_ext_aw_wptr [FPClusterSlvIdx] ),
   .async_axi_in_aw_rptr_o ( axi_slv_ext_aw_rptr [FPClusterSlvIdx] ),
   .async_axi_in_w_data_i  ( axi_slv_ext_w_data  [FPClusterSlvIdx] ),
   .async_axi_in_w_wptr_i  ( axi_slv_ext_w_wptr  [FPClusterSlvIdx] ),
   .async_axi_in_w_rptr_o  ( axi_slv_ext_w_rptr  [FPClusterSlvIdx] ),
   .async_axi_in_b_data_o  ( axi_slv_ext_b_data  [FPClusterSlvIdx] ),
   .async_axi_in_b_wptr_o  ( axi_slv_ext_b_wptr  [FPClusterSlvIdx] ),
   .async_axi_in_b_rptr_i  ( axi_slv_ext_b_rptr  [FPClusterSlvIdx] ),
   .async_axi_in_ar_data_i ( axi_slv_ext_ar_data [FPClusterSlvIdx] ),
   .async_axi_in_ar_wptr_i ( axi_slv_ext_ar_wptr [FPClusterSlvIdx] ),
   .async_axi_in_ar_rptr_o ( axi_slv_ext_ar_rptr [FPClusterSlvIdx] ),
   .async_axi_in_r_data_o  ( axi_slv_ext_r_data  [FPClusterSlvIdx] ),
   .async_axi_in_r_wptr_o  ( axi_slv_ext_r_wptr  [FPClusterSlvIdx] ),
   .async_axi_in_r_rptr_i  ( axi_slv_ext_r_rptr  [FPClusterSlvIdx] ),
   //AXI FP Cluster Master Port -> Carfield Slave Port
   .async_axi_out_aw_data_o ( axi_mst_ext_aw_data [FPClusterMstIdx] ),
   .async_axi_out_aw_wptr_o ( axi_mst_ext_aw_wptr [FPClusterMstIdx] ),
   .async_axi_out_aw_rptr_i ( axi_mst_ext_aw_rptr [FPClusterMstIdx] ),
   .async_axi_out_w_data_o  ( axi_mst_ext_w_data  [FPClusterMstIdx] ),
   .async_axi_out_w_wptr_o  ( axi_mst_ext_w_wptr  [FPClusterMstIdx] ),
   .async_axi_out_w_rptr_i  ( axi_mst_ext_w_rptr  [FPClusterMstIdx] ),
   .async_axi_out_b_data_i  ( axi_mst_ext_b_data  [FPClusterMstIdx] ),
   .async_axi_out_b_wptr_i  ( axi_mst_ext_b_wptr  [FPClusterMstIdx] ),
   .async_axi_out_b_rptr_o  ( axi_mst_ext_b_rptr  [FPClusterMstIdx] ),
   .async_axi_out_ar_data_o ( axi_mst_ext_ar_data [FPClusterMstIdx] ),
   .async_axi_out_ar_wptr_o ( axi_mst_ext_ar_wptr [FPClusterMstIdx] ),
   .async_axi_out_ar_rptr_i ( axi_mst_ext_ar_rptr [FPClusterMstIdx] ),
   .async_axi_out_r_data_i  ( axi_mst_ext_r_data  [FPClusterMstIdx] ),
   .async_axi_out_r_wptr_i  ( axi_mst_ext_r_wptr  [FPClusterMstIdx] ),
   .async_axi_out_r_rptr_o  ( axi_mst_ext_r_rptr  [FPClusterMstIdx] ),
   .cluster_probe_o (        )
  );

// Security Island
// Alt Clock Domain
secure_subsystem_synth_wrap #(
  .AxiAddrWidth          ( Cfg.AddrWidth              ),
  .AxiDataWidth          ( Cfg.AxiDataWidth           ),
  .AxiUserWidth          ( Cfg.AxiUserWidth           ),
  .AxiOutIdWidth         ( Cfg.AxiMstIdWidth          ),
  .AxiOtAddrWidth        ( Cfg.AddrWidth              ),
  .AxiOtDataWidth        ( AxiNarrowDataWidth         ), // TODO: why is this exposed?
  .AxiOtUserWidth        ( Cfg.AxiUserWidth           ),
  .AxiOtOutIdWidth       ( Cfg.AxiMstIdWidth          ),
  .AsyncAxiOutAwWidth    ( CarfieldAxiMstAwWidth      ),
  .AsyncAxiOutWWidth     ( CarfieldAxiMstWWidth       ),
  .AsyncAxiOutBWidth     ( CarfieldAxiMstBWidth       ),
  .AsyncAxiOutArWidth    ( CarfieldAxiMstArWidth      ),
  .AsyncAxiOutRWidth     ( CarfieldAxiMstRWidth       ),
  .axi_out_aw_chan_t     ( carfield_axi_mst_aw_chan_t ),
  .axi_out_w_chan_t      ( carfield_axi_mst_w_chan_t  ),
  .axi_out_b_chan_t      ( carfield_axi_mst_b_chan_t  ),
  .axi_out_ar_chan_t     ( carfield_axi_mst_ar_chan_t ),
  .axi_out_r_chan_t      ( carfield_axi_mst_r_chan_t  ),
  .axi_out_req_t         ( carfield_axi_mst_req_t     ),
  .axi_out_resp_t        ( carfield_axi_mst_rsp_t     ),
  .axi_ot_out_aw_chan_t  ( carfield_axi_mst_aw_chan_t ),
  .axi_ot_out_w_chan_t   ( carfield_axi_mst_w_chan_t  ),
  .axi_ot_out_b_chan_t   ( carfield_axi_mst_b_chan_t  ),
  .axi_ot_out_ar_chan_t  ( carfield_axi_mst_ar_chan_t ),
  .axi_ot_out_r_chan_t   ( carfield_axi_mst_r_chan_t  ),
  .axi_ot_out_req_t      ( carfield_axi_mst_req_t     ),
  .axi_ot_out_resp_t     ( carfield_axi_mst_rsp_t     )
) i_security_island (
  .clk_i            ( alt_clk_i       ),
  .clk_ref_i        ( alt_clk_i       ), // TODO: proper ref clock(?)
  .rst_ni           ( security_rst_n  ),
  // TODO: add pwr_on_rst (!)
  // TODO: add synth wrapper and isolate stuff like safety island
  .fetch_en_i       ( car_regs_reg2hw.security_island_fetch_enable ),
  .bootmode_i       ( '0              ),
  .test_enable_i    ( '0              ),
  .irq_ibex_i       ( ibex_mbox_irq   ),
   // JTAG port
  .jtag_tck_i       ( jtag_ot_tck_i   ),
  .jtag_tms_i       ( jtag_ot_tms_i   ),
  .jtag_trst_n_i    ( jtag_ot_trst_ni ),
  .jtag_tdi_i       ( jtag_ot_tdi_i   ),
  .jtag_tdo_o       ( jtag_ot_tdo_o   ),
  .jtag_tdo_oe_o    (                 ),
   // Asynch axi port
  .async_axi_out_aw_data_o ( axi_mst_ext_aw_data [SecurityIslandMstIdx] ),
  .async_axi_out_aw_wptr_o ( axi_mst_ext_aw_wptr [SecurityIslandMstIdx] ),
  .async_axi_out_aw_rptr_i ( axi_mst_ext_aw_rptr [SecurityIslandMstIdx] ),
  .async_axi_out_w_data_o  ( axi_mst_ext_w_data  [SecurityIslandMstIdx] ),
  .async_axi_out_w_wptr_o  ( axi_mst_ext_w_wptr  [SecurityIslandMstIdx] ),
  .async_axi_out_w_rptr_i  ( axi_mst_ext_w_rptr  [SecurityIslandMstIdx] ),
  .async_axi_out_b_data_i  ( axi_mst_ext_b_data  [SecurityIslandMstIdx] ),
  .async_axi_out_b_wptr_i  ( axi_mst_ext_b_wptr  [SecurityIslandMstIdx] ),
  .async_axi_out_b_rptr_o  ( axi_mst_ext_b_rptr  [SecurityIslandMstIdx] ),
  .async_axi_out_ar_data_o ( axi_mst_ext_ar_data [SecurityIslandMstIdx] ),
  .async_axi_out_ar_wptr_o ( axi_mst_ext_ar_wptr [SecurityIslandMstIdx] ),
  .async_axi_out_ar_rptr_i ( axi_mst_ext_ar_rptr [SecurityIslandMstIdx] ),
  .async_axi_out_r_data_i  ( axi_mst_ext_r_data  [SecurityIslandMstIdx] ),
  .async_axi_out_r_wptr_i  ( axi_mst_ext_r_wptr  [SecurityIslandMstIdx] ),
  .async_axi_out_r_rptr_o  ( axi_mst_ext_r_rptr  [SecurityIslandMstIdx] ),
   // Uart
  .ibex_uart_rx_i   ( uart_ot_tx_o  ),
  .ibex_uart_tx_o   ( uart_ot_rx_i  ),
   // SPI host
  .spi_host_SCK_o   ( spih_ot_sck_o    ),
  .spi_host_SCK_en_o( spih_ot_sck_en_o ),
  .spi_host_CSB_o   ( spih_ot_csb_o    ),
  .spi_host_CSB_en_o( spih_ot_csb_en_o ),
  .spi_host_SD_o    ( spih_ot_sd_o     ),
  .spi_host_SD_i    ( spih_ot_sd_i     ),
  .spi_host_SD_en_o ( spih_ot_sd_en_o  )
);

// Security Island Mailbox
// Host Clock Domain

carfield_axi_slv_req_t axi_mbox_req;
carfield_axi_slv_rsp_t axi_mbox_rsp;

// TODO: remove this useless CDC. Mailbox is in the host domain
axi_cdc_dst #(
  .LogDepth   ( LogDepth                   ),
  .aw_chan_t  ( carfield_axi_slv_aw_chan_t ),
  .w_chan_t   ( carfield_axi_slv_w_chan_t  ),
  .b_chan_t   ( carfield_axi_slv_b_chan_t  ),
  .ar_chan_t  ( carfield_axi_slv_ar_chan_t ),
  .r_chan_t   ( carfield_axi_slv_r_chan_t  ),
  .axi_req_t  ( carfield_axi_slv_req_t     ),
  .axi_resp_t ( carfield_axi_slv_rsp_t     )
) i_mailbox_cdc_dst (
  // asynchronous slave port
  .async_data_slave_aw_data_i ( axi_slv_ext_aw_data [OTMailboxSlvIdx] ),
  .async_data_slave_aw_wptr_i ( axi_slv_ext_aw_wptr [OTMailboxSlvIdx] ),
  .async_data_slave_aw_rptr_o ( axi_slv_ext_aw_rptr [OTMailboxSlvIdx] ),
  .async_data_slave_w_data_i  ( axi_slv_ext_w_data  [OTMailboxSlvIdx] ),
  .async_data_slave_w_wptr_i  ( axi_slv_ext_w_wptr  [OTMailboxSlvIdx] ),
  .async_data_slave_w_rptr_o  ( axi_slv_ext_w_rptr  [OTMailboxSlvIdx] ),
  .async_data_slave_b_data_o  ( axi_slv_ext_b_data  [OTMailboxSlvIdx] ),
  .async_data_slave_b_wptr_o  ( axi_slv_ext_b_wptr  [OTMailboxSlvIdx] ),
  .async_data_slave_b_rptr_i  ( axi_slv_ext_b_rptr  [OTMailboxSlvIdx] ),
  .async_data_slave_ar_data_i ( axi_slv_ext_ar_data [OTMailboxSlvIdx] ),
  .async_data_slave_ar_wptr_i ( axi_slv_ext_ar_wptr [OTMailboxSlvIdx] ),
  .async_data_slave_ar_rptr_o ( axi_slv_ext_ar_rptr [OTMailboxSlvIdx] ),
  .async_data_slave_r_data_o  ( axi_slv_ext_r_data  [OTMailboxSlvIdx] ),
  .async_data_slave_r_wptr_o  ( axi_slv_ext_r_wptr  [OTMailboxSlvIdx] ),
  .async_data_slave_r_rptr_i  ( axi_slv_ext_r_rptr  [OTMailboxSlvIdx] ),
  // synchronous master port
  .dst_clk_i                  ( host_clk_i        ),
  .dst_rst_ni                 ( host_pwr_on_rst_n ),
  .dst_req_o                  ( axi_mbox_req      ),
  .dst_resp_i                 ( axi_mbox_rsp      )
);

axi_scmi_mailbox #(
  .AXI_ADDR_WIDTH     ( Cfg.AddrWidth          ),
  .AXI_MST_DATA_WIDTH ( Cfg.AxiDataWidth       ),
  .AXI_ID_WIDTH       ( AxiSlvIdWidth          ),
  .AXI_USER_WIDTH     ( Cfg.AxiUserWidth       ),
  .axi_req_t          ( carfield_axi_slv_req_t ),
  .axi_resp_t         ( carfield_axi_slv_rsp_t )
) i_scmi_ot_mailbox   (
  .clk_i              ( host_clk_i         ),
  .rst_ni             ( host_pwr_on_rst_n  ),
  .axi_mbox_req       ( axi_mbox_req       ),
  .axi_mbox_rsp       ( axi_mbox_rsp       ),
  .doorbell_irq_o     ( ibex_mbox_irq      ),
  .completion_irq_o   ( ches_mbox_irq      )
);

// Carfield peripherals
// Ethernet
// Peripheral Clock Domain
carfield_axi_slv_req_t axi_ethernet_req;
carfield_axi_slv_rsp_t axi_ethernet_rsp;

axi_cdc_dst #(
  .LogDepth   ( LogDepth                   ),
  .aw_chan_t  ( carfield_axi_slv_aw_chan_t ),
  .w_chan_t   ( carfield_axi_slv_w_chan_t  ),
  .b_chan_t   ( carfield_axi_slv_b_chan_t  ),
  .ar_chan_t  ( carfield_axi_slv_ar_chan_t ),
  .r_chan_t   ( carfield_axi_slv_r_chan_t  ),
  .axi_req_t  ( carfield_axi_slv_req_t     ),
  .axi_resp_t ( carfield_axi_slv_rsp_t     )
) i_ethernet_cdc_dst (
  .async_data_slave_aw_data_i ( axi_slv_ext_aw_data [EthernetSlvIdx] ),
  .async_data_slave_aw_wptr_i ( axi_slv_ext_aw_wptr [EthernetSlvIdx] ),
  .async_data_slave_aw_rptr_o ( axi_slv_ext_aw_rptr [EthernetSlvIdx] ),
  .async_data_slave_w_data_i  ( axi_slv_ext_w_data  [EthernetSlvIdx] ),
  .async_data_slave_w_wptr_i  ( axi_slv_ext_w_wptr  [EthernetSlvIdx] ),
  .async_data_slave_w_rptr_o  ( axi_slv_ext_w_rptr  [EthernetSlvIdx] ),
  .async_data_slave_b_data_o  ( axi_slv_ext_b_data  [EthernetSlvIdx] ),
  .async_data_slave_b_wptr_o  ( axi_slv_ext_b_wptr  [EthernetSlvIdx] ),
  .async_data_slave_b_rptr_i  ( axi_slv_ext_b_rptr  [EthernetSlvIdx] ),
  .async_data_slave_ar_data_i ( axi_slv_ext_ar_data [EthernetSlvIdx] ),
  .async_data_slave_ar_wptr_i ( axi_slv_ext_ar_wptr [EthernetSlvIdx] ),
  .async_data_slave_ar_rptr_o ( axi_slv_ext_ar_rptr [EthernetSlvIdx] ),
  .async_data_slave_r_data_o  ( axi_slv_ext_r_data  [EthernetSlvIdx] ),
  .async_data_slave_r_wptr_o  ( axi_slv_ext_r_wptr  [EthernetSlvIdx] ),
  .async_data_slave_r_rptr_i  ( axi_slv_ext_r_rptr  [EthernetSlvIdx] ),
  .dst_clk_i                  ( periph_clk_i        ),
  .dst_rst_ni                 ( periph_pwr_on_rst_n ),
  .dst_req_o                  ( axi_ethernet_req    ),
  .dst_resp_i                 ( axi_ethernet_rsp    )
);

// TODO connect ethernet
axi_err_slv #(
 .AxiIdWidth  ( AxiSlvIdWidth          ),
 .axi_req_t   ( carfield_axi_slv_req_t ),
 .axi_resp_t  ( carfield_axi_slv_rsp_t ),
 .Resp        ( axi_pkg::RESP_DECERR   ),
 .ATOPs       ( 1'b0                   ),
 .MaxTrans    ( 4                      )
) i_axi_err_slv_ethernet (
  .clk_i      ( periph_clk_i           ),
  .rst_ni     ( periph_pwr_on_rst_n    ), // TODO: currently not sw resettable no isolate
  .test_i     ( test_mode_i            ),
  // slave port
  .slv_req_i  ( axi_ethernet_req       ),
  .slv_resp_o ( axi_ethernet_rsp       )
);

// APB peripherals
// Periph Clock Domain
// axi_cdc -> axi_amos -> axi_cut -> axi_to_axilite -> axilite_to_apb -> periph devices
carfield_axi_slv_req_t axi_d64_a48_peripherals_req;
carfield_axi_slv_rsp_t axi_d64_a48_peripherals_rsp;

axi_cdc_dst #(
  .LogDepth   ( LogDepth                   ),
  .aw_chan_t  ( carfield_axi_slv_aw_chan_t ),
  .w_chan_t   ( carfield_axi_slv_w_chan_t  ),
  .b_chan_t   ( carfield_axi_slv_b_chan_t  ),
  .ar_chan_t  ( carfield_axi_slv_ar_chan_t ),
  .r_chan_t   ( carfield_axi_slv_r_chan_t  ),
  .axi_req_t  ( carfield_axi_slv_req_t     ),
  .axi_resp_t ( carfield_axi_slv_rsp_t     )
) i_cdc_dst_peripherals (
  // asynchronous slave port
  .async_data_slave_aw_data_i ( axi_slv_ext_aw_data [PeriphsSlvIdx] ),
  .async_data_slave_aw_wptr_i ( axi_slv_ext_aw_wptr [PeriphsSlvIdx] ),
  .async_data_slave_aw_rptr_o ( axi_slv_ext_aw_rptr [PeriphsSlvIdx] ),
  .async_data_slave_w_data_i  ( axi_slv_ext_w_data  [PeriphsSlvIdx] ),
  .async_data_slave_w_wptr_i  ( axi_slv_ext_w_wptr  [PeriphsSlvIdx] ),
  .async_data_slave_w_rptr_o  ( axi_slv_ext_w_rptr  [PeriphsSlvIdx] ),
  .async_data_slave_b_data_o  ( axi_slv_ext_b_data  [PeriphsSlvIdx] ),
  .async_data_slave_b_wptr_o  ( axi_slv_ext_b_wptr  [PeriphsSlvIdx] ),
  .async_data_slave_b_rptr_i  ( axi_slv_ext_b_rptr  [PeriphsSlvIdx] ),
  .async_data_slave_ar_data_i ( axi_slv_ext_ar_data [PeriphsSlvIdx] ),
  .async_data_slave_ar_wptr_i ( axi_slv_ext_ar_wptr [PeriphsSlvIdx] ),
  .async_data_slave_ar_rptr_o ( axi_slv_ext_ar_rptr [PeriphsSlvIdx] ),
  .async_data_slave_r_data_o  ( axi_slv_ext_r_data  [PeriphsSlvIdx] ),
  .async_data_slave_r_wptr_o  ( axi_slv_ext_r_wptr  [PeriphsSlvIdx] ),
  .async_data_slave_r_rptr_i  ( axi_slv_ext_r_rptr  [PeriphsSlvIdx] ),
  // synchronous master port
  .dst_clk_i                  ( periph_clk_i                ),
  .dst_rst_ni                 ( periph_pwr_on_rst_n         ),
  .dst_req_o                  ( axi_d64_a48_peripherals_req ),
  .dst_resp_i                 ( axi_d64_a48_peripherals_rsp )
);

carfield_axi_slv_req_t axi_d64_a48_amo_peripherals_req;
carfield_axi_slv_rsp_t axi_d64_a48_amo_peripherals_rsp;

// Shim atomics, which are not supported in reg
// TODO: should we use a filter instead here?
axi_riscv_atomics_structs #(
  .AxiAddrWidth     ( Cfg.AddrWidth          ),
  .AxiDataWidth     ( Cfg.AxiDataWidth       ),
  .AxiIdWidth       ( AxiSlvIdWidth          ),
  .AxiUserWidth     ( Cfg.AxiUserWidth       ),
  .AxiMaxReadTxns   ( Cfg.RegMaxReadTxns     ),
  .AxiMaxWriteTxns  ( Cfg.RegMaxWriteTxns    ),
  .AxiUserAsId      ( 1                      ),
  .AxiUserIdMsb     ( Cfg.AxiUserAmoMsb      ),
  .AxiUserIdLsb     ( Cfg.AxiUserAmoLsb      ),
  .RiscvWordWidth   ( 64                     ),
  .NAxiCuts         ( Cfg.RegAmoNumCuts      ),
  .axi_req_t        ( carfield_axi_slv_req_t ),
  .axi_rsp_t        ( carfield_axi_slv_rsp_t )
) i_atomics_peripherals (
  .clk_i         ( periph_clk_i                    ),
  .rst_ni        ( periph_pwr_on_rst_n             ),
  .axi_slv_req_i ( axi_d64_a48_peripherals_req     ),
  .axi_slv_rsp_o ( axi_d64_a48_peripherals_rsp     ),
  .axi_mst_req_o ( axi_d64_a48_amo_peripherals_req ),
  .axi_mst_rsp_i ( axi_d64_a48_amo_peripherals_rsp )
);

carfield_axi_slv_req_t axi_d64_a48_amo_cut_peripherals_req;
carfield_axi_slv_rsp_t axi_d64_a48_amo_cut_peripherals_rsp;

axi_cut #(
  .Bypass     ( ~Cfg.RegAmoPostCut         ),
  .aw_chan_t  ( carfield_axi_slv_aw_chan_t ),
  .w_chan_t   ( carfield_axi_slv_w_chan_t  ),
  .b_chan_t   ( carfield_axi_slv_b_chan_t  ),
  .ar_chan_t  ( carfield_axi_slv_ar_chan_t ),
  .r_chan_t   ( carfield_axi_slv_r_chan_t  ),
  .axi_req_t  ( carfield_axi_slv_req_t     ),
  .axi_resp_t ( carfield_axi_slv_rsp_t     )
) i_atomics_cut_peripherals (
  .clk_i      ( periph_clk_i                        ),
  .rst_ni     ( periph_pwr_on_rst_n                 ),
  .slv_req_i  ( axi_d64_a48_amo_peripherals_req     ),
  .slv_resp_o ( axi_d64_a48_amo_peripherals_rsp     ),
  .mst_req_o  ( axi_d64_a48_amo_cut_peripherals_req ),
  .mst_resp_i ( axi_d64_a48_amo_cut_peripherals_rsp )
);

// Convert to d32 a48
// verilog_lint: waive-start line-length
`AXI_TYPEDEF_ALL_CT(carfield_axi_d32_a48_slv, carfield_axi_d32_a48_slv_req_t, carfield_axi_d32_a48_slv_rsp_t, car_addrw_t, car_slv_id_t, car_nar_dataw_t, car_nar_strb_t, car_usr_t)
// verilog_lint: waive-stop line-length

carfield_axi_d32_a48_slv_req_t axi_d32_a48_peripherals_req;
carfield_axi_d32_a48_slv_rsp_t axi_d32_a48_peripherals_rsp;

axi_dw_converter #(
  .AxiSlvPortDataWidth  ( Cfg.AxiDataWidth                  ),
  .AxiMstPortDataWidth  ( AxiNarrowDataWidth                ),
  .AxiAddrWidth         ( Cfg.AddrWidth                     ),
  .AxiIdWidth           ( AxiSlvIdWidth                     ),
  .aw_chan_t            ( carfield_axi_slv_aw_chan_t        ),
  .mst_w_chan_t         ( carfield_axi_d32_a48_slv_w_chan_t ),
  .slv_w_chan_t         ( carfield_axi_slv_w_chan_t         ),
  .b_chan_t             ( carfield_axi_slv_b_chan_t         ),
  .ar_chan_t            ( carfield_axi_slv_ar_chan_t        ),
  .mst_r_chan_t         ( carfield_axi_d32_a48_slv_r_chan_t ),
  .slv_r_chan_t         ( carfield_axi_slv_r_chan_t         ),
  .axi_mst_req_t        ( carfield_axi_d32_a48_slv_req_t    ),
  .axi_mst_resp_t       ( carfield_axi_d32_a48_slv_rsp_t    ),
  .axi_slv_req_t        ( carfield_axi_slv_req_t            ),
  .axi_slv_resp_t       ( carfield_axi_slv_rsp_t            )
) i_axi_dw_converter_peripherals (
  .clk_i      ( periph_clk_i                        ),
  .rst_ni     ( periph_pwr_on_rst_n                 ),
  .slv_req_i  ( axi_d64_a48_amo_cut_peripherals_req ),
  .slv_resp_o ( axi_d64_a48_amo_cut_peripherals_rsp ),
  .mst_req_o  ( axi_d32_a48_peripherals_req         ),
  .mst_resp_i ( axi_d32_a48_peripherals_rsp         )
);

// Convert to d32_a32
// verilog_lint: waive-start line-length
`AXI_TYPEDEF_ALL_CT(carfield_axi_d32_a32_slv, carfield_axi_d32_a32_slv_req_t, carfield_axi_d32_a32_slv_rsp_t, car_nar_addrw_t, car_slv_id_t, car_nar_dataw_t, car_nar_strb_t, car_usr_t)
// verilog_lint: waive-stop line-length

carfield_axi_d32_a32_slv_req_t axi_d32_a32_peripherals_req;
carfield_axi_d32_a32_slv_rsp_t axi_d32_a32_peripherals_rsp;

axi_modify_address #(
  .slv_req_t  ( carfield_axi_d32_a48_slv_req_t ),
  .mst_addr_t ( car_nar_addrw_t                ),
  .mst_req_t  ( carfield_axi_d32_a32_slv_req_t ),
  .axi_resp_t ( carfield_axi_d32_a32_slv_rsp_t )
) i_axi_modify_addr_peripherals (
  .slv_req_i     ( axi_d32_a48_peripherals_req               ),
  .slv_resp_o    ( axi_d32_a48_peripherals_rsp               ),
  .mst_req_o     ( axi_d32_a32_peripherals_req               ),
  .mst_resp_i    ( axi_d32_a32_peripherals_rsp               ),
  .mst_aw_addr_i ( axi_d32_a48_peripherals_req.aw.addr[31:0] ),
  .mst_ar_addr_i ( axi_d32_a48_peripherals_req.ar.addr[31:0] )
);

// AXI to AXI lite conversion
// verilog_lint: waive-start line-length
`AXI_LITE_TYPEDEF_ALL_CT(carfield_axi_lite_d32_a32, carfield_axi_lite_d32_a32_slv_req_t, carfield_axi_lite_d32_a32_slv_rsp_t, car_nar_addrw_t, car_nar_dataw_t, car_nar_strb_t)
// verilog_lint: waive-stop line-length

carfield_axi_lite_d32_a32_slv_req_t axi_lite_d32_a32_peripherals_req;
carfield_axi_lite_d32_a32_slv_rsp_t axi_lite_d32_a32_peripherals_rsp;

axi_to_axi_lite #(
  .AxiAddrWidth   ( AxiNarrowAddrWidth                  ),
  .AxiDataWidth   ( AxiNarrowDataWidth                  ),
  .AxiIdWidth     ( AxiSlvIdWidth                       ),
  .AxiUserWidth   ( Cfg.AxiUserWidth                    ),
  .AxiMaxWriteTxns( 1                                   ),
  .AxiMaxReadTxns ( 1                                   ),
  .FallThrough    ( 1                                   ),
  .full_req_t     ( carfield_axi_d32_a32_slv_req_t      ),
  .full_resp_t    ( carfield_axi_d32_a32_slv_rsp_t      ),
  .lite_req_t     ( carfield_axi_lite_d32_a32_slv_req_t ),
  .lite_resp_t    ( carfield_axi_lite_d32_a32_slv_rsp_t )
) i_axi_to_axi_lite_peripherals (
  .clk_i     ( periph_clk_i                     ),
  .rst_ni    ( periph_pwr_on_rst_n              ),
  .test_i    ( test_mode_i                      ),
  .slv_req_i ( axi_d32_a32_peripherals_req      ),
  .slv_resp_o( axi_d32_a32_peripherals_rsp      ),
  .mst_req_o ( axi_lite_d32_a32_peripherals_req ),
  .mst_resp_i( axi_lite_d32_a32_peripherals_rsp )
);

// Address map rules for peripherals

// Address map of peripheral system
typedef struct packed {
    logic [31:0] idx;
    car_nar_addrw_t start_addr;
    car_nar_addrw_t end_addr;
} carfield_addr_map_rule_t;

localparam carfield_addr_map_rule_t [NumApbMst-1:0] PeriphApbAddrMapRule = '{
 '{ idx: SystemTimerIdx,   start_addr: SystemTimerBase,
                           end_addr: SystemTimerEnd   }, // 0: System Timer
 '{ idx: AdvancedTimerIdx, start_addr: AdvancedTimerBase,
                           end_addr: AdvancedTimerEnd }, // 1: Advanced Timer
 '{ idx: SystemWdtIdx,     start_addr: SystemWdtBase,
                           end_addr: SystemWdtEnd     }, // 2: WDT
 '{ idx: CanIdx,           start_addr: CanBase,
                           end_addr: CanEnd           }, // 3: Can
 '{ idx: HyperBusIdx,      start_addr: HyperBusBase,
                           end_addr: HyperBusEnd      }  // 4: Hyperbus
};

// APB req/rsp
`APB_TYPEDEF_REQ_T(carfield_apb_req_t, car_nar_addrw_t, car_nar_dataw_t, car_nar_strb_t)
`APB_TYPEDEF_RESP_T(carfield_apb_rsp_t, car_nar_dataw_t)

// APB masters
carfield_apb_req_t [NumApbMst-1:0] apb_mst_req;
carfield_apb_rsp_t [NumApbMst-1:0] apb_mst_rsp;

axi_lite_to_apb #(
  .NoApbSlaves     ( NumApbMst                           ),
  .NoRules         ( NumApbMst                           ),
  .AddrWidth       ( AxiNarrowAddrWidth                  ),
  .DataWidth       ( AxiNarrowDataWidth                  ),
  .PipelineRequest ( '0                                  ),
  .PipelineResponse( '0                                  ),
  .axi_lite_req_t  ( carfield_axi_lite_d32_a32_slv_req_t ),
  .axi_lite_resp_t ( carfield_axi_lite_d32_a32_slv_rsp_t ),
  .apb_req_t       ( carfield_apb_req_t                  ),
  .apb_resp_t      ( carfield_apb_rsp_t                  ),
  .rule_t          ( carfield_addr_map_rule_t            )
) i_axi_lite_to_apb_peripherals (
  .clk_i          ( periph_clk_i                         ),
  .rst_ni         ( periph_pwr_on_rst_n                  ),
  .axi_lite_req_i ( axi_lite_d32_a32_peripherals_req     ),
  .axi_lite_resp_o( axi_lite_d32_a32_peripherals_rsp     ),
  .apb_req_o      ( apb_mst_req                          ),
  .apb_resp_i     ( apb_mst_rsp                          ),
  .addr_map_i     ( PeriphApbAddrMapRule                 )
);

// System timer
apb_timer_unit #(
  .APB_ADDR_WIDTH ( AxiNarrowAddrWidth )
) i_system_timer (
  .HCLK       ( periph_clk_i                        ),
  .HRESETn    ( periph_pwr_on_rst_n                 ),
  .PADDR      ( apb_mst_req[SystemTimerIdx].paddr   ),
  .PWDATA     ( apb_mst_req[SystemTimerIdx].pwdata  ),
  .PWRITE     ( apb_mst_req[SystemTimerIdx].pwrite  ),
  .PSEL       ( apb_mst_req[SystemTimerIdx].psel    ),
  .PENABLE    ( apb_mst_req[SystemTimerIdx].penable ),
  .PRDATA     ( apb_mst_rsp[SystemTimerIdx].prdata  ),
  .PREADY     ( apb_mst_rsp[SystemTimerIdx].pready  ),
  .PSLVERR    ( apb_mst_rsp[SystemTimerIdx].pslverr ),
  .ref_clk_i  ( rt_clk_i              ),
  .event_lo_i ( '0                    ),
  .event_hi_i ( '0                    ),
  .irq_lo_o   ( /* TODO connect me */ ),
  .irq_hi_o   ( /* TODO connect me */ ),
  .busy_o     ( /* TODO connect me */ )
);

// Advanced Timer
apb_adv_timer #(
  .APB_ADDR_WIDTH  ( AxiNarrowAddrWidth ),
  .EXTSIG_NUM      ( 64                 )
) i_advanced_timer (
  .HCLK            ( periph_clk_i           ),
  .HRESETn         ( periph_pwr_on_rst_n    ),
  .dft_cg_enable_i ( 1'b0                   ),
  .PADDR           ( apb_mst_req[AdvancedTimerIdx].paddr   ),
  .PWDATA          ( apb_mst_req[AdvancedTimerIdx].pwdata  ),
  .PWRITE          ( apb_mst_req[AdvancedTimerIdx].pwrite  ),
  .PSEL            ( apb_mst_req[AdvancedTimerIdx].psel    ),
  .PENABLE         ( apb_mst_req[AdvancedTimerIdx].penable ),
  .PRDATA          ( apb_mst_rsp[AdvancedTimerIdx].prdata  ),
  .PREADY          ( apb_mst_rsp[AdvancedTimerIdx].pready  ),
  .PSLVERR         ( apb_mst_rsp[AdvancedTimerIdx].pslverr ),
  .low_speed_clk_i ( rt_clk_i              ),
  .ext_sig_i       ( /* TODO connect me */  ),
  .events_o        ( /* TODO connect me */  ),
  .ch_0_o          ( /* TODO connect me */  ),
  .ch_1_o          ( /* TODO connect me */  ),
  .ch_2_o          ( /* TODO connect me */  ),
  .ch_3_o          ( /* TODO connect me */  )
);

// Watchdog timer
REG_BUS #(
  .ADDR_WIDTH ( AxiNarrowAddrWidth ),
  .DATA_WIDTH ( AxiNarrowDataWidth )
) reg_bus_wdt (periph_clk_i);

apb_to_reg i_apb_to_reg_wdt (
  .clk_i     ( periph_clk_i                      ),
  .rst_ni    ( periph_pwr_on_rst_n               ),
  .penable_i ( apb_mst_req[SystemWdtIdx].penable ),
  .pwrite_i  ( apb_mst_req[SystemWdtIdx].pwrite  ),
  .paddr_i   ( apb_mst_req[SystemWdtIdx].paddr   ),
  .psel_i    ( apb_mst_req[SystemWdtIdx].psel    ),
  .pwdata_i  ( apb_mst_req[SystemWdtIdx].pwdata  ),
  .prdata_o  ( apb_mst_rsp[SystemWdtIdx].prdata  ),
  .pready_o  ( apb_mst_rsp[SystemWdtIdx].pready  ),
  .pslverr_o ( apb_mst_rsp[SystemWdtIdx].pslverr ),
  .reg_o     ( reg_bus_wdt                 )
);

// crop the address to 32-bit
assign reg_wdt_req.addr  = reg_bus_wdt.addr;
assign reg_wdt_req.write = reg_bus_wdt.write;
assign reg_wdt_req.wdata = reg_bus_wdt.wdata;
assign reg_wdt_req.wstrb = reg_bus_wdt.wstrb;
assign reg_wdt_req.valid = reg_bus_wdt.valid;

assign reg_bus_wdt.rdata = reg_wdt_rsp.rdata;
assign reg_bus_wdt.error = reg_wdt_rsp.error;
assign reg_bus_wdt.ready = reg_wdt_rsp.ready;

// reg to tilelink
tlul_ot_pkg::tl_h2d_t tl_wdt_req;
tlul_ot_pkg::tl_d2h_t tl_wdt_rsp;

reg_to_tlul #(
  .req_t             ( carfield_a32_d32_reg_req_t     ),
  .rsp_t             ( carfield_a32_d32_reg_rsp_t     ),
  .tl_h2d_t          ( tlul_ot_pkg::tl_h2d_t          ),
  .tl_d2h_t          ( tlul_ot_pkg::tl_d2h_t          ),
  .tl_a_user_t       ( tlul_ot_pkg::tl_a_user_t       ),
  .tl_a_op_e         ( tlul_ot_pkg::tl_a_op_e         ),
  .TL_A_USER_DEFAULT ( tlul_ot_pkg::TL_A_USER_DEFAULT ),
  .PutFullData       ( tlul_ot_pkg::PutFullData       ),
  .Get               ( tlul_ot_pkg::Get               )
) i_reg_to_tlul_wdt (
  .tl_o      ( tl_wdt_req  ),
  .tl_i      ( tl_wdt_rsp  ),
  .reg_req_i ( reg_wdt_req ),
  .reg_rsp_o ( reg_wdt_rsp )
);

// Wdt
aon_timer i_watchdog_timer (
  .clk_i                     ( periph_clk_i          ),
  .rst_ni                    ( periph_pwr_on_rst_n   ),
  .clk_aon_i                 ( rt_clk_i              ),
  .rst_aon_ni                ( periph_pwr_on_rst_n   ),
  .tl_i                      ( tl_wdt_req            ),
  .tl_o                      ( tl_wdt_rsp            ),
  .alert_rx_i                ( '0                    ),
  .alert_tx_o                ( /* TODO connect me */ ),
  .lc_escalate_en_i          ( '0                    ),
  .intr_wkup_timer_expired_o ( /* TODO connect me */ ),
  .intr_wdog_timer_bark_o    ( /* TODO connect me */ ),
  .nmi_wdog_timer_bark_o     ( /* TODO connect me */ ),
  .wkup_req_o                ( /* TODO connect me */ ),
  .aon_timer_rst_req_o       ( /* TODO connect me */ ),
  .sleep_mode_i              ( '0                    )
);

// Hyperbus
REG_BUS #(
  .ADDR_WIDTH ( AxiNarrowAddrWidth ),
  .DATA_WIDTH ( AxiNarrowDataWidth )
) reg_bus_hyper (periph_clk_i);

apb_to_reg i_apb_to_reg_hyper (
  .clk_i     ( periph_clk_i                     ),
  .rst_ni    ( periph_pwr_on_rst_n              ),
  .penable_i ( apb_mst_req[HyperBusIdx].penable ),
  .pwrite_i  ( apb_mst_req[HyperBusIdx].pwrite  ),
  .paddr_i   ( apb_mst_req[HyperBusIdx].paddr   ),
  .psel_i    ( apb_mst_req[HyperBusIdx].psel    ),
  .pwdata_i  ( apb_mst_req[HyperBusIdx].pwdata  ),
  .prdata_o  ( apb_mst_rsp[HyperBusIdx].prdata  ),
  .pready_o  ( apb_mst_rsp[HyperBusIdx].pready  ),
  .pslverr_o ( apb_mst_rsp[HyperBusIdx].pslverr ),
  .reg_o     ( reg_bus_hyper                    )
);

assign reg_hyper_req.addr  = reg_bus_hyper.addr;
assign reg_hyper_req.write = reg_bus_hyper.write;
assign reg_hyper_req.wdata = reg_bus_hyper.wdata;
assign reg_hyper_req.wstrb = reg_bus_hyper.wstrb;
assign reg_hyper_req.valid = reg_bus_hyper.valid;

assign reg_bus_hyper.rdata = reg_hyper_rsp.rdata;
assign reg_bus_hyper.error = reg_hyper_rsp.error;
assign reg_bus_hyper.ready = reg_hyper_rsp.ready;

// CAN bus
logic [63:0] can_timestamp;
assign can_timestamp = '1;
can_top_apb #(
  .rx_buffer_size   ( 32                    ),
  .txt_buffer_count ( 2                     ),
  .target_technology( 0                     ) // 0 for ASIC or 1 for FPGA
 ) i_apb_to_can (
  .aclk             ( periph_clk_i           ),
  .arstn            ( periph_pwr_on_rst_n    ),
  .scan_enable      ( 1'b0                   ),
  .res_n_out        (                        ),
  .irq              ( /* TODO connect me */  ),
  .CAN_tx           ( /* TODO connect me */  ),
  .CAN_rx           ( /* TODO connect me */  ),
  .timestamp        ( can_timestamp          ),
  .s_apb_paddr      ( apb_mst_req[CanIdx].paddr   ),
  .s_apb_penable    ( apb_mst_req[CanIdx].penable ),
  .s_apb_pprot      ( 3'b000                 ),
  .s_apb_prdata     ( apb_mst_rsp[CanIdx].prdata  ),
  .s_apb_pready     ( apb_mst_rsp[CanIdx].pready  ),
  .s_apb_psel       ( apb_mst_req[CanIdx].psel    ),
  .s_apb_pslverr    ( apb_mst_rsp[CanIdx].pslverr ),
  .s_apb_pstrb      ( 4'b1111                ),
  .s_apb_pwdata     ( apb_mst_req[CanIdx].pwdata  ),
  .s_apb_pwrite     ( apb_mst_req[CanIdx].pwrite  )
);

// Propagate PLL cfg interface
assign pll_cfg_reg_req_o   = ext_reg_req[PllIdx];
assign ext_reg_rsp[PllIdx] = pll_cfg_reg_rsp_i;

// Propagate padframe cfg interface
assign padframe_cfg_reg_req_o   = ext_reg_req[PadframeIdx];
assign ext_reg_rsp[PadframeIdx] = padframe_cfg_reg_rsp_i;

endmodule
