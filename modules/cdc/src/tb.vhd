--*****************************************************
--*
--* tb.vhd
--*
--*
--* Description: Top level module testbench.
--*
--*---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


Library testbench;

library cdc_lib;

library OSVVM ;
   use OSVVM.TbUtilPkg.all ;
   use OSVVM.TranscriptPkg.all ;
   use OSVVM.AlertLogPkg.all ;
   use OSVVM.RandomPkg.all ;
   use OSVVM.CoveragePkg.all ;
   use OSVVM.ResolutionPkg.all ;

entity tb is
   generic (
            g_clk_period      : time := 10.0 ns   -- Clock Period
      );
end tb;

architecture Behavioral of tb is


   signal s_clk_cd1               : std_logic := '0';
   signal s_dat_cd1               : std_logic := '0';
   signal s_clk_cd2               : std_logic := '0';
   signal s_dat_cd2               : std_logic := '0';
   signal s_rst                   : std_logic := '1';


   signal TestDone                : integer_barrier := 1 ;
   signal SendReady               : std_logic       := '0';
   signal AlertLogID              : integer_max     := 0;
begin

   CreateClock(s_clk_cd1, g_clk_period);
   CreateClock(s_clk_cd2, g_clk_period * 1.3);
   CreateReset(s_rst, '1', s_clk_cd1, 100 ns, 1 ns);

   bl_DUT : block


   begin
      inst_DUT : entity cdc_lib.cdc
         GENERIC MAP(
                  g_inp_FF => "yes",         -- Use "yes" or "no" (Is relevant only if Level is in input)
                  g_type   => "Pulse2Pulse"  -- Use "Level2Level", "Level2Pulse", "Pulse2Level" or "Pulse2Pulse"
                  )
         PORT MAP(
                clk_CD1_I => s_clk_cd1, -- First clock domain CLK
                dat_CD1_I => s_dat_cd1, -- First clock domain data
                clk_CD2_I => s_clk_cd2, -- Second clock domain CLK
                dat_CD2_O => s_dat_cd2  -- Second clock domain data
               );

   end block bl_DUT;

   bl_stimuli_and_check : block
      constant C_CDC_PULSE_CNT      : integer := 10;
      signal s_sended_pulse_count   : integer := 0;
   begin
      process
      begin
         wait until falling_edge(s_rst);
         for i in 0 to C_CDC_PULSE_CNT - 1 loop
            s_dat_cd1 <= '0';
            wait for 100 * g_clk_period;
            wait until rising_edge(s_clk_cd1);
            s_dat_cd1 <= '1';
            wait until rising_edge(s_clk_cd1);
            s_sended_pulse_count <= s_sended_pulse_count + 1;
            Toggle(SendReady);
            s_dat_cd1 <= '0';
            wait for 10 * g_clk_period;
         end loop;

         WaitForBarrier(TestDone);
         wait;
      end process;
      process
         variable v_recieved_pulses : integer := 0;
      begin
         WaitForToggle(SendReady);
         wait until rising_edge( s_dat_cd2);
            v_recieved_pulses := v_recieved_pulses + 1;
                  AffirmIf(
                     AlertLogID,
                     v_recieved_pulses = s_sended_pulse_count,
                     "Recieved pulses = "  & to_string(s_sended_pulse_count),
                     " /= Expected: " & to_string(v_recieved_pulses),
                     true
                     );
      end process;
   end block bl_stimuli_and_check;


   ControlProc : process
   begin

      -- Initialization of test
      SetAlertLogName("CDC") ;
      SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
      -- Wait for testbench initialization
      wait for 0 ns ;
      TranscriptOpen("CDC.txt") ;
      SetTranscriptMirror(TRUE) ;
      -- Wait for Design Reset
      wait until s_rst = '0' ;
      ClearAlerts ;
      -- Wait for test to finish
      WaitForBarrier(TestDone, 1 ms) ;
      AlertIf(now >= 1 ms, "Test finished due to timeout") ;
      AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
      print("") ;
      ReportAlerts ;
      print("") ;
      TranscriptClose ;
      std.env.stop ;
      wait ;

   end process ControlProc ;


end Behavioral;


