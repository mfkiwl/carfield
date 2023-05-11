# Copyright 2021 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Author: Yvan Tortorella <yvan.tortorella@unibo.it>
# Author: Matteo Perotti <mperotti@iis.ee.ethz.ch>

# bender targets
synth_targs += -t asic
synth_targs += -t spyglass
synth_targs += -t cva6_test
synth_targs += -t synthesis
synth_targs += -t top_level
synth_targs += -t intel16
synth_targs += -t scm_use_latch_scm
synth_targs += -t cluster_standalone
synth_targs += -t cv64a6_imafdc_sv39

# bender defines
synth_defs += -D SPYGLASS
synth_defs += -D SYNTHESIS
synth_defs += -D EXCLUDE_PADFRAME
