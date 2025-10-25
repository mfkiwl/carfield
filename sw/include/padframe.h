// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Victor Isachi <victor.isachi@unibo.it>
//
// Padframe driver

#ifndef __PADFRAME_H
#define __PADFRAME_H

#include "io.h"
#include "car_memory_map.h"

inline void write_padframe_mux(uint8_t mux_sel_reg_offset, uint8_t mux_id){
  writew(mux_id, PADFRAME_BASE_ADDRESS + mux_sel_reg_offset);
}

void write_padframe_pen(uint8_t cfg_reg_offset, uint8_t pen){
  uint32_t config_reg = readw(PADFRAME_BASE_ADDRESS + cfg_reg_offset);
  config_reg = (config_reg & ~0x8 ) | ((pen & 0x1) << 3);
  writew(config_reg, PADFRAME_BASE_ADDRESS + cfg_reg_offset);
}

void write_padframe_psel(uint8_t cfg_reg_offset, uint8_t psel){
  uint32_t config_reg = readw(PADFRAME_BASE_ADDRESS + cfg_reg_offset);
  config_reg = (config_reg & ~0x10 ) | ((psel & 0x1) << 4);
  writew(config_reg, PADFRAME_BASE_ADDRESS + cfg_reg_offset);
}

void padframe_ethernet_cfg() {
  // Configuring padframe - mux
  write_padframe_mux(PADFRAME_CONFIG_MUXED_V_07_MUX_SEL, PADFRAME_MUXED_V_07_SEL_ETHERNET_RXCK);
  write_padframe_mux(PADFRAME_CONFIG_MUXED_V_08_MUX_SEL, PADFRAME_MUXED_V_08_SEL_ETHERNET_RXCTL);
  write_padframe_mux(PADFRAME_CONFIG_MUXED_V_09_MUX_SEL, PADFRAME_MUXED_V_09_SEL_ETHERNET_RXD_0);
  write_padframe_mux(PADFRAME_CONFIG_MUXED_V_10_MUX_SEL, PADFRAME_MUXED_V_10_SEL_ETHERNET_RXD_1);
  write_padframe_mux(PADFRAME_CONFIG_MUXED_V_11_MUX_SEL, PADFRAME_MUXED_V_11_SEL_ETHERNET_RXD_2);
  write_padframe_mux(PADFRAME_CONFIG_MUXED_V_12_MUX_SEL, PADFRAME_MUXED_V_12_SEL_ETHERNET_RXD_3);
  write_padframe_mux(PADFRAME_CONFIG_MUXED_V_13_MUX_SEL, PADFRAME_MUXED_V_13_SEL_ETHERNET_TXCK);
  write_padframe_mux(PADFRAME_CONFIG_MUXED_V_14_MUX_SEL, PADFRAME_MUXED_V_14_SEL_ETHERNET_TXCTL);
  write_padframe_mux(PADFRAME_CONFIG_MUXED_V_15_MUX_SEL, PADFRAME_MUXED_V_15_SEL_ETHERNET_TXD_0);
  write_padframe_mux(PADFRAME_CONFIG_MUXED_V_16_MUX_SEL, PADFRAME_MUXED_V_16_SEL_ETHERNET_TXD_1);
  write_padframe_mux(PADFRAME_CONFIG_MUXED_V_17_MUX_SEL, PADFRAME_MUXED_V_17_SEL_ETHERNET_TXD_2);
  write_padframe_mux(PADFRAME_CONFIG_MUXED_H_00_MUX_SEL, PADFRAME_MUXED_H_00_SEL_ETHERNET_TXD_3);
  write_padframe_mux(PADFRAME_CONFIG_MUXED_H_01_MUX_SEL, PADFRAME_MUXED_H_01_SEL_ETHERNET_MD);
  write_padframe_mux(PADFRAME_CONFIG_MUXED_H_02_MUX_SEL, PADFRAME_MUXED_H_02_SEL_ETHERNET_MDC);
  write_padframe_mux(PADFRAME_CONFIG_MUXED_H_03_MUX_SEL, PADFRAME_MUXED_H_03_SEL_ETHERNET_RST_N);
  // Configuring padframe - pullup
  write_padframe_pen(PADFRAME_CONFIG_MUXED_V_07_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_V_07_CFG, 0x1);
  write_padframe_pen(PADFRAME_CONFIG_MUXED_V_08_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_V_08_CFG, 0x1);
  write_padframe_pen(PADFRAME_CONFIG_MUXED_V_09_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_V_09_CFG, 0x1);
  write_padframe_pen(PADFRAME_CONFIG_MUXED_V_10_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_V_10_CFG, 0x1);
  write_padframe_pen(PADFRAME_CONFIG_MUXED_V_11_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_V_11_CFG, 0x1);
  write_padframe_pen(PADFRAME_CONFIG_MUXED_V_12_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_V_12_CFG, 0x1);
  write_padframe_pen(PADFRAME_CONFIG_MUXED_V_13_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_V_13_CFG, 0x1);
  write_padframe_pen(PADFRAME_CONFIG_MUXED_V_14_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_V_14_CFG, 0x1);
  write_padframe_pen(PADFRAME_CONFIG_MUXED_V_15_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_V_15_CFG, 0x1);
  write_padframe_pen(PADFRAME_CONFIG_MUXED_V_16_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_V_16_CFG, 0x1);
  write_padframe_pen(PADFRAME_CONFIG_MUXED_V_17_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_V_17_CFG, 0x1);
  write_padframe_pen(PADFRAME_CONFIG_MUXED_H_00_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_H_00_CFG, 0x1);
  write_padframe_pen(PADFRAME_CONFIG_MUXED_H_01_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_H_01_CFG, 0x1);
  write_padframe_pen(PADFRAME_CONFIG_MUXED_H_02_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_H_02_CFG, 0x1);
  write_padframe_pen(PADFRAME_CONFIG_MUXED_H_03_CFG, 0x1); write_padframe_psel(PADFRAME_CONFIG_MUXED_H_03_CFG, 0x1);
}

#endif /*__PADFRAME_H*/
