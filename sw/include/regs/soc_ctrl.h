// Generated register defines for carfield

// Copyright information found in source file:
// Copyright 2023 ETH Zurich and University of Bologna.

// Licensing information found in source file:
// 
// SPDX-License-Identifier: SHL-0.51

#ifndef _CARFIELD_REG_DEFS_
#define _CARFIELD_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define CARFIELD_PARAM_REG_WIDTH 32

// Cheshire sha256 commit
#define CARFIELD_VERSION0_REG_OFFSET 0x0

// Safety Island sha256 commit
#define CARFIELD_VERSION1_REG_OFFSET 0x4

// Security Island sha256 commit
#define CARFIELD_VERSION2_REG_OFFSET 0x8

// PULP Cluster sha256 commit
#define CARFIELD_VERSION3_REG_OFFSET 0xc

// Spatz CLuster sha256 commit
#define CARFIELD_VERSION4_REG_OFFSET 0x10

// Boot mode
#define CARFIELD_BOOT_MODE_REG_OFFSET 0x14
#define CARFIELD_BOOT_MODE_BOOT_MODE_MASK 0x7
#define CARFIELD_BOOT_MODE_BOOT_MODE_OFFSET 0
#define CARFIELD_BOOT_MODE_BOOT_MODE_FIELD \
  ((bitfield_field32_t) { .mask = CARFIELD_BOOT_MODE_BOOT_MODE_MASK, .index = CARFIELD_BOOT_MODE_BOOT_MODE_OFFSET })

// JEDEC ID CODE -TODO assign-
#define CARFIELD_JEDEC_IDCODE_REG_OFFSET 0x18

// Scratch
#define CARFIELD_GENERIC_SCRATCH0_REG_OFFSET 0x1c

// Scratch
#define CARFIELD_GENERIC_SCRATCH1_REG_OFFSET 0x20

// Host Domain reset -active high, inverted in HW-
#define CARFIELD_HOST_RST_REG_OFFSET 0x24
#define CARFIELD_HOST_RST_HOST_RST_BIT 0

// Periph Domain reset -active high, inverted in HW-
#define CARFIELD_PERIPH_RST_REG_OFFSET 0x28
#define CARFIELD_PERIPH_RST_PERIPH_RST_BIT 0

// Safety Island reset -active high, inverted in HW-
#define CARFIELD_SAFETY_ISLAND_RST_REG_OFFSET 0x2c
#define CARFIELD_SAFETY_ISLAND_RST_SAFETY_ISLAND_RST_BIT 0

// Security Island reset -active high, inverted in HW-
#define CARFIELD_SECURITY_ISLAND_RST_REG_OFFSET 0x30
#define CARFIELD_SECURITY_ISLAND_RST_SECURITY_ISLAND_RST_BIT 0

// PULP Cluster reset -active high, inverted in HW-
#define CARFIELD_PULP_CLUSTER_RST_REG_OFFSET 0x34
#define CARFIELD_PULP_CLUSTER_RST_PULP_CLUSTER_RST_BIT 0

// Spatz Cluster reset -active high, inverted in HW-
#define CARFIELD_SPATZ_CLUSTER_RST_REG_OFFSET 0x38
#define CARFIELD_SPATZ_CLUSTER_RST_SPATZ_CLUSTER_RST_BIT 0

// L2 reset -active high, inverted in HW-
#define CARFIELD_L2_RST_REG_OFFSET 0x3c
#define CARFIELD_L2_RST_L2_RST_BIT 0

// Host Domain AXI isolate
#define CARFIELD_HOST_ISOLATE_REG_OFFSET 0x40
#define CARFIELD_HOST_ISOLATE_HOST_ISOLATE_BIT 0

// Periph Domain  AXI isolate
#define CARFIELD_PERIPH_ISOLATE_REG_OFFSET 0x44
#define CARFIELD_PERIPH_ISOLATE_PERIPH_ISOLATE_BIT 0

// Safety Island AXI isolate
#define CARFIELD_SAFETY_ISLAND_ISOLATE_REG_OFFSET 0x48
#define CARFIELD_SAFETY_ISLAND_ISOLATE_SAFETY_ISLAND_ISOLATE_BIT 0

// Security Island AXI isolate
#define CARFIELD_SECURITY_ISLAND_ISOLATE_REG_OFFSET 0x4c
#define CARFIELD_SECURITY_ISLAND_ISOLATE_SECURITY_ISLAND_ISOLATE_BIT 0

