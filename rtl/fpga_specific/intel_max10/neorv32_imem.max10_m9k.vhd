-- #################################################################################################
-- # << NEORV32 - Processor-internal IMEM for Intel/Altera MAX10, using M9K-Blocks >>              #
-- # ********************************************************************************************* #
-- # This memory includes the in-place executable image of the application. See the                #
-- # processor's documentary to get more information.                                              #
-- # ********************************************************************************************* #
-- # BSD 3-Clause License                                                                          #
-- #                                                                                               #
-- # Copyright (c) 2020, Stephan Nolting.                                                          #
-- # Copyright (c) 2020, islandc_. Adapted "imem", "imem.ice40up" modules to use altsyncram        #
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

library altera_mf;
use altera_mf.altera_mf_components.all;

entity neorv32_imem is
  generic (
    IMEM_BASE      : std_ulogic_vector(31 downto 0) := x"00000000"; -- memory base address
    IMEM_SIZE      : natural := 16*1024; -- processor-internal instruction memory size in bytes
    IMEM_AS_ROM    : boolean := true;    -- implement IMEM as read-only memory?
    BOOTLOADER_USE : boolean := false    -- implement and use bootloader?
  );
  port (
    clk_i  : in  std_ulogic; -- global clock line
    rden_i : in  std_ulogic; -- read enable
    wren_i : in  std_ulogic; -- write enable
    ben_i  : in  std_ulogic_vector(03 downto 0); -- byte write enable (not used)
    upen_i : in  std_ulogic; -- update enable (not used)
    addr_i : in  std_ulogic_vector(31 downto 0); -- address
    data_i : in  std_ulogic_vector(31 downto 0); -- data in (not used)
    data_o : out std_ulogic_vector(31 downto 0); -- data out
    ack_o  : out std_ulogic  -- transfer acknowledge
  );
end neorv32_imem;

architecture neorv32_imem_rtl of neorv32_imem is
  
  -- IO space: module base address --
  constant hi_abb_c : natural := 31; -- high address boundary bit
  constant lo_abb_c : natural := index_size_f(IMEM_SIZE); -- low address boundary bit
  
  -- local signals --
  signal acc_en : std_ulogic; -- address match
  signal acc_rd : std_ulogic; -- read access
  signal acc_wr : std_ulogic; -- write access
  signal rdata  : std_ulogic_vector(31 downto 0);
  signal rden   : std_ulogic; -- buffered read-enable for output gate
  
  -- M9K block configuration constants --
  constant m9k_init_file : string := "imem.mif"; -- ROM initialisation file
  constant m9k_blk_depth : natural := IMEM_SIZE / 4; -- size in number of words
  constant m9k_addr_width : natural := index_size_f(m9k_blk_depth); -- m9k block addr width
  
  -- M9K interface signals --
  signal m9k_addr : std_logic_vector(m9k_addr_width-1 downto 0);
  signal m9k_clk : std_logic;
  signal m9k_rden : std_logic;
  signal m9k_rdata : std_logic_vector(31 downto 0);

begin

  -- Access Control -------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  acc_en <= '1' when (addr_i(hi_abb_c downto lo_abb_c) = IMEM_BASE(hi_abb_c downto lo_abb_c)) else '0';
  acc_rd <= acc_en and rden_i;
  acc_wr <= acc_en and (rden_i or wren_i);
  
  -- Memory Access --------------------------------------------------------------------------
  -- -------------------------------------------------------------------------------------------
  imem_m9k_inst : altsyncram GENERIC MAP (
    address_aclr_a => "NONE",
    clock_enable_input_a => "BYPASS",
    clock_enable_output_a => "BYPASS",
    init_file => m9k_init_file,
    intended_device_family => "MAX 10",
    lpm_hint => "ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=IMEM",
    lpm_type => "altsyncram",
    numwords_a => m9k_blk_depth,
    operation_mode => "ROM",
    outdata_aclr_a => "NONE",
    outdata_reg_a => "UNREGISTERED",
    ram_block_type => "M9K",
    widthad_a => m9k_addr_width,
    width_a => 32
  ) PORT MAP (
    address_a => m9k_addr,
    clock0 => m9k_clk,
    rden_a => m9k_rden,
    q_a => m9k_rdata
  );
  
  -- access logic and signal type conversion --
  m9k_addr <= std_logic_vector(addr_i(m9k_addr_width+1 downto 2));
  m9k_clk <= std_logic(clk_i);
  m9k_rden <= '1' when (acc_rd = '1') else '0';
  rdata <= std_ulogic_vector(m9k_rdata);
  
  buffer_ff: process (clk_i)
  begin
    -- configuration check --
    if (IMEM_AS_ROM = false) or (BOOTLOADER_USE = true) then
      assert false report "RAM-style M9K variant of IMEM not yet implemented" severity error;
    end if;
    -- buffer --
    if rising_edge(clk_i) then
      rden  <= acc_rd;
      ack_o <= acc_rd or acc_wr;
    end if;
  end process buffer_ff;
  
  -- output gate --
  data_o <= rdata when (rden = '1') else (others => '0');

end neorv32_imem_rtl;
