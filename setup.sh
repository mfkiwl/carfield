# Copyright 2023 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

#!/bin/bash

export PATH=/usr/pack/riscv-1.0-kgf/riscv64-gcc-11.2.0/bin:$PATH
export RISCV=/usr/pack/riscv-1.0-kgf/riscv64-gcc-11.2.0
export RISCV_GCC_BINROOT=$RISCV/bin

grep -rl "BlockAw = 27" $(bender path opentitan_peripherals)/src/rv_plic/rtl/* | xargs sed -i 's/BlockAw = 27/BlockAw = 26/g'
cp sw/cheshire/mbox_test.c cheshire/sw/tests/
cp sw/cheshire/crt0.S cheshire/sw/lib/