// PULP Cluster AXI isolate
#define CARFIELD_PULP_CLUSTER_ISOLATE_REG_OFFSET 0x50
#define CARFIELD_PULP_CLUSTER_ISOLATE_PULP_CLUSTER_ISOLATE_BIT 0

// Spatz Cluster  AXI isolate
#define CARFIELD_SPATZ_CLUSTER_ISOLATE_REG_OFFSET 0x54
#define CARFIELD_SPATZ_CLUSTER_ISOLATE_SPATZ_CLUSTER_ISOLATE_BIT 0

// Host Domain AXI isolate status
#define CARFIELD_HOST_ISOLATE_STATUS_REG_OFFSET 0x58
#define CARFIELD_HOST_ISOLATE_STATUS_HOST_ISOLATE_STATUS_BIT 0

// Periph Domain AXI isolate status
#define CARFIELD_PERIPH_ISOLATE_STATUS_REG_OFFSET 0x5c
#define CARFIELD_PERIPH_ISOLATE_STATUS_PERIPH_ISOLATE_STATUS_BIT 0

// Safety Island AXI isolate status
#define CARFIELD_SAFETY_ISLAND_ISOLATE_STATUS_REG_OFFSET 0x60
#define CARFIELD_SAFETY_ISLAND_ISOLATE_STATUS_SAFETY_ISLAND_ISOLATE_STATUS_BIT 0

// Security Island AXI isolate status
#define CARFIELD_SECURITY_ISLAND_ISOLATE_STATUS_REG_OFFSET 0x64
#define CARFIELD_SECURITY_ISLAND_ISOLATE_STATUS_SECURITY_ISLAND_ISOLATE_STATUS_BIT \
  0

// PULP Cluster AXI isolate status
#define CARFIELD_PULP_CLUSTER_ISOLATE_STATUS_REG_OFFSET 0x68
#define CARFIELD_PULP_CLUSTER_ISOLATE_STATUS_PULP_CLUSTER_ISOLATE_STATUS_BIT 0

// Spatz Cluster AXI isolate status
#define CARFIELD_SPATZ_CLUSTER_ISOLATE_STATUS_REG_OFFSET 0x6c
#define CARFIELD_SPATZ_CLUSTER_ISOLATE_STATUS_SPATZ_CLUSTER_ISOLATE_STATUS_BIT 0

// Periph Domain clk gate enable
#define CARFIELD_PERIPH_CLK_EN_REG_OFFSET 0x70
#define CARFIELD_PERIPH_CLK_EN_PERIPH_CLK_EN_BIT 0

// Safety Island clk gate enable
#define CARFIELD_SAFETY_ISLAND_CLK_EN_REG_OFFSET 0x74
#define CARFIELD_SAFETY_ISLAND_CLK_EN_SAFETY_ISLAND_CLK_EN_BIT 0

// Security Island clk gate enable
#define CARFIELD_SECURITY_ISLAND_CLK_EN_REG_OFFSET 0x78
#define CARFIELD_SECURITY_ISLAND_CLK_EN_SECURITY_ISLAND_CLK_EN_BIT 0

// PULP Cluster clk gate enable
#define CARFIELD_PULP_CLUSTER_CLK_EN_REG_OFFSET 0x7c
#define CARFIELD_PULP_CLUSTER_CLK_EN_PULP_CLUSTER_CLK_EN_BIT 0

// Spatz Cluster clk gate enable
#define CARFIELD_SPATZ_CLUSTER_CLK_EN_REG_OFFSET 0x80
#define CARFIELD_SPATZ_CLUSTER_CLK_EN_SPATZ_CLUSTER_CLK_EN_BIT 0

// Shared L2 memory clk gate enable
#define CARFIELD_L2_CLK_EN_REG_OFFSET 0x84
#define CARFIELD_L2_CLK_EN_L2_CLK_EN_BIT 0

// Periph Domain pll select (0 -> host pll, 1 -> alt PLL, 2 -> per pll)
#define CARFIELD_PERIPH_CLK_SEL_REG_OFFSET 0x88
#define CARFIELD_PERIPH_CLK_SEL_PERIPH_CLK_SEL_MASK 0x3
#define CARFIELD_PERIPH_CLK_SEL_PERIPH_CLK_SEL_OFFSET 0
#define CARFIELD_PERIPH_CLK_SEL_PERIPH_CLK_SEL_FIELD \
  ((bitfield_field32_t) { .mask = CARFIELD_PERIPH_CLK_SEL_PERIPH_CLK_SEL_MASK, .index = CARFIELD_PERIPH_CLK_SEL_PERIPH_CLK_SEL_OFFSET })

// Safety Island pll select (0 -> host pll, 1 -> alt PLL, 2 -> per pll)
#define CARFIELD_SAFETY_ISLAND_CLK_SEL_REG_OFFSET 0x8c
#define CARFIELD_SAFETY_ISLAND_CLK_SEL_SAFETY_ISLAND_CLK_SEL_MASK 0x3
#define CARFIELD_SAFETY_ISLAND_CLK_SEL_SAFETY_ISLAND_CLK_SEL_OFFSET 0
#define CARFIELD_SAFETY_ISLAND_CLK_SEL_SAFETY_ISLAND_CLK_SEL_FIELD \
  ((bitfield_field32_t) { .mask = CARFIELD_SAFETY_ISLAND_CLK_SEL_SAFETY_ISLAND_CLK_SEL_MASK, .index = CARFIELD_SAFETY_ISLAND_CLK_SEL_SAFETY_ISLAND_CLK_SEL_OFFSET })

// Security Island pll select (0 -> host pll, 1 -> alt PLL, 2 -> per pll)
#define CARFIELD_SECURITY_ISLAND_CLK_SEL_REG_OFFSET 0x90
#define CARFIELD_SECURITY_ISLAND_CLK_SEL_SECURITY_ISLAND_CLK_SEL_MASK 0x3
#define CARFIELD_SECURITY_ISLAND_CLK_SEL_SECURITY_ISLAND_CLK_SEL_OFFSET 0
#define CARFIELD_SECURITY_ISLAND_CLK_SEL_SECURITY_ISLAND_CLK_SEL_FIELD \
  ((bitfield_field32_t) { .mask = CARFIELD_SECURITY_ISLAND_CLK_SEL_SECURITY_ISLAND_CLK_SEL_MASK, .index = CARFIELD_SECURITY_ISLAND_CLK_SEL_SECURITY_ISLAND_CLK_SEL_OFFSET })

// PULP Cluster pll select (0 -> host pll, 1 -> alt PLL, 2 -> per pll)
#define CARFIELD_PULP_CLUSTER_CLK_SEL_REG_OFFSET 0x94
#define CARFIELD_PULP_CLUSTER_CLK_SEL_PULP_CLUSTER_CLK_SEL_MASK 0x3
#define CARFIELD_PULP_CLUSTER_CLK_SEL_PULP_CLUSTER_CLK_SEL_OFFSET 0
#define CARFIELD_PULP_CLUSTER_CLK_SEL_PULP_CLUSTER_CLK_SEL_FIELD \
  ((bitfield_field32_t) { .mask = CARFIELD_PULP_CLUSTER_CLK_SEL_PULP_CLUSTER_CLK_SEL_MASK, .index = CARFIELD_PULP_CLUSTER_CLK_SEL_PULP_CLUSTER_CLK_SEL_OFFSET })

// Spatz Cluster pll select (0 -> host pll, 1 -> alt PLL, 2 -> per pll)
#define CARFIELD_SPATZ_CLUSTER_CLK_SEL_REG_OFFSET 0x98
#define CARFIELD_SPATZ_CLUSTER_CLK_SEL_SPATZ_CLUSTER_CLK_SEL_MASK 0x3
#define CARFIELD_SPATZ_CLUSTER_CLK_SEL_SPATZ_CLUSTER_CLK_SEL_OFFSET 0
#define CARFIELD_SPATZ_CLUSTER_CLK_SEL_SPATZ_CLUSTER_CLK_SEL_FIELD \
  ((bitfield_field32_t) { .mask = CARFIELD_SPATZ_CLUSTER_CLK_SEL_SPATZ_CLUSTER_CLK_SEL_MASK, .index = CARFIELD_SPATZ_CLUSTER_CLK_SEL_SPATZ_CLUSTER_CLK_SEL_OFFSET })

// L2 Memory pll select (0 -> host pll, 1 -> alt PLL, 2 -> per pll)
#define CARFIELD_L2_CLK_SEL_REG_OFFSET 0x9c
#define CARFIELD_L2_CLK_SEL_L2_CLK_SEL_MASK 0x3
#define CARFIELD_L2_CLK_SEL_L2_CLK_SEL_OFFSET 0
#define CARFIELD_L2_CLK_SEL_L2_CLK_SEL_FIELD \
  ((bitfield_field32_t) { .mask = CARFIELD_L2_CLK_SEL_L2_CLK_SEL_MASK, .index = CARFIELD_L2_CLK_SEL_L2_CLK_SEL_OFFSET })

