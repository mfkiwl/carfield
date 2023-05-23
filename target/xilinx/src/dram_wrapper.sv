`include "cheshire/typedef.svh"
`include "phy_definitions.svh"

(* DONT_TOUCH = "yes" *) 
module dram_wrapper
#(
    parameter type axi_soc_aw_chan_t   = logic,
    parameter type axi_soc_w_chan_t    = logic,
    parameter type axi_soc_b_chan_t    = logic,
    parameter type axi_soc_ar_chan_t   = logic,
    parameter type axi_soc_r_chan_t    = logic,
    parameter type axi_soc_req_t       = logic,
    parameter type axi_soc_resp_t      = logic
) (
    // System reset
    input                       sys_rst_i,
    // Controller reset
    input                       soc_resetn_i,
    input                       soc_clk_i,
    // Phy interfaces
    `ifdef USE_DDR4
    `DDR4_INTF
    `endif
    `ifdef USE_DDR3
    `DDR3_INTF
    `endif
    // Dram axi interface
    input  axi_soc_req_t        soc_req_i,
    output axi_soc_resp_t       soc_rsp_o,
    // Generated clk/rst for SoC
    (* dont_touch = "yes" *) output dram_clk_o,
    // Synchronous with dram_axi_clk (not dram_clk_o)
    (* dont_touch = "yes" *) output dram_rst_o 
);

  ////////////////////////////////////
  // Configurations and definitions //
  ////////////////////////////////////

  typedef struct packed {
    bit     EnSpill0;
    bit     EnResizer;
    bit     EnCDC;
    bit     EnSpill1;
    integer DataWidth;
    integer ProbeWidth;
  } dram_cfg_t;

`ifdef USE_DDR4
  localparam dram_cfg_t cfg = '{
    EnSpill0      : 1,
    EnResizer     : 1,
    EnCDC         : 1, // 333 MHz
    EnSpill1      : 1,
    DataWidth     : 512,
    ProbeWidth    : 64
  };
`endif

