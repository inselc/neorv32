# rtl/fpga_specific/xilinx_xc7

Alternative internal IMEM and DMEM implementations for use with Xilinx 7-series FPGA, using the *Xilinx Parameterized Macros* (XPM) library for block memory instantiation.

## Usage and configuration

* Replace the part-independent IMEM/DMEM implementation with the module provided here, as described in the [README](../README.md) in the parent folder.

* For IMEM, the memory initialisation file (MEM file) name can be specified using the [`IMEM_INIT_FILE` generic](neorv32_imem.xc7_bram.vhd#L51). Setting the file name to `"none"` will disable initialisation (e.g. for use with the bootloader). **Defaults to `"imem.mem"`**. The MEM file needs to be imported into Vivado as a new design source before implementation.

* If desired, use the included python3 script to convert a **raw** firmware binary (`main.bin`) into the required MEM file format. 

      $> python bin2mem.py -h

## Verification

* Module operation cross-checked with part-independent implementation using a logic analyser IP core

* Hardware testing performed using *read-only*, *writeable*, and *writeable w/ bootloader* configurations on a [Digilent Cmod A7-35T Rev. C](https://reference.digilentinc.com/reference/programmable-logic/cmod-a7/start) (featured part: Artix-7 `XC7A35T`)

* Pending testbench verification and software-based memory access test

## References

* [Xilinx UG953](https://www.xilinx.com/support/documentation-navigation/see-all-versions.html?xlnxproducttypes=Design%20Tools&xlnxdocumentid=UG953): *Vivado Design Suite 7 Series
FPGA and Zynq-7000 SoC Libraries Guide*, p. 156ff (Sections *"XPM_MEMORY_SPRAM"* and *"XPM_MEMORY_SPROM"*)

* [Xilinx UG898](https://www.xilinx.com/support/documentation-navigation/see-all-versions.html?xlnxproducttypes=Design%20Tools&xlnxdocumentid=UG898): *Vivado Design Suite User Guide, Embedded Processor Hardware Design*, p. 164ff (Section *"Memory (MEM) Files"*)