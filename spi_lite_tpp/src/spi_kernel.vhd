--******************************************************
-- Tarmo Palm
--* (c) copyright 2016
--******************************************************
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

library spi_top_lib;


entity spi_kernel is
   Generic (
      g_spi_maxData_len    : positive range 8 to 128 := 8;
      g_busy_delay         : positive range 1 to  8 := 1
   );
   Port (
      i_clk                         : in  std_logic;
      i_clk_en                      : in  std_logic;
      i_en_data_in                  : in  std_logic;
      i_en_data_out                 : in  std_logic;
      i_start                       : in  std_logic;

      i_cpol                        : in  std_logic;
      i_cpha                        : in  std_logic;
      i_msb_first                   : in  std_logic;

      i_rst                         : in  std_logic;
      i_Data                        : in  std_logic_vector(g_spi_maxData_len-1 downto 0);
      o_Data                        : out std_logic_vector(g_spi_maxData_len-1 downto 0);
      i_Data_len                    : in  std_logic_vector(spi_top_lib.spi_pkg.log2(g_spi_maxData_len) downto 0);

      o_Data_Valid                  : out std_logic;
      o_busy                        : out std_logic;
      o_cs                          : out std_logic;    --! Spi chip select
      o_sck                         : out std_logic;    --! Spi clock
      i_miso                        : in  std_logic;    --! Spi data
      o_mosi                        : out std_logic     --! Spi data
   );
end spi_kernel;


architecture Behavioral of spi_kernel is

   signal s_TXDataReg            : std_logic_vector(g_spi_maxData_len-1 downto 0);
   signal s_RXDataReg            : std_logic_vector(g_spi_maxData_len-1 downto 0):= (others=>'0');
   signal s_bitCounterOut        : integer range 0 to g_spi_maxData_len;
   signal s_busy_out             : std_logic := '0';
   signal s_cs                   : std_logic := '1';
   signal s_clk_en               : std_logic := '0';
   signal s_sck                  : std_logic;
   signal s_cpha                 : std_logic;
begin


      -- ##################################################################################################
      -- # Transmit
      -- ##################################################################################################
      o_sck <= s_sck;

      process(i_clk)
      begin
         if rising_edge(i_clk)then
            if i_rst = '1' then
               o_Data_Valid <= '0';
               o_busy       <= '0';
               o_cs         <= '0';
               o_mosi       <= '0';
               s_busy_out   <= '0';
               s_sck        <= i_cpol;
            else
               o_Data_Valid <= '0';
               if i_clk_en = '1' then
                  s_cpha       <= '0';
                  if s_busy_out = '1' then
                     if s_cpha = '0' then
                        s_sck    <= not s_sck;
                     end if;
                  else
                     s_sck             <= i_cpol;
                  end if;
                  -- configure SPI and Start SPI cycle
                  if i_start = '1' and  s_busy_out = '0' and i_en_data_out ='1'then
                     s_busy_out        <= '1';
                     o_busy            <= '1';
                     o_cs              <= '0';

                     if i_cpha = '0' then
                        if i_msb_first='1' then
                           o_mosi            <= i_Data(to_integer(unsigned(i_data_len))-1);
                           s_TxDataReg       <= i_Data(i_Data'left -1 downto 0) & '0';
                        else
                           o_mosi            <= i_Data(i_Data'right);
                           s_TxDataReg <= '0' & i_Data(i_Data'left downto 1);
                        end if;

                        s_bitCounterOut      <= to_integer(unsigned(i_data_len))-1;
                     else
                        if i_msb_first='1' then
                           o_mosi            <= i_Data(to_integer(unsigned(i_data_len))-1);
                        else
                           o_mosi            <= i_Data(i_Data'right);
                        end if;
                        s_TxDataReg          <= i_Data;

                        s_bitCounterOut      <= to_integer(unsigned(i_data_len)) ;
                     end if;
                     s_cpha            <= i_cpha;
                     s_sck             <= i_cpol;
                  elsif(s_busy_out = '1') and i_en_data_out ='1'then
                     -- end of spi cycle
                     if(s_bitCounterOut = 0) then
                        s_busy_out        <='0';
                        s_sck             <= i_cpol;
                        o_cs              <='1';
                        o_busy            <='0';
                        o_Data_Valid      <= '1';
                     else
                        s_bitCounterOut <= s_bitCounterOut - 1;
                     end if;

                     --Transmit Bits
                     if i_msb_first='1' then
                         s_TXDataReg <= s_TXDataReg(s_TXDataReg'left -1 downto 0) & '0';
                         o_mosi <= s_TXDataReg(to_integer(unsigned(i_data_len))-1);
                     else
                         s_TXDataReg <= '0' & s_TXDataReg(s_TXDataReg'left downto 1);
                         o_mosi <= s_TXDataReg(s_TXDataReg'right);
                     end if;
                   end if;
                end if;
             end if;
         end if;
      end process;

      -- ##################################################################################################
      -- # Receive
      -- ##################################################################################################
      process(i_clk)
         variable v_RXDataReg :std_logic_vector(g_spi_maxData_len-1 downto 0) := (others=>'0');
      begin
         if rising_edge (i_clk) then
             if i_clk_en = '1' then
               -- (read first bit on start)                                    or (read current bit)
               if (s_busy_out = '1' and i_en_data_in ='1')then
                   if (i_msb_first='1') then
                      v_RXDataReg := v_RXDataReg(v_RXDataReg'left-1 downto 0) & i_miso;
                      o_Data <= v_RXDataReg;
                   else
                      v_RXDataReg := i_miso & v_RXDataReg(v_RXDataReg'left downto 1);
                      o_Data <= v_RXDataReg; -- if recieved bit count is less "g_spi_maxData_len", then received data word stays on the MSB side of "o_Data". It could be changed in future.
                   end if;
                end if;
             end if;
         end if;
      end process;

end Behavioral;