// Periph Domain clk divider value
#define CARFIELD_PERIPH_CLK_DIV_VALUE_REG_OFFSET 0xa0
#define CARFIELD_PERIPH_CLK_DIV_VALUE_PERIPH_CLK_DIV_VALUE_MASK 0xffffff
#define CARFIELD_PERIPH_CLK_DIV_VALUE_PERIPH_CLK_DIV_VALUE_OFFSET 0
#define CARFIELD_PERIPH_CLK_DIV_VALUE_PERIPH_CLK_DIV_VALUE_FIELD \
  ((bitfield_field32_t) { .mask = CARFIELD_PERIPH_CLK_DIV_VALUE_PERIPH_CLK_DIV_VALUE_MASK, .index = CARFIELD_PERIPH_CLK_DIV_VALUE_PERIPH_CLK_DIV_VALUE_OFFSET })

// Safety Island clk divider value
#define CARFIELD_SAFETY_ISLAND_CLK_DIV_VALUE_REG_OFFSET 0xa4
#define CARFIELD_SAFETY_ISLAND_CLK_DIV_VALUE_SAFETY_ISLAND_CLK_DIV_VALUE_MASK \
  0xffffff
#define CARFIELD_SAFETY_ISLAND_CLK_DIV_VALUE_SAFETY_ISLAND_CLK_DIV_VALUE_OFFSET \
  0
#define CARFIELD_SAFETY_ISLAND_CLK_DIV_VALUE_SAFETY_ISLAND_CLK_DIV_VALUE_FIELD \
  ((bitfield_field32_t) { .mask = CARFIELD_SAFETY_ISLAND_CLK_DIV_VALUE_SAFETY_ISLAND_CLK_DIV_VALUE_MASK, .index = CARFIELD_SAFETY_ISLAND_CLK_DIV_VALUE_SAFETY_ISLAND_CLK_DIV_VALUE_OFFSET })

// Security Island clk divider value
#define CARFIELD_SECURITY_ISLAND_CLK_DIV_VALUE_REG_OFFSET 0xa8
#define CARFIELD_SECURITY_ISLAND_CLK_DIV_VALUE_SECURITY_ISLAND_CLK_DIV_VALUE_MASK \
  0xffffff
#define CARFIELD_SECURITY_ISLAND_CLK_DIV_VALUE_SECURITY_ISLAND_CLK_DIV_VALUE_OFFSET \
  0
#define CARFIELD_SECURITY_ISLAND_CLK_DIV_VALUE_SECURITY_ISLAND_CLK_DIV_VALUE_FIELD \
  ((bitfield_field32_t) { .mask = CARFIELD_SECURITY_ISLAND_CLK_DIV_VALUE_SECURITY_ISLAND_CLK_DIV_VALUE_MASK, .index = CARFIELD_SECURITY_ISLAND_CLK_DIV_VALUE_SECURITY_ISLAND_CLK_DIV_VALUE_OFFSET })

// PULP Cluster clk divider value
#define CARFIELD_PULP_CLUSTER_CLK_DIV_VALUE_REG_OFFSET 0xac
#define CARFIELD_PULP_CLUSTER_CLK_DIV_VALUE_PULP_CLUSTER_CLK_DIV_VALUE_MASK \
  0xffffff
#define CARFIELD_PULP_CLUSTER_CLK_DIV_VALUE_PULP_CLUSTER_CLK_DIV_VALUE_OFFSET 0
#define CARFIELD_PULP_CLUSTER_CLK_DIV_VALUE_PULP_CLUSTER_CLK_DIV_VALUE_FIELD \
  ((bitfield_field32_t) { .mask = CARFIELD_PULP_CLUSTER_CLK_DIV_VALUE_PULP_CLUSTER_CLK_DIV_VALUE_MASK, .index = CARFIELD_PULP_CLUSTER_CLK_DIV_VALUE_PULP_CLUSTER_CLK_DIV_VALUE_OFFSET })

// Spatz Cluster clk divider value
#define CARFIELD_SPATZ_CLUSTER_CLK_DIV_VALUE_REG_OFFSET 0xb0
#define CARFIELD_SPATZ_CLUSTER_CLK_DIV_VALUE_SPATZ_CLUSTER_CLK_DIV_VALUE_MASK \
  0xffffff
#define CARFIELD_SPATZ_CLUSTER_CLK_DIV_VALUE_SPATZ_CLUSTER_CLK_DIV_VALUE_OFFSET \
  0
#define CARFIELD_SPATZ_CLUSTER_CLK_DIV_VALUE_SPATZ_CLUSTER_CLK_DIV_VALUE_FIELD \
  ((bitfield_field32_t) { .mask = CARFIELD_SPATZ_CLUSTER_CLK_DIV_VALUE_SPATZ_CLUSTER_CLK_DIV_VALUE_MASK, .index = CARFIELD_SPATZ_CLUSTER_CLK_DIV_VALUE_SPATZ_CLUSTER_CLK_DIV_VALUE_OFFSET })

// L2 Memory clk divider value
#define CARFIELD_L2_CLK_DIV_VALUE_REG_OFFSET 0xb4
#define CARFIELD_L2_CLK_DIV_VALUE_L2_CLK_DIV_VALUE_MASK 0xffffff
#define CARFIELD_L2_CLK_DIV_VALUE_L2_CLK_DIV_VALUE_OFFSET 0
#define CARFIELD_L2_CLK_DIV_VALUE_L2_CLK_DIV_VALUE_FIELD \
  ((bitfield_field32_t) { .mask = CARFIELD_L2_CLK_DIV_VALUE_L2_CLK_DIV_VALUE_MASK, .index = CARFIELD_L2_CLK_DIV_VALUE_L2_CLK_DIV_VALUE_OFFSET })

// Host Domain fetch enable
#define CARFIELD_HOST_FETCH_ENABLE_REG_OFFSET 0xb8
#define CARFIELD_HOST_FETCH_ENABLE_HOST_FETCH_ENABLE_BIT 0

// Safety Island fetch enable
#define CARFIELD_SAFETY_ISLAND_FETCH_ENABLE_REG_OFFSET 0xbc
#define CARFIELD_SAFETY_ISLAND_FETCH_ENABLE_SAFETY_ISLAND_FETCH_ENABLE_BIT 0

// Security Island fetch enable
#define CARFIELD_SECURITY_ISLAND_FETCH_ENABLE_REG_OFFSET 0xc0
#define CARFIELD_SECURITY_ISLAND_FETCH_ENABLE_SECURITY_ISLAND_FETCH_ENABLE_BIT 0

// PULP Cluster fetch enable
#define CARFIELD_PULP_CLUSTER_FETCH_ENABLE_REG_OFFSET 0xc4
#define CARFIELD_PULP_CLUSTER_FETCH_ENABLE_PULP_CLUSTER_FETCH_ENABLE_BIT 0

// Spatz Cluster fetch enable
#define CARFIELD_SPATZ_CLUSTER_FETCH_ENABLE_REG_OFFSET 0xc8
#define CARFIELD_SPATZ_CLUSTER_FETCH_ENABLE_SPATZ_CLUSTER_FETCH_ENABLE_BIT 0

// Host boot address
#define CARFIELD_HOST_BOOT_ADDR_REG_OFFSET 0xcc

// Safety Island boot address
#define CARFIELD_SAFETY_ISLAND_BOOT_ADDR_REG_OFFSET 0xd0

// Security Island boot address
#define CARFIELD_SECURITY_ISLAND_BOOT_ADDR_REG_OFFSET 0xd4

// PULP Cluster boot address
#define CARFIELD_PULP_CLUSTER_BOOT_ADDR_REG_OFFSET 0xd8

// Spatz Cluster boot address
#define CARFIELD_SPATZ_CLUSTER_BOOT_ADDR_REG_OFFSET 0xdc

// PULP Cluster boot enable
#define CARFIELD_PULP_CLUSTER_BOOT_ENABLE_REG_OFFSET 0xe0
#define CARFIELD_PULP_CLUSTER_BOOT_ENABLE_PULP_CLUSTER_BOOT_ENABLE_BIT 0

// PULP Cluster busy
#define CARFIELD_PULP_CLUSTER_BUSY_REG_OFFSET 0xe4
#define CARFIELD_PULP_CLUSTER_BUSY_PULP_CLUSTER_BUSY_BIT 0

// PULP Cluster end of computation
#define CARFIELD_PULP_CLUSTER_EOC_REG_OFFSET 0xe8
#define CARFIELD_PULP_CLUSTER_EOC_PULP_CLUSTER_EOC_BIT 0

// L2 RAM cfg pins -margin adjustments-
#define CARFIELD_L2_SRAM_CONFIG0_REG_OFFSET 0xec

// L2 RAM cfg pins -margin adjustments-
#define CARFIELD_L2_SRAM_CONFIG1_REG_OFFSET 0xf0

// L2 RAM cfg pins -margin adjustments-
#define CARFIELD_L2_SRAM_CONFIG2_REG_OFFSET 0xf4

// L2 RAM cfg pins -margin adjustments-
#define CARFIELD_L2_SRAM_CONFIG3_REG_OFFSET 0xf8

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _CARFIELD_REG_DEFS_
// End generated register defines for carfield