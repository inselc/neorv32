## IMEM implementation for Intel MAX10 FPGA using M9K ROM

This VHDL module provides an alternative IMEM implementation for Intel MAX10-series FPGA (or similar), using M9K Block-RAM in **read-only** configuration. 

### Usage and configuration

* Ensure the `MEM_INT_IMEM_ROM` generic is set to `true`, and `BOOTLOADER_USE` is set to `false`.

* Replace the FPGA-independent `imem` implementation with the file provided in this folder, as described in the [README](../README.md) in the parent folder.

* The initialisation file name can be configured using the [`m9k_init_file` constant](neorv32_imem.max10_m9k.vhd#L81) in this VHDL module. By default, it is set to "`imem.mif`" in the Quartus project folder.

The instantiated `altsyncram` block uses 32-bit wide cells, and is *not* byte-adressable. Memory initialisation using **word** adressing via a [MIF file](https://www.intel.com/content/www/us/en/programmable/quartushelp/13.0/mergedProjects/reference/glossary/def_mif.htm) is required, as Intel HEX format addressing is byte-oriented.

* A python script for converting binary images to memory initialisation files is provided in this folder: [`bin2mif.py`](bin2mif.py). Usage example:
`python bin2mif.py main.bin <Quartus project location>/imem.mif`