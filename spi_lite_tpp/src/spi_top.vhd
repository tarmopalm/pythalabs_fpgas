--******************************************************
--* Tarmo Palm
--* (c) copyright 2016
--******************************************************
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

library spi_top_lib;
--use spi_top_lib.spi_pkg."log2";
--use spi_top_lib.spi_pkg.all;



entity spi_top is
      Generic (
            g_slave_cnt          : positive range 1 to 16;
            g_spi_divisor        : positive range 1 to 4096;  -- 5 - o_spi_sck is 10 cycles i_clk long.
            g_spi_maxData_len    : positive range 8 to 128;
            g_busy_delay         : positive range 1 to 8
      );
      Port (
            -- General control signals
            i_rst                         : in  std_logic;
            i_clk                         : in  std_logic;

            -- Configuration
            i_start                       : in  std_logic;
            i_slave_num                   : in  std_logic_vector(3 downto 0);
            o_busy                        : out  std_logic;
            i_data                        : in  std_logic_vector(g_spi_maxData_len -1 downto 0);
            o_data                        : out std_logic_vector(g_spi_maxData_len -1 downto 0);
            i_spi_clkPol                  : in  std_logic;
            i_spi_clkPhase                : in  std_logic;
            i_spi_msbFirst                : in  std_logic;
            i_Data_len                    : in  std_logic_vector(spi_top_lib.spi_pkg.log2(g_spi_maxData_len) downto 0);

	    -- SPI interface
            o_spi_cs                      : out std_logic_vector(g_slave_cnt - 1 downto 0);
            o_spi_sck                     : out std_logic;
            i_spi_miso                    : in  std_logic;
            o_spi_mosi                    : out std_logic;
            o_Data_Valid                  : out std_logic
      );
end spi_top;


architecture Behavioral of spi_top is

   signal s_EnDataIn       : std_logic;
   signal s_EnDataOut      : std_logic;
   signal s_spiEn_cnt      : integer range 0 to g_spi_divisor-1;
   signal s_spiEnInOut_cnt : std_logic := '1';
   signal s_sclk_en        : std_logic;
   signal s_Data_Valid     : std_logic;
   signal s_start          : std_logic := '0';
   signal s_busy           : std_logic := '0';
   signal s_DataIn         : std_logic_vector(g_spi_maxData_len -1 downto 0);
   signal s_DataOut        : std_logic_vector(g_spi_maxData_len -1 downto 0);
   signal s_spi_cs         : std_logic;
   signal s_spi_clkPol     : std_logic;
   signal s_spi_clkPhase   : std_logic;
   signal s_spi_msbFirst   : std_logic;
   signal s_slave_num      : std_logic_vector(3 downto 0);
   signal s_Data_len       : std_logic_vector(spi_top_lib.spi_pkg.log2(g_spi_maxData_len) downto 0);
   signal s_spi_csNum      : std_logic_vector(g_slave_cnt - 1 downto 0);



   begin


      -- ##################################################################################################
      -- # Spi Kernel
      -- ##################################################################################################
      Inst_Spi_Kernel: entity spi_top_lib.spi_kernel
      GENERIC MAP (
         g_spi_maxData_len    => g_spi_maxData_len,
         g_busy_delay         => g_busy_delay
      )
      PORT MAP(
         i_clk                => i_clk,
         i_clk_en             => s_sclk_en,
         i_en_data_in         => s_EnDataIn,
         i_en_data_out        => s_EnDataOut,
         i_start              => s_start,

         i_cpol               => s_spi_clkPol,
         i_cpha               => s_spi_clkPhase,
         i_msb_first          => s_spi_msbFirst,

         i_rst                => i_rst,
         i_Data               => s_DataIn,
         o_Data               => s_DataOut,
         i_Data_len           => s_Data_len,

         o_Data_Valid         => s_Data_Valid,
         o_busy               => s_busy,
         o_cs                 => s_spi_cs,
         o_sck                => o_spi_sck,
         i_miso               => i_spi_miso,
         o_mosi               => o_spi_mosi
      );

      -- ##################################################################################################
      -- # Spi Takterzeugung
      -- ##################################################################################################
      process (i_clk)
      begin

         if rising_edge (i_clk) then
            s_EnDataOut <= '0';
            s_EnDataIn  <= '0';

            if s_spiEn_cnt = 0 then
               s_sclk_en         <= '1';
               s_spiEn_cnt       <= g_spi_divisor-1;
               s_spiEnInOut_cnt  <= not s_spiEnInOut_cnt;

               if(s_spiEnInOut_cnt = '0')then
                  s_EnDataIn        <= '1';
               elsif(s_spiEnInOut_cnt = '1')then
                  s_EnDataOut       <= '1';
               end if;

            else
               s_spiEn_cnt <= s_spiEn_cnt -1;
               s_sclk_en   <= '0';
            end if;

         end if;
      end process;

      -- ##################################################################################################
      -- # Start, Busy, Data-Output
      -- ##################################################################################################
      process (i_clk)
      begin
         if rising_edge(i_clk)then
               -- signals before start, resolves simulation problems
               -- in kernel they aren't synchronized with start anyway
               s_spi_clkPol   <= i_spi_clkPol;
               s_spi_clkPhase <= i_spi_clkPhase;
               s_spi_msbFirst <= i_spi_msbFirst;
            if i_start = '1' then
               s_start        <= '1';
               s_DataIn       <= i_Data;
               s_Data_len     <= i_Data_len;
            end if;

            if s_busy = '1' then
               s_start <= '0';
            end if;

            if s_busy = '1' or s_start ='1' or i_start = '1' then
               o_busy<='1';
            else
               o_busy<='0';
            end if;

            o_Data         <= (others => '0');
            o_Data_Valid   <= '0';

            if s_Data_Valid='1' then
               o_Data         <= s_DataOut;
               o_Data_Valid   <= s_Data_Valid;

            end if;

         end if;
      end process;

      -- ##################################################################################################
      -- # Chip Select Konfiguration
      -- ##################################################################################################
      process(i_clk)
         variable v_slave_num :std_logic_vector(3 downto 0);
      begin
         if rising_edge(i_clk) then
            if(i_start = '1')then
               v_slave_num := i_slave_num;
               s_slave_num <= i_slave_num;
            end if;

            o_spi_cs <= (others => '1');
            if(s_busy = '1')then
               o_spi_cs(to_integer(unsigned(v_slave_num)))<='0';
            end if;

         end if;
      end process;

end Behavioral;
