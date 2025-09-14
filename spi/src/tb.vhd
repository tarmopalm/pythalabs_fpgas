---*****************************************************
--* Tarmo Palm
--* (c) copyright 2016
--*****************************************************

library IEEE;
   use IEEE.STD_LOGIC_1164.ALL;
   use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library OSVVM ;
   use OSVVM.TbUtilPkg.all ;
   use OSVVM.TranscriptPkg.all ;
   use OSVVM.AlertLogPkg.all ;
   use OSVVM.RandomPkg.all ;
   use OSVVM.CoveragePkg.all ;


library spi_top_lib;


library spislave_model_lib;
   use spislave_model_lib.SPIslave_model_TbPkg.all;

entity tb is
   generic (
            g_clk_period      : time := 10.0 ns   -- Clock Period
      );
end tb;

architecture Behavioral of tb is

   --####################################################################################
   --#Constant###########################################################################
   CONSTANT C_SPI_SLAVE       : integer   := 6;

   --####################################################################################
   --Signals#############################################################################

   signal s_clk               : std_logic := '0';
   signal s_rst               : std_logic := '0';

   signal s_start             : std_logic := '0';
   signal s_slave_num         : std_logic_vector(3 downto 0 ):= "0100";
   signal s_busy              : std_logic;
   signal s_data_in           : std_logic_vector ( 31 downto 0 ) := (others => '0');
   signal s_data_out          : std_logic_vector ( 31 downto 0 ) := (others => '0');
   signal s_spi_clkPol        : std_logic;
   signal s_spi_clkPhase      : std_logic;
   signal s_spi_msbFirst      : std_logic;

   signal s_spi_cs            : std_logic_vector(7 downto 0);
   signal s_spi_csSingle      : std_logic;
   signal s_spi_sck           : std_logic;
   signal s_spi_miso          : std_logic;
   signal s_pha               : std_logic := '0';
   signal s_pol               : std_logic := '0';
   signal s_msbFirst          : std_logic := '1';
   signal s_spi_mosi          : std_logic;
   signal s_Data_Valid        : std_logic;
   signal s_regslave          : std_logic_vector(31 downto 0);
   signal s_miso_val          : std_logic_vector(31 downto 0):=X"AFFEDEAD";
   signal SPIslaveRec         : SPIslaveRecType := INIT_SPISLAVE;
   signal DoRead              : std_logic       := '0';
   signal DoWrite             : std_logic       := '0';
   signal TestDone            : integer_barrier := 1 ;


 begin
   process
   begin
      s_clk <= '0';
      wait for g_clk_period / 2;
      s_clk <= '1';
      wait for g_clk_period / 2;
   end process;

   -- Generate RST
   process
   begin
      s_rst <= '1';
      wait for 100 ns;
      wait until rising_edge(s_clk);
      s_rst <= '0';
      wait;
   end process;

   bl_DUT : block
   begin


      inst_SPI_top : entity spi_top_lib.spi_top
         Generic Map (
               g_slave_cnt       => 8,
               g_spi_divisor     => 5,  -- 5 - o_spi_sck is 10 cycles i_clk long.
               g_spi_maxdata_len => 32,
               g_busy_delay      => 1
         )

         Port Map(
            -- General control signals
            i_rst                          => s_rst,
            i_clk                          => s_clk,

            -- Configuration
            i_start                        => s_start,
            i_slave_num                    => s_slave_num,
            o_busy                         => s_busy,
            i_data                         => s_data_in,
            o_data                         => s_data_out,
            i_spi_clkPol                  =>  s_pol,
            i_spi_clkPhase                =>  s_pha,
            i_spi_msbFirst                =>  s_msbFirst,
            i_Data_len                    => "100000",


            -- SPI interface
            o_spi_cs                       =>  s_spi_cs,
            o_spi_sck                      =>  s_spi_sck,
            i_spi_miso                     =>  s_spi_miso,
            o_spi_mosi                     =>  s_spi_mosi,
            o_Data_Valid                   =>  s_Data_Valid
           );

   end block bl_DUT;

   s_spi_csSingle <= s_spi_cs(to_integer(unsigned(s_slave_num)));

   bl_stimuliAndCheck : block
   begin

      inst_SPIslave_model: entity spislave_model_lib.SPIslave_model
      Generic Map (
               g_slave_cnt       => 8
               )
      Port Map (
               SPIslaveRec       => SPIslaveRec,
               i_clk             => s_clk,
               i_rst             => s_rst,

               -- SPI Interface     -- SPI Inte
               i_spi_cs          => s_spi_cs,
               i_spi_sck         => s_spi_sck,
               o_spi_miso        => open,
               i_spi_mosi        => s_spi_mosi
            );

      --Stimuli 10 Random writes on SPI
      process
         variable RV : RandomPType ;
      begin
         wait until falling_edge(s_rst);

         --Generate Random InputData
         for i in 0 to 9 loop

            --s_data_in <= RV.RandSlv(Min => 0 , Max => 2**(s_data_in'length-1)-1, Size => s_data_in'length);
            s_data_in <= RV.RandSlv(Min => 0 , Max => 2** 16 - 1, Size => s_data_in'length);
            s_start <= '1';
            wait until rising_edge(s_clk);
            s_start <= '0';

            Toggle(DoRead);
            WaitForToggle(DoWrite);
         end loop;

         WaitForBarrier(TestDone);
      end process;

      --Check
      process
      begin

         WaitForToggle(DoRead);
         SPIslaveRDcheck(SPIslaveRec, s_Data_In, s_pol, s_pha, s_msbFirst, to_integer(unsigned(s_slave_num)));
         Toggle(DoWrite);

      end process;
   end block bl_stimuliAndCheck;


   ControlProc : process
   begin

      -- Initialization of test
      SetAlertLogName("SPI_WR") ;
      SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
      -- Wait for testbench initialization
      wait for 0 ns ;
      TranscriptOpen("SPI_WR.txt") ;
      SetTranscriptMirror(TRUE) ;
      -- Wait for Design Reset
      wait until s_rst = '0' ;
      ClearAlerts ;
      -- Wait for test to finish
      WaitForBarrier(TestDone, 5 ms) ;
      AlertIf(now >= 5 ms, "Test finished due to timeout") ;
      AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
      print("") ;
      ReportAlerts ;
      print("") ;
      TranscriptClose ;
      std.env.stop ;
      wait ;

   end process ControlProc ;

end Behavioral;