`ifdef USE_DDR3
  localparam dram_cfg_t cfg = '{
    EnSpill0      : 0,
    EnResizer     : 0,
    EnCDC         : 1, // 200 MHz
    EnSpill1      : 1,
    DataWidth     : 64,
    ProbeWidth    : 8
  };
`endif

  // Define type after resizer (DRAM AXI)
  `AXI_TYPEDEF_ALL(axi_ddr, logic[$bits(soc_req_i.ar.addr)-1:0], logic[$bits(soc_req_i.ar.id)-1:0], logic[cfg.DataWidth-1:0], logic[cfg.ProbeWidth-1:0], logic[$bits(soc_req_i.ar.user)-1:0])

  // Clock on which is clocked the DRAM AXI
  // (May or may not be the dram_clk_o)
  logic  dram_axi_clk;

  // Signals before resizing
  axi_soc_req_t      soc_spill_req, spill_resizer_req;
  axi_soc_resp_t     soc_spill_rsp, spill_resizer_rsp;

  // Signals after resizing
  axi_ddr_req_t  resizer_cdc_req, cdc_spill_req, spill_dram_req;
  axi_ddr_resp_t resizer_cdc_rsp, cdc_spill_rsp, spill_dram_rsp;

  // Entry signals
  assign soc_spill_req = soc_req_i;
  assign soc_rsp_o = soc_spill_rsp;

  //////////////////////////
  // Instianciate Spill 0 //
  //////////////////////////

  generate
    if (cfg.EnSpill0)
    begin
      // AXI CUT (spill register) between the AXI CDC and the MIG to
      // reduce timing pressure
      axi_cut #(
        .Bypass     ( 1'b0  ),
        .aw_chan_t  ( axi_soc_aw_chan_t  ),
        .w_chan_t   ( axi_soc_w_chan_t   ),
        .b_chan_t   ( axi_soc_b_chan_t   ),
        .ar_chan_t  ( axi_soc_ar_chan_t  ),
        .r_chan_t   ( axi_soc_r_chan_t   ),
        .axi_req_t  ( axi_soc_req_t      ),
        .axi_resp_t ( axi_soc_resp_t     )
      ) i_axi_cut_soc_dram (
        .clk_i      ( soc_clk_i       ),
        .rst_ni     ( soc_resetn_i        ),

        .slv_req_i  ( soc_spill_req      ),
        .slv_resp_o ( soc_spill_rsp      ),

        .mst_req_o  ( spill_resizer_req            ),
        .mst_resp_i ( spill_resizer_rsp            )
      );
    end
    else
    begin
      assign spill_resizer_req = soc_spill_req;
      assign soc_spill_rsp = spill_resizer_rsp;
    end
  endgenerate

  /////////////////////////////////////
  // Instianciate data width resizer //
  /////////////////////////////////////

  generate
    if (cfg.EnResizer)
    begin
      axi_dw_converter #(
        .AxiMaxReads(8),
        .AxiSlvPortDataWidth($bits(spill_resizer_req.w.data)),
        .AxiMstPortDataWidth($bits(resizer_cdc_req.w.data)),
        .AxiAddrWidth ($bits(spill_resizer_req.ar.addr)),
        .AxiIdWidth ($bits(spill_resizer_req.ar.id)),
        // Common aw, ar, b
        .aw_chan_t       ( axi_soc_aw_chan_t ),
        .b_chan_t        ( axi_soc_b_chan_t ),
        .ar_chan_t       ( axi_soc_ar_chan_t ),
        // Master w, r
        .mst_w_chan_t    ( axi_ddr_w_chan_t  ),
        .mst_r_chan_t    ( axi_ddr_r_chan_t ),
        .axi_mst_req_t   ( axi_ddr_req_t ),
        .axi_mst_resp_t  ( axi_ddr_resp_t ),
        // Slave w, r
        .slv_w_chan_t    ( axi_soc_w_chan_t ),
        .slv_r_chan_t    ( axi_soc_r_chan_t ),
        .axi_slv_req_t   ( axi_soc_req_t ),
        .axi_slv_resp_t  ( axi_soc_resp_t )
      ) axi_dw_converter_ddr4 (
        .clk_i(soc_clk_i),
        .rst_ni(soc_resetn_i),
        .slv_req_i(spill_resizer_req),
        .slv_resp_o(spill_resizer_rsp),
        .mst_req_o(resizer_cdc_req),
        .mst_resp_i(resizer_cdc_rsp)
      );
    end
    else
    begin
      assign resizer_cdc_req = spill_resizer_req;
      assign spill_resizer_rsp = resizer_cdc_rsp;
    end
  endgenerate

  //////////////////////
  // Instianciate CDC //
  //////////////////////

  generate
    if (cfg.EnCDC)
    begin
    axi_cdc #(
      .aw_chan_t  ( axi_ddr_aw_chan_t ),
      .w_chan_t   ( axi_ddr_w_chan_t  ),
      .b_chan_t   ( axi_ddr_b_chan_t  ),
      .ar_chan_t  ( axi_ddr_ar_chan_t ),
      .r_chan_t   ( axi_ddr_r_chan_t  ),
      .axi_req_t  ( axi_ddr_req_t     ),
      .axi_resp_t ( axi_ddr_resp_t    ),
      .LogDepth   ( 3                 )
    ) i_axi_cdc_mig (
      .src_clk_i    ( soc_clk_i          ),
      .src_rst_ni   ( soc_resetn_i       ),
      .src_req_i    ( resizer_cdc_req    ),
      .src_resp_o   ( resizer_cdc_rsp    ),
      .dst_clk_i    ( dram_axi_clk       ),
      .dst_rst_ni   ( ~dram_rst_o        ),
      .dst_req_o    ( cdc_spill_req      ),
      .dst_resp_i   ( cdc_spill_rsp      )
    );
    end
    else
    begin
      assign cdc_spill_req = resizer_cdc_req;
      assign resizer_cdc_rsp = cdc_spill_rsp;
    end
  endgenerate

  //////////////////////////
  // Instianciate Spill 1 //
  //////////////////////////

  generate
    if (cfg.EnSpill1)
    begin
      axi_cut #(
        .Bypass     ( 1'b0  ),
        .aw_chan_t  ( axi_ddr_aw_chan_t  ),
        .w_chan_t   ( axi_ddr_w_chan_t   ),
        .b_chan_t   ( axi_ddr_b_chan_t   ),
        .ar_chan_t  ( axi_ddr_ar_chan_t  ),
        .r_chan_t   ( axi_ddr_r_chan_t   ),
        .axi_req_t  ( axi_ddr_req_t      ),
        .axi_resp_t ( axi_ddr_resp_t     )
      ) i_axi_cut_dw_dram (
        .clk_i      ( dram_axi_clk       ),
        .rst_ni     ( ~dram_rst_o        ),

        .slv_req_i  ( cdc_spill_req      ),
        .slv_resp_o ( cdc_spill_rsp      ),

        .mst_req_o  ( spill_dram_req     ),
        .mst_resp_i ( spill_dram_rsp     )
      );
    end
    else
    begin
      assign spill_dram_req = cdc_spill_req;
      assign cdc_spill_rsp = spill_dram_rsp;
    end
  endgenerate


  ///////////////////////
  // Instianciate DDR4 //
  ///////////////////////

`ifdef USE_DDR4

  // Resize addresses and IDs

  logic [5:0] spill_dram_req_awid;
  logic [5:0] spill_dram_req_arid;
  logic [5:0] spill_dram_rsp_bid;
  logic [5:0] spill_dram_rsp_rid;
  logic [31:0] spill_dram_req_awaddr;
  logic [31:0] spill_dram_req_araddr;

  assign spill_dram_req_awaddr = spill_dram_req.aw.addr[31:0];
  assign spill_dram_req_araddr = spill_dram_req.ar.addr[31:0];

  assign spill_dram_req_awid = {2'b0, spill_dram_req.aw.id};
  assign spill_dram_req_arid = {2'b0, spill_dram_req.ar.id};
  assign spill_dram_rsp.b.id = spill_dram_rsp_bid[$bits(spill_dram_rsp.b.id)-1:0];
  assign spill_dram_rsp.r.id = spill_dram_rsp_rid[$bits(spill_dram_rsp.r.id)-1:0];
  assign spill_dram_rsp.b.user = '0;
  assign spill_dram_rsp.r.user = '0;

  // Instanciate RAM

xlnx_mig_ddr4 i_dram (
    // Rst
    .   sys_rst                     ( sys_rst_i      ),
    .   c0_ddr4_aresetn             ( soc_resetn_i   ),
    // Clk rst out
    .   c0_ddr4_ui_clk              ( dram_axi_clk   ),
    .   c0_ddr4_ui_clk_sync_rst     ( dram_rst_o     ),
    // Axi
    .   c0_ddr4_s_axi_awid          ( spill_dram_req_awid             ),
    .   c0_ddr4_s_axi_awaddr        ( spill_dram_req_awaddr           ),
    .   c0_ddr4_s_axi_awlen         ( spill_dram_req.aw.len           ),
    .   c0_ddr4_s_axi_awsize        ( spill_dram_req.aw.size          ),
    .   c0_ddr4_s_axi_awburst       ( spill_dram_req.aw.burst         ),
    .   c0_ddr4_s_axi_awlock        ( spill_dram_req.aw.lock          ),
    .   c0_ddr4_s_axi_awcache       ( spill_dram_req.aw.cache         ),
    .   c0_ddr4_s_axi_awprot        ( spill_dram_req.aw.prot          ),
    .   c0_ddr4_s_axi_awqos         ( spill_dram_req.aw.qos           ),
    .   c0_ddr4_s_axi_awvalid       ( spill_dram_req.aw_valid         ),
    .   c0_ddr4_s_axi_awready       ( spill_dram_rsp.aw_ready         ),
    .   c0_ddr4_s_axi_wdata         ( spill_dram_req.w.data           ),
    .   c0_ddr4_s_axi_wstrb         ( spill_dram_req.w.strb           ),
    .   c0_ddr4_s_axi_wlast         ( spill_dram_req.w.last           ),
    .   c0_ddr4_s_axi_wvalid        ( spill_dram_req.w_valid          ),
    .   c0_ddr4_s_axi_wready        ( spill_dram_rsp.w_ready          ),
    .   c0_ddr4_s_axi_bready        ( spill_dram_req.b_ready          ),
    .   c0_ddr4_s_axi_bid           ( spill_dram_rsp_bid              ),
    .   c0_ddr4_s_axi_bresp         ( spill_dram_rsp.b.resp           ),
    .   c0_ddr4_s_axi_bvalid        ( spill_dram_rsp.b_valid          ),
    .   c0_ddr4_s_axi_arid          ( spill_dram_req_arid             ),
    .   c0_ddr4_s_axi_araddr        ( spill_dram_req_araddr           ),
    .   c0_ddr4_s_axi_arlen         ( spill_dram_req.ar.len           ),
    .   c0_ddr4_s_axi_arsize        ( spill_dram_req.ar.size          ),
    .   c0_ddr4_s_axi_arburst       ( spill_dram_req.ar.burst         ),
    .   c0_ddr4_s_axi_arlock        ( spill_dram_req.ar.lock          ),
    .   c0_ddr4_s_axi_arcache       ( spill_dram_req.ar.cache         ),
    .   c0_ddr4_s_axi_arprot        ( spill_dram_req.ar.prot          ),
    .   c0_ddr4_s_axi_arqos         ( spill_dram_req.ar.qos           ),
    .   c0_ddr4_s_axi_arvalid       ( spill_dram_req.ar_valid         ),
    .   c0_ddr4_s_axi_arready       ( spill_dram_rsp.ar_ready         ),
    .   c0_ddr4_s_axi_rready        ( spill_dram_req.r_ready          ),
    .   c0_ddr4_s_axi_rid           ( spill_dram_rsp_rid              ),
    .   c0_ddr4_s_axi_rdata         ( spill_dram_rsp.r.data           ),
    .   c0_ddr4_s_axi_rresp         ( spill_dram_rsp.r.resp           ),
    .   c0_ddr4_s_axi_rlast         ( spill_dram_rsp.r.last           ),
    .   c0_ddr4_s_axi_rvalid        ( spill_dram_rsp.r_valid          ),
    // Axi ctrl
    .   c0_ddr4_s_axi_ctrl_awvalid  ( '0             ),
    .   c0_ddr4_s_axi_ctrl_awready  (                ),
    .   c0_ddr4_s_axi_ctrl_awaddr   ( '0             ),
    .   c0_ddr4_s_axi_ctrl_wvalid   ( '0             ),
    .   c0_ddr4_s_axi_ctrl_wready   (                ),
    .   c0_ddr4_s_axi_ctrl_wdata    ( '0             ),
    .   c0_ddr4_s_axi_ctrl_bvalid   (                ),
    .   c0_ddr4_s_axi_ctrl_bready   ( '0             ),
    .   c0_ddr4_s_axi_ctrl_bresp    (                ),
    .   c0_ddr4_s_axi_ctrl_arvalid  ( '0             ),
    .   c0_ddr4_s_axi_ctrl_arready  (                ),
    .   c0_ddr4_s_axi_ctrl_araddr   ( '0             ),
    .   c0_ddr4_s_axi_ctrl_rvalid   (                ),
    .   c0_ddr4_s_axi_ctrl_rready   ( '0             ),
    .   c0_ddr4_s_axi_ctrl_rdata    (                ),
    .   c0_ddr4_s_axi_ctrl_rresp    (                ),
    // Others
    .   c0_init_calib_complete      (                ), // keep open
    .   addn_ui_clkout1             ( dram_clk_o     ),
    .   dbg_clk                     (                ),
    .   c0_ddr4_interrupt           (                ),
    .   dbg_bus                     (                ),
    // Phy
    .*
);

`endif // USE_DDR4


  ///////////////////////
  // Instianciate DDR3 //
  ///////////////////////


`ifdef USE_DDR3

  // AXI is already on 200 MHz
  assign dram_clk_o = dram_axi_clk;

xlnx_mig_7_ddr3 i_dram (
    .sys_clk_p           ( sysclk_p                      ),
    .sys_clk_n           ( sysclk_n                      ),
    .sys_rst             ( sys_rst                       ),
    .ui_clk              ( dram_axi_clk                  ),
    .ui_clk_sync_rst     ( dram_rst_o                    ),
    .mmcm_locked         (                               ), // keep open
    .app_sr_req          ( '0                            ),
    .app_ref_req         ( '0                            ),
    .app_zq_req          ( '0                            ),
    .app_sr_active       (                               ), // keep open
    .app_ref_ack         (                               ), // keep open
    .app_zq_ack          (                               ), // keep open
    .aresetn             ( soc_resetn_i                  ),
    .s_axi_awid          ( spill_dram_req.aw.id          ),
    .s_axi_awaddr        ( spill_dram_req.aw.addr[29:0]  ),
    .s_axi_awlen         ( spill_dram_req.aw.len         ),
    .s_axi_awsize        ( spill_dram_req.aw.size        ),
    .s_axi_awburst       ( spill_dram_req.aw.burst       ),
    .s_axi_awlock        ( spill_dram_req.aw.lock        ),
    .s_axi_awcache       ( spill_dram_req.aw.cache       ),
    .s_axi_awprot        ( spill_dram_req.aw.prot        ),
    .s_axi_awqos         ( spill_dram_req.aw.qos         ),
    .s_axi_awvalid       ( spill_dram_req.aw_valid       ),
    .s_axi_awready       ( spill_dram_rsp.aw_ready       ),
    .s_axi_wdata         ( spill_dram_req.w.data         ),
    .s_axi_wstrb         ( spill_dram_req.w.strb         ),
    .s_axi_wlast         ( spill_dram_req.w.last         ),
    .s_axi_wvalid        ( spill_dram_req.w_valid        ),
    .s_axi_wready        ( spill_dram_rsp.w_ready        ),
    .s_axi_bready        ( spill_dram_req.b_ready        ),
    .s_axi_bid           ( spill_dram_rsp.b.id           ),
    .s_axi_bresp         ( spill_dram_rsp.b.resp         ),
    .s_axi_bvalid        ( spill_dram_rsp.b_valid        ),
    .s_axi_arid          ( spill_dram_req.ar.id          ),
    .s_axi_araddr        ( spill_dram_req.ar.addr[29:0]  ),
    .s_axi_arlen         ( spill_dram_req.ar.len         ),
    .s_axi_arsize        ( spill_dram_req.ar.size        ),
    .s_axi_arburst       ( spill_dram_req.ar.burst       ),
    .s_axi_arlock        ( spill_dram_req.ar.lock        ),
    .s_axi_arcache       ( spill_dram_req.ar.cache       ),
    .s_axi_arprot        ( spill_dram_req.ar.prot        ),
    .s_axi_arqos         ( spill_dram_req.ar.qos         ),
    .s_axi_arvalid       ( spill_dram_req.ar_valid       ),
    .s_axi_arready       ( spill_dram_rsp.ar_ready       ),
    .s_axi_rready        ( spill_dram_req.r_ready        ),
    .s_axi_rid           ( spill_dram_rsp.r.id           ),
    .s_axi_rdata         ( spill_dram_rsp.r.data         ),
    .s_axi_rresp         ( spill_dram_rsp.r.resp         ),
    .s_axi_rlast         ( spill_dram_rsp.r.last         ),
    .s_axi_rvalid        ( spill_dram_rsp.r_valid        ),
    .init_calib_complete (                               ),  // keep open
    .device_temp         (                               )   // keep open
  );
`endif // USE_DDR3

endmodule