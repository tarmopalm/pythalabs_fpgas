library IEEE;
   use IEEE.STD_LOGIC_1164.ALL;
   use IEEE.NUMERIC_STD.ALL;
   use ieee.std_logic_textio.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
library OSVVM ;
   use OSVVM.TbUtilPkg.all ;
   use OSVVM.TranscriptPkg.all ;
   use OSVVM.AlertLogPkg.all ;
   use OSVVM.ResolutionPkg.all ;
   context OSVVM.OsvvmContext ;

library SPIslave_model_Lib;
   use SPIslave_model_Lib.SPIslave_model_TbPkg.all;

--library std;
--   use std.textio.all ;

entity SPIslave_model is
   generic (
            g_slave_cnt : natural := 12
            );
   Port (   SPIslaveRec       : InOut  SPIslaveRecType := INIT_SPISLAVE;
            i_clk             : in  STD_LOGIC;
            i_rst             : in  STD_LOGIC;

            -- SPI Interface
            i_spi_cs          : in std_logic_vector(g_slave_cnt - 1 downto 0);
            i_spi_sck         : in std_logic;
            o_spi_miso        : out std_logic;
            i_spi_mosi        : in std_logic
         );
end SPIslave_model;


architecture Behavioral of SPIslave_model is
--###########################################
-- START (ConstDefs)
   constant I_NAME       : string          := PathTail(to_lower(SPIslave_model'PATH_NAME)) ;
   constant SPIslave_ID  : AlertLogIDType  := GetAlertLogID(I_NAME) ;

-- END (ConstDefs)
--###########################################
-- START (TypeDefs
-- END (TypeDefs)
--###########################################
-- START (Global Signal Defs)
   signal s_counter        : unsigned (31 downto 0) := (others=> '0');
   signal s_setupTimeFail  : boolean := FALSE;
   signal s_holdTimeFail   : boolean := FALSE;
   signal s_spi_sck_old    : std_logic := '0';
   signal s_spi_cs_old     : std_logic := '0';
begin

   --s_holdTime  <= ;
   --###############################################################
   --SPIslaveReadFunction
   --###############################################################

   process
       variable v_RXDataReg      : std_logic_vector(SPIslaveRec.DataRD'Range) := (others=>'0');
       variable v_TXDataReg      : std_logic_vector(SPIslaveRec.DataWR'Range) := (others=>'0');
       variable v_dataActualSL   : std_logic;
       variable v_dataExpectedSL : std_logic;
       variable v_dataActualSLV  : std_logic_vector(31 downto 0);
       variable v_dataExpectedSLV: std_logic_vector(31 downto 0);
       constant StatusMsgOn      : boolean := FALSE;

       variable v_startTime      : Time;
       variable v_currentTime    : Time;
       variable v_TimeOut        : boolean := false;
       variable v_setupTime      : time := 0 ns;
       variable v_holdTime       : time := 0 ns;
   begin

      WaitForTransaction(
                        Clk => i_clk,
                        Rdy => SPIslaveRec.CmdRdy,
                        Ack => SPIslaveRec.CmdAck
      );
      if SPIslaveRec.AccessType = C_READ_ACCESS then
         v_startTime := now;
         v_RXDataReg := (others=>'0');
         --Wait for CS or Timeout
         if SPIslaveRec.WaitForSlave = FALSE then
            wait on i_spi_cs;
         else
            loop
               wait on i_spi_cs for SPIslaveRec.SlaveTimeOut;
               v_currentTime := now;
               if i_spi_cs(SPIslaveRec.Slave) = '0' then
                  exit;
               end if;
               if (v_currentTime - v_startTime) >= SPIslaveRec.SlaveTimeOut then
                  v_TimeOut := true;
                  exit;
               end if;
            end loop;
         end if;

         --Check CS
         v_dataActualSL := i_spi_cs(SPIslaveRec.Slave);
         v_dataExpectedSL := '0';

         if (SPIslaveRec.ErrorMode =  C_ERR_TIMEOUT) then
            AffirmIf(
               SPIslaveRec.AlertLogID,
               Match(v_dataActualSL, v_dataExpectedSL, v_dataActualSLV, v_dataExpectedSLV),
               "SPIslaveReadCheck Received: " & to_string(i_spi_cs(SPIslaveRec.Slave)),
               --" /= Expected: " & to_string("0"),
               StatusMsgOn
               );
         end if;

         --Check Timeout
         if i_spi_cs(SPIslaveRec.Slave) = '1' then
            SPIslaveRec.DataRD <= (others => '0');
            if SPIslaveRec.ErrorMode =  C_ERR_TIMEOUT then
               AffirmIf(
                  SPIslaveRec.AlertLogID,
                  v_TimeOut,"SPIslaveReadCheck TimeOut"
                  );
            else
               if v_TimeOut then
                  Log(SPIslaveRec.AlertLogID,"SPIslaveReadCheck TimeOut");
               end if;
            end if;
         else
            loop

               wait on i_spi_sck, i_spi_cs;


               if i_spi_cs(SPIslaveRec.Slave) = '1' then
                  -- Check lenght
                  v_dataActualSLV := std_logic_vector(s_counter);
                  v_dataExpectedSLV := std_logic_vector(to_unsigned(SPIslaveRec.Length, v_dataExpectedSLV'length));

                  AffirmIf(
                     SPIslaveRec.AlertLogID,
                     Match(v_dataActualSL, v_dataExpectedSL, v_dataActualSLV, v_dataExpectedSLV, FALSE),
                     "SPIslaveRead Bit Cnt : " & to_string(v_dataActualSLV),
                     " /= Expected: " & to_string(v_dataExpectedSLV),
                     StatusMsgOn
                     );

                  AffirmIf(
                     SPIslaveRec.AlertLogID,
                     s_setupTimeFail = FALSE,
                     "Setup Time",
                     " /= Expected: " & to_string(SPIslaveRec.setupTime),
                     StatusMsgOn
                     );

                  AffirmIf(
                     SPIslaveRec.AlertLogID,
                     s_holdTimeFail = FALSE,
                     "Hold Time",
                     " /= Expected: " & to_string(SPIslaveRec.holdTime),
                     StatusMsgOn
                     );

                  s_setupTimeFail <= FALSE;
                  s_holdTimeFail <= FALSE;
                  s_counter    <= (others => '0');
                  exit;
               end if;

               --Read SPI Data
               if i_spi_sck = (SPIslaveRec.clkPha xnor SPIslaveRec.clkPol) then
                  v_setupTime := i_spi_mosi'LAST_EVENT;
                  if  SPIslaveRec.msbFirst = '1' then
                     v_RXDataReg := v_RXDataReg(v_RXDataReg'left -1 downto 0) & i_spi_mosi;
                     s_counter   <= s_counter + 1;
                  else
                     v_RXDataReg := i_spi_mosi &  v_RXDataReg(v_RXDataReg'left downto v_RXDataReg'right + 1 ) ;
                     s_counter   <= s_counter + 1;
                  end if;

                  if v_setupTime < SPIslaveRec.setupTime then
                     s_setupTimeFail <= TRUE;
                  end if;

                  --Wait for next edge for hold time
                  wait for SPIslaveRec.holdTime;
                  v_holdTime := i_spi_mosi'LAST_EVENT;
                  if v_holdTime <= SPIslaveRec.holdTime then
                     s_holdTimeFail <= TRUE;
                  end if;

               end if;
            end loop;
         end if;
         SPIslaveRec.DataRD <= v_RXDataReg;

      elsif SPIslaveRec.AccessType = C_WRITE_ACCESS then
         v_TXDataReg := SPIslaveRec.DataWR;

         wait on i_spi_cs;
         if i_spi_cs(SPIslaveRec.Slave) = '0' then

            if SPIslaveRec.clkPha = '0' then
               if SPIslaveRec.msbFirst = '1' then
                  o_spi_miso  <= v_TXDataReg(SPIslaveRec.Length-1);
                  v_TXDataReg := v_TXDataReg(v_TXDataReg'left -1 downto 0) & '0';
               else
                  o_spi_miso  <= v_TXDataReg(v_TXDataReg'right);
                  v_TXDataReg := '0' & v_TXDataReg(v_TXDataReg'left downto 1);
               end if;
            else
               if SPIslaveRec.msbFirst = '1' then
                  o_spi_miso  <= v_TXDataReg(v_TXDataReg'length-1);
               else
                  o_spi_miso  <= v_TXDataReg(v_TXDataReg'right);
               end if;
            end if;
            -- Start of SPI access
            loop
               wait on i_spi_sck, i_spi_cs;

               if i_spi_cs(SPIslaveRec.Slave) = '1' then
                  s_counter   <= (others => '0');
                  exit;
               end if;

               if i_spi_sck = (SPIslaveRec.clkPha xor SPIslaveRec.clkPol) then
                  if SPIslaveRec.msbFirst = '1' then
                     o_spi_miso  <= v_TXDataReg(SPIslaveRec.Length-1);
                     v_TXDataReg := v_TXDataReg(v_TXDataReg'left -1 downto 0) & '0';
                     s_counter   <= s_counter + 1;
                  else
                     o_spi_miso  <= v_TXDataReg(v_TXDataReg'right);
                     v_TXDataReg := '0' & v_TXDataReg(v_TXDataReg'left -1 downto 0) ;
                     s_counter   <= s_counter + 1;
                  end if;
               end if;

            end loop;
         end if;

         v_dataActualSLV := std_logic_vector(s_counter);
         v_dataExpectedSLV := std_logic_vector(to_unsigned(SPIslaveRec.Length, v_dataExpectedSLV'length));

         AffirmIf(
            SPIslaveRec.AlertLogID,
            Match(v_dataActualSL, v_dataExpectedSL, v_dataActualSLV, v_dataExpectedSLV, FALSE),
            "SPIslaveWrite Bit Cnt : " & to_string(v_dataActualSLV),
            " /= Expected: "  & to_string(v_dataExpectedSLV),
            StatusMsgOn
            );
      end if;
   end process;


end Behavioral;

