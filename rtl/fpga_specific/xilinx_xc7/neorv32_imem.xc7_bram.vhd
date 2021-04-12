-- #################################################################################################
-- # << NEORV32 - Processor-Internal IMEM using XPM Block Memory in Xilinx 7-series FPGA >>        #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2021, Stephan Nolting. All rights reserved.                                     #
-- # Copyright (c) 2021, islandc_. Adapted ice40up variant to use XPM block memory                 #
-- #                                                                                               #
-- # Redistribution and use in source and binary forms, with or without modification, are          #
-- # permitted provided that the following conditions are met:                                     #
-- #                                                                                               #
-- # 1. Redistributions of source code must retain the above copyright notice, this list of        #
-- #    conditions and the following disclaimer.                                                   #
-- #                                                                                               #
-- # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
-- #    conditions and the following disclaimer in the documentation and/or other materials        #
-- #    provided with the distribution.                                                            #
-- #                                                                                               #
-- # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
-- #    endorse or promote products derived from this software without specific prior written      #
-- #    permission.                                                                                #
-- #                                                                                               #
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
-- # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
-- # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
-- # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
-- # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
-- # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
-- # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
-- # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
-- # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
-- # ********************************************************************************************* #
-- # The NEORV32 Processor - https://github.com/stnolting/neorv32              (c) Stephan Nolting #
-- #################################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library neorv32;
use neorv32.neorv32_package.all;

library xpm;
use xpm.vcomponents.all;

entity neorv32_imem is
  generic (
    IMEM_BASE      : std_ulogic_vector(31 downto 0) := x"00000000"; -- memory base address
    IMEM_SIZE      : natural := 64*1024; -- processor-internal instruction memory size in bytes
    IMEM_AS_ROM    : boolean := true;    -- implement IMEM as read-only memory?
    IMEM_INIT_FILE : string  := "imem.mem"; -- memory initialisation file name
    BOOTLOADER_EN  : boolean := false    -- implement and use bootloader?
  );
  port (
    clk_i  : in  std_ulogic; -- global clock line
    rden_i : in  std_ulogic; -- read enable
    wren_i : in  std_ulogic; -- write enable
    ben_i  : in  std_ulogic_vector(03 downto 0); -- byte write enable
    addr_i : in  std_ulogic_vector(31 downto 0); -- address
    data_i : in  std_ulogic_vector(31 downto 0); -- data in
    data_o : out std_ulogic_vector(31 downto 0); -- data out
    ack_o  : out std_ulogic  -- transfer acknowledge
  );
end neorv32_imem;

architecture neorv32_imem_rtl of neorv32_imem is

  -- advanced configuration --------------------------------------------------------------------------------
  constant bram_sleep_mode_en_c : boolean := false; -- put IMEM into sleep mode when idle (for low power)
  -- -------------------------------------------------------------------------------------------------------
  
  -- IO space: module base address --
  constant hi_abb_c : natural := 31; -- high address boundary bit
  constant lo_abb_c : natural := index_size_f(IMEM_SIZE); -- low address boundary bit

  -- local signals --
  signal acc_en     : std_ulogic;
  signal mem_cs     : std_ulogic;
  signal rdata      : std_ulogic_vector(31 downto 0);
  signal rden       : std_ulogic;

  -- XPM BRAM signals --
  signal bram_clk   : std_logic;
  signal bram_addr  : std_logic_vector(lo_abb_c-1 downto 0);
  signal bram_di    : std_logic_vector(31 downto 0);
  signal bram_do    : std_logic_vector(31 downto 0);
  signal bram_we    : std_logic_vector(3 downto 0);
  signal bram_pwr_n : std_logic;
  signal bram_en    : std_logic;

begin

  -- Access Control -------------------------------------------------------------------------
  acc_en <= '1' when (addr_i(hi_abb_c downto lo_abb_c) = IMEM_BASE(hi_abb_c downto lo_abb_c)) else '0';
  mem_cs <= acc_en and (rden_i or wren_i);

  -- Block Memory Instantiation -------------------------------------------------------------
  -- Generate single port ROM macro for read-only configuration
  imem_bram_rom_gen : if IMEM_AS_ROM = true generate
    imem_bram_rom_inst : xpm_memory_sprom
    generic map (
      ADDR_WIDTH_A => (lo_abb_c - 2),
      MEMORY_INIT_FILE => IMEM_INIT_FILE,
      MEMORY_PRIMITIVE => "block",
      MEMORY_SIZE => (IMEM_SIZE * 8),
      READ_DATA_WIDTH_A => 32,
      READ_LATENCY_A => 1,
      WAKEUP_TIME => "use_sleep_pin"
    ) port map (
      addra => bram_addr(lo_abb_c-1 downto 2),
      clka => bram_clk,
      dbiterra => open,
      douta => bram_do,
      ena => bram_en,
      injectdbiterra => '0',
      injectsbiterra => '0',
      regcea => '1',
      rsta => '0',
      sbiterra => open,
      sleep => bram_pwr_n
    );
  end generate imem_bram_rom_gen;

  -- Generate single-port RAM for r/w configuration
  imem_bram_ram_gen : if IMEM_AS_ROM = false generate
    imem_bram_ram_inst : xpm_memory_spram
    generic map (
      ADDR_WIDTH_A => (lo_abb_c - 2),
      BYTE_WRITE_WIDTH_A => 8,
      MEMORY_INIT_FILE => IMEM_INIT_FILE,
      MEMORY_PRIMITIVE => "block",
      MEMORY_SIZE => (IMEM_SIZE * 8),
      READ_DATA_WIDTH_A => 32,
      READ_LATENCY_A => 1,
      WAKEUP_TIME => "use_sleep_pin",
      WRITE_DATA_WIDTH_A => 32
    ) port map (
      addra => bram_addr(lo_abb_c-1 downto 2),
      clka => bram_clk,
      dbiterra => open,
      dina => bram_di,
      douta => bram_do,
      ena => bram_en,
      injectdbiterra => '0',
      injectsbiterra => '0',
      regcea => '1',
      rsta => '0',
      sbiterra => open,
      sleep => bram_pwr_n,
      wea => bram_we
    );
  end generate imem_bram_ram_gen;

  -- Interface Logic and Type Conversion ----------------------------------------------------
  bram_clk <= std_logic(clk_i);
  bram_addr <= std_logic_vector(addr_i(lo_abb_c-1 downto 0));
  bram_di <= std_logic_vector(data_i);
  bram_we <= std_logic_vector(ben_i) when ((acc_en and wren_i) = '1') else (others => '0');
  bram_en <= std_logic(mem_cs);
  bram_pwr_n <= '0' when ((bram_sleep_mode_en_c = false) or (mem_cs = '1')) else '1';
  rdata <= std_ulogic_vector(bram_do);

  buffer_ff: process(clk_i)
  begin
    -- buffer --
    if rising_edge(clk_i) then
      ack_o <= mem_cs;
      rden  <= acc_en and rden_i;
    end if;
  end process buffer_ff;

  -- output gate --
  data_o <= rdata when (rden = '1') else (others => '0');

end neorv32_imem_rtl;
