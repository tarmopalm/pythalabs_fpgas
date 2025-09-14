library IEEE;
use IEEE.STD_LOGIC_1164.all;

library std;
   use std.textio.all ;

library OSVVM ;
  use OSVVM.TbUtilPkg.all ;
  use OSVVM.TranscriptPkg.all ;
  use OSVVM.AlertLogPkg.all ;
  use OSVVM.ResolutionPkg.all ;

package SPIslave_model_TbPkg is

   subtype t_errorMode is std_logic_vector(0 downto 0);
   CONSTANT C_ERR_TIMEOUT_INDEX : integer := 0;
   CONSTANT C_ERR_TIMEOUT  : t_errorMode := (C_ERR_TIMEOUT_INDEX => '1');
   CONSTANT C_READ_ACCESS  : std_logic := '1';
   CONSTANT C_WRITE_ACCESS : std_logic := '0';

   type SPIslaveRecType is record
      CmdAck         : std_logic;
      CmdRdy         : std_logic;
      DataValid      : std_logic;
      clkPol         : std_logic;
      clkPha         : std_logic;
      msbFirst       : std_logic;
      DataRD         : std_logic_vector(63 downto 0);
      DataWR         : std_logic_vector(63 downto 0);
      ErrorMode      : t_errorMode;
      Slave          : integer_max;
      Length         : integer_max;
      AccessType     : std_logic;
      AlertLogID     : integer_max;
      WaitForSlave   : boolean_max;
      SlaveTimeOut   : time_max;
      setupTime      : time_max;
      holdTime       : time_max;
   end record SPIslaveRecType;

   constant INIT_SPISLAVE : SPIslaveRecType := (
                                                CmdRdy         => 'Z',
                                                CmdAck         => 'Z',
                                                DataValid      => 'Z',
                                                clkPol         => 'Z',
                                                clkPha         => 'Z',
                                                msbFirst       => 'Z',
                                                DataRD         => (others => 'Z'),
                                                DataWR         => (others => 'Z'),
                                                ErrorMode      => (others => 'Z'),
                                                Slave          =>  0,
                                                Length         =>  0,
                                                AccessType     => 'Z',
                                                AlertLogID     =>  0,
                                                WaitForSlave   => FALSE,
                                                SlaveTimeOut   =>  0 us,
                                                setupTime      =>  0 ns,
                                                holdTime       =>  0 ns
                                                );

    function Match (
      constant  ActualDataSL        : in    std_logic;
      constant  ExpectedDataSL      : in    std_logic;
      constant  ActualDataSLV       : in    std_logic_vector;
      constant  ExpectedDataSLV     : in    std_logic_vector;
      constant  SL                  : in    boolean := TRUE
   ) return boolean;

   function to_string (
      constant  Data    : in    std_logic_vector

   ) return string;

   procedure SPIslaveRD (
      signal   SPIslaveRec       : InOut SPIslaveRecType;
      variable Data              : Out   std_logic_vector;
      constant clkPol            : In    std_logic;
      constant clkPha            : In    std_logic;
      constant msbFirst          : In    std_logic;
      constant Slave             : In    integer_max;
      constant setupTime         : In    time := 0 ns;
      constant holdTime          : In    time := 0 ns;
      constant WaitForSlave      : In    boolean  := FALSE;
      constant ErrorMode         : In    t_errorMode := (others => '0');
      constant SlaveTimeOut      : In    time     := 1 us;
      constant StatusMsgOn       : In    boolean := FALSE
   );

   procedure SPIslaveRDcheck (
      signal   SPIslaveRec       : InOut SPIslaveRecType ;
      signal   DataExpected      : In    std_logic_vector;
      constant clkPol            : In    std_logic;
      constant clkPha            : In    std_logic;
      constant msbFirst          : In    std_logic;
      constant Slave             : In    integer_max;
      constant setupTime         : In    time := 0 ns;
      constant holdTime          : In    time := 0 ns;
      constant StatusMsgOn       : In    boolean := FALSE;
      constant WaitForSlave      : In    boolean := FALSE;
      constant ErrorMode         : In     t_errorMode := (others => '0');
      constant SlaveTimeOut      : In    time    := 1 us
   );

   procedure SPIslaveWR (
      signal   SPIslaveRec       : InOut SPIslaveRecType ;
      constant Data              : In    std_logic_vector;
      constant clkPol            : In    std_logic;
      constant clkPha            : In    std_logic;
      constant msbFirst          : In    std_logic;
      constant Slave             : In    integer_max;
      constant StatusMsgOn       : In    boolean := FALSE
   );
end SPIslave_model_TbPkg ;

package body SPIslave_model_TbPkg is

   function Match (
      constant  ActualDataSL        : in    std_logic;
      constant  ExpectedDataSL      : in    std_logic;
      constant  ActualDataSLV       : in    std_logic_vector;
      constant  ExpectedDataSLV     : in    std_logic_vector;
      constant  SL                  : in    boolean := TRUE
   ) return boolean is
   begin
      if SL = TRUE then
         return ActualDataSL = ExpectedDataSL;
      else
         return ActualDataSLV = ExpectedDataSLV;
      end if;
   end function Match ;

   ----------------------------------------------
   --
   -- to_string(Data, Addr)
   --
   function to_string (
      constant  Data    : in    std_logic_vector

   ) return string is
   begin
      return to_hstring(Data) & ";";
   end function to_string ;

   procedure SPIslaveRD (
      signal   SPIslaveRec       : InOut SPIslaveRecType;
      variable Data              : Out   std_logic_vector;
      constant clkPol            : In    std_logic;
      constant clkPha            : In    std_logic;
      constant msbFirst          : In    std_logic;
      constant Slave             : In    integer_max;
      constant setupTime         : In    time := 0 ns;
      constant holdTime          : In    time := 0 ns;
      constant WaitForSlave      : In    boolean  := FALSE;
      constant ErrorMode         : In    t_errorMode := (others => '0');
      constant SlaveTimeOut      : In    time     := 1 us;
      constant StatusMsgOn       : In    boolean := FALSE
   ) is
   begin
      SPIslaveRec.clkPol         <= clkPol;
      SPIslaveRec.clkPha         <= clkPha;
      SPIslaveRec.msbFirst       <= msbFirst;
      SPIslaveRec.Slave          <= Slave;
      SPIslaveRec.setupTime      <= setupTime;
      SPIslaveRec.holdTime       <= holdTime;
      SPIslaveRec.Length         <= Data'length;
      SPIslaveRec.WaitForSlave   <= WaitForSlave;
      SPIslaveRec.ErrorMode      <= ErrorMode;
      SPIslaveRec.AccessType     <= C_READ_ACCESS;
      SPIslaveRec.SlaveTimeOut   <= SlaveTimeOut;
      RequestTransaction(Rdy => SPIslaveRec.CmdRdy, Ack => SPIslaveRec.CmdAck) ;
      Data                       := SPIslaveRec.DataRD(Data'Range);
      Log(SPIslaveRec.AlertLogID,
         "SPIslaveRead Received: " & to_string(SPIslaveRec.DataRD),
         INFO, Enable => StatusMsgOn
         ) ;
      SPIslaveRec.clkPol         <= 'Z';
      SPIslaveRec.clkPha         <= 'Z';
      SPIslaveRec.msbFirst       <= 'Z';
      SPIslaveRec.Slave          <= 0;
      SPIslaveRec.setupTime      <= 0 ns;
      SPIslaveRec.holdTime       <= 0 ns;
      SPIslaveRec.AccessType     <= 'Z';
   end procedure SPIslaveRD;

   procedure SPIslaveRDcheck (
      signal   SPIslaveRec       : InOut SPIslaveRecType ;
      signal   DataExpected      : In    std_logic_vector;
      constant clkPol            : In    std_logic;
      constant clkPha            : In    std_logic;
      constant msbFirst          : In    std_logic;
      constant Slave             : In    integer_max;
      constant setupTime         : In    time := 0 ns;
      constant holdTime          : In    time := 0 ns;
      constant StatusMsgOn       : In    boolean := FALSE;
      constant WaitForSlave      : In    boolean := FALSE;
      constant ErrorMode         : In     t_errorMode := (others => '0');
      constant SlaveTimeOut      : In    time    := 1 us
   )is
      variable v_dataActual   : std_logic_vector(DataExpected'RANGE);
      variable v_dataExpected : std_logic_vector(DataExpected'RANGE);
   begin
      SPIslaveRec.clkPol         <= clkPol;
      SPIslaveRec.clkPha         <= clkPha;
      SPIslaveRec.msbFirst       <= msbFirst;
      SPIslaveRec.Slave          <= Slave;
      SPIslaveRec.setupTime      <= setupTime;
      SPIslaveRec.holdTime       <= holdTime;
      SPIslaveRec.Length         <= DataExpected'length;
      SPIslaveRec.WaitForSlave   <= WaitForSlave;
      SPIslaveRec.SlaveTimeOut   <= SlaveTimeOut;
      SPIslaveRec.ErrorMode      <= ErrorMode;
      SPIslaveRec.AccessType     <= C_READ_ACCESS;
      RequestTransaction(Rdy => SPIslaveRec.CmdRdy, Ack => SPIslaveRec.CmdAck);
      v_dataActual               := SPIslaveRec.DataRD(v_dataActual'RANGE);
      v_dataExpected             := DataExpected;
      AffirmIf(
               SPIslaveRec.AlertLogID,
               Match('0','0', v_dataActual, v_dataExpected, FALSE),
               "SPIslaveReadCheck Received: " & to_string(v_dataActual),
               " /= Expected: " & to_string(v_dataExpected),
               StatusMsgOn
               );

      SPIslaveRec.clkPol         <= 'Z';
      SPIslaveRec.clkPha         <= 'Z';
      SPIslaveRec.msbFirst       <= 'Z';
      SPIslaveRec.setupTime      <= 0 ns;
      SPIslaveRec.holdTime       <= 0 ns;
      SPIslaveRec.AccessType     <= 'Z';
   end procedure SPIslaveRDcheck;

   procedure SPIslaveWR (
      signal   SPIslaveRec       : InOut  SPIslaveRecType ;
      constant Data              : In     std_logic_vector;
      constant clkPol            : In    std_logic;
      constant clkPha            : In    std_logic;
      constant msbFirst          : In    std_logic;
      constant Slave             : In     integer_max;
      constant StatusMsgOn       : In     boolean := FALSE
   ) is
   begin
      SPIslaveRec.clkPol         <= clkPol;
      SPIslaveRec.clkPha         <= clkPha;
      SPIslaveRec.msbFirst       <= msbFirst;
      SPIslaveRec.Slave          <= Slave;
      SPIslaveRec.Length         <= Data'length;
      SPIslaveRec.DataWR(data'length -1 downto 0)         <= Data;
      SPIslaveRec.AccessType     <= C_WRITE_ACCESS;
      RequestTransaction(Rdy => SPIslaveRec.CmdRdy, Ack => SPIslaveRec.CmdAck) ;

      SPIslaveRec.clkPol         <= 'Z';
      SPIslaveRec.clkPha         <= 'Z';
      SPIslaveRec.msbFirst       <= 'Z';
      SPIslaveRec.Slave          <=  0 ;
      SPIslaveRec.AccessType     <= 'Z';
   end procedure SPIslaveWR;
end SPIslave_model_TbPkg ;


