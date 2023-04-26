# Carfield

This repository hosts the Carfield SoC platform, a mixed-criticality SoC
targeting the automotive domain. It uses
[`Cheshire`](https://github.com/pulp-platform/cheshire) as main host domain. It
is developed as part of the PULP project, a joint effort between ETH Zurich and
the University of Bologna.

## Disclaimer

This project is still considered to be in early development; some parts may not
yet be functional, and existing interfaces and conventions may be broken without
prior notice. We target a formal release in the very near future.

## Dependencies
To handle project dependencies, you can use
[bender](https://github.com/pulp-platform/bender).

## Carfield Initialization
To initialize Carfield, do the following:
 * Export the `RISCV` environment variable to the RISC-V toolchain. To work on IIS machines,
 do `export RISCV=/usr/pack/riscv-1.0-kgf/riscv64-gcc-11.2.0`.
 * Execute the commands:

   ```
   make car-checkout-deps
   make car-init
   ```

   They will take care of:

   ** Clone all the Carfield dependencies;
   ** Initialize the [Cheshire SoC](https://github.com/pulp-platform/cheshire). This can be
	  done separately by running `make chs-init`
   ** Downloads the Hyperram models from the iis-gitlab. If you don't have access to it, you
	  can also download the freely-available Hyperram models from
	  [here](https://www.cypress.com/documentation/models/verilog/s27kl0641-s27ks0641-verilog)
	  and unzip them according to the bender.

## Simulation

Follow these steps to launch a Carfield simulation:

* Generate the compile scripts for Questasim and compile Carfield.

   ```
   make car-hw-build
   ```

  It is also possible to run `make -B scripts/carfield_compile.tcl` to
  re-generate the compile script after hardware modfications.

* Compile tests for Carfield. Tests resides in `sw/tests`.

  ```
  make car-sw-all
  ```

* Simulate a binary in RTL. The current supported bootmodes from Cheshire are:

  | Bootmode | Preload mode | Action |
  | --- | --- | --- |
  | 0 | 0 | Passive bootmode, JTAG preload |
  | 0 | 1 | Passive bootmode, Serial Link preload |
  | 0 | 2 | Passive bootmode, UART preload |
  | 1 | - | Autonomous bootmode, SPI SD card |
  | 2 | - | Autonomous bootmode, SPI flash |
  | 3 | - | Autonomous bootmode, I2C EEPROM |

  `Bootmode` indicates the available bootmodes in Cheshire, while `Preload mode`
  indicates the type of preload, if any is needed. For RTL simulation, bootmodes
  0, 2 and 3 are supported. SPI SD card bootmode is supported on FPGA emulation.

  To launch an RTL simulation with the selected boot and preload modes, type:

  | Bootmode | Command |
  | --- | --- |
  | 0 | `make car-hw-sim BOOTMODE=<bootmode> PRELMODE=<prelmode> CHS_BINARY=<chs_binary_path>.car.elf SECD_BINARY=<secd_binary_path> SAFED_BINARY=<safed_binary_path>`  |
  | 1, 2, 3 | `make car-hw-sim BOOTMODE=<bootmode> PRELMODE=<prelmode> CHS_IMAGE=<chs_binary_path>.car.memh`  |

  Default is passive bootmode with serial link preload.

## License

Unless specified otherwise in the respective file headers, all code checked into
this repository is made available under a permissive license. All hardware
sources and tool scripts are licensed under the Solderpad Hardware License 0.51
(see `LICENSE`) with the exception of generated register file code (e.g.
`hw/regs/*.sv`), which is generated by a fork of lowRISC's
[`regtool`](https://github.com/lowRISC/opentitan/blob/master/util/regtool.py)
and licensed under Apache 2.0. All software sources are licensed under Apache
2.0.
