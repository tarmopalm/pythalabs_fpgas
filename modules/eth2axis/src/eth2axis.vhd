library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

library UNISIM;
use UNISIM.VComponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity eth2axis is
   Generic (
      -- Configuration
      g_src_mac      : std_logic_vector(47 downto 0);
      g_des_mac      : std_logic_vector(47 downto 0)
            );
   Port (
      -- General control signals
      i_rst          : in  std_logic;
      i_clk          : in  std_logic;


      -- AXIS Slave
      s_axis_tvalid  : in std_logic;
      s_axis_tdata   : in std_logic_vector(31 downto 0);
      s_axis_tstrb   : in std_logic_vector( 3 downto 0);
      s_axis_tlast   : in std_logic;
      s_axis_tready  : out std_logic;

      -- AXIS_Master
      m_axis_tvalid  : out std_logic;
      m_axis_tdata   : out std_logic_vector(31 downto 0);
      m_axis_tstrb   : out std_logic_vector( 3 downto 0);
      m_axis_tlast   : out std_logic;
      m_axis_tready  : in  std_logic;


      i_eth_rx_clk   : in  std_logic;
      i_eth_rx_vld   : in  std_logic;
      i_eth_rx_dat   : in  std_logic_vector(7 downto 0);

      i_eth_tx_clk   : in  std_logic;
      o_eth_tx_vld   : out std_logic;
      o_eth_tx_dat   : out std_logic_vector(7 downto 0);

      o_crc_err_cnt  : out std_logic_vector(7 downto 0);
      o_mac_err_cnt  : out std_logic_vector(7 downto 0);
      o_packet_cnt   : out std_logic_vector(7 downto 0)



      );
end eth2axis;

architecture Behavioral of eth2axis is

   component packetRAM
      -- NB! Memory Size is 36Kbits
      generic (
         g_port1_dat_width : natural := 32;
         g_port1_adr_width : natural := 9;
         g_port2_dat_width : natural := 32;
         g_port2_adr_width : natural := 9

         );
      port (
         i_clk1 : in  std_logic;
         i_rst1 : in  std_logic;
         i_wre1 : in  std_logic;
         i_dat1 : in  std_logic_vector(g_port1_dat_width - 1 downto 0);
         i_adr1 : in  std_logic_vector(g_port1_adr_width - 1 downto 0);

         i_clk2 : in  std_logic;
         i_rst2 : in  std_logic;
         i_rde2 : in  std_logic;
         o_dat2 : out std_logic_vector(g_port2_dat_width - 1 downto 0);
         i_adr2 : in  std_logic_vector(g_port2_adr_width - 1 downto 0)
      );
   end component;

      -- polynomial: (0 1 2 4 5 7 8 10 11 12 16 22 23 26 32)
      -- data width: 8
      -- convention: the first serial data bit is D(7)
      function nextCRC32_D8 ( Data:  std_logic_vector(7 downto 0);
                              CRC:   std_logic_vector(31 downto 0)
                              )
                              return std_logic_vector is

         variable D: std_logic_vector(7 downto 0);
         variable C: std_logic_vector(31 downto 0);
         variable NewCRC: std_logic_vector(31 downto 0);
      begin

         D := Data;
         C := CRC;

         NewCRC(0) := D(6) xor D(0) xor C(24) xor C(30);
         NewCRC(1) := D(7) xor D(6) xor D(1) xor D(0) xor C(24) xor C(25) xor
                 C(30) xor C(31);
         NewCRC(2) := D(7) xor D(6) xor D(2) xor D(1) xor D(0) xor C(24) xor
                 C(25) xor C(26) xor C(30) xor C(31);
         NewCRC(3) := D(7) xor D(3) xor D(2) xor D(1) xor C(25) xor C(26) xor
                 C(27) xor C(31);
         NewCRC(4) := D(6) xor D(4) xor D(3) xor D(2) xor D(0) xor C(24) xor
                 C(26) xor C(27) xor C(28) xor C(30);
         NewCRC(5) := D(7) xor D(6) xor D(5) xor D(4) xor D(3) xor D(1) xor
                 D(0) xor C(24) xor C(25) xor C(27) xor C(28) xor C(29) xor
                 C(30) xor C(31);
         NewCRC(6) := D(7) xor D(6) xor D(5) xor D(4) xor D(2) xor D(1) xor
                 C(25) xor C(26) xor C(28) xor C(29) xor C(30) xor C(31);
         NewCRC(7) := D(7) xor D(5) xor D(3) xor D(2) xor D(0) xor C(24) xor
                 C(26) xor C(27) xor C(29) xor C(31);
         NewCRC(8) := D(4) xor D(3) xor D(1) xor D(0) xor C(0) xor C(24) xor
                 C(25) xor C(27) xor C(28);
         NewCRC(9) := D(5) xor D(4) xor D(2) xor D(1) xor C(1) xor C(25) xor
                 C(26) xor C(28) xor C(29);
         NewCRC(10) := D(5) xor D(3) xor D(2) xor D(0) xor C(2) xor C(24) xor
                  C(26) xor C(27) xor C(29);
         NewCRC(11) := D(4) xor D(3) xor D(1) xor D(0) xor C(3) xor C(24) xor
                  C(25) xor C(27) xor C(28);
         NewCRC(12) := D(6) xor D(5) xor D(4) xor D(2) xor D(1) xor D(0) xor
                  C(4) xor C(24) xor C(25) xor C(26) xor C(28) xor C(29) xor
                  C(30);
         NewCRC(13) := D(7) xor D(6) xor D(5) xor D(3) xor D(2) xor D(1) xor
                  C(5) xor C(25) xor C(26) xor C(27) xor C(29) xor C(30) xor
                  C(31);
         NewCRC(14) := D(7) xor D(6) xor D(4) xor D(3) xor D(2) xor C(6) xor
                  C(26) xor C(27) xor C(28) xor C(30) xor C(31);
         NewCRC(15) := D(7) xor D(5) xor D(4) xor D(3) xor C(7) xor C(27) xor
                  C(28) xor C(29) xor C(31);
         NewCRC(16) := D(5) xor D(4) xor D(0) xor C(8) xor C(24) xor C(28) xor
                  C(29);
         NewCRC(17) := D(6) xor D(5) xor D(1) xor C(9) xor C(25) xor C(29) xor
                  C(30);
         NewCRC(18) := D(7) xor D(6) xor D(2) xor C(10) xor C(26) xor C(30) xor
                  C(31);
         NewCRC(19) := D(7) xor D(3) xor C(11) xor C(27) xor C(31);
         NewCRC(20) := D(4) xor C(12) xor C(28);
         NewCRC(21) := D(5) xor C(13) xor C(29);
         NewCRC(22) := D(0) xor C(14) xor C(24);
         NewCRC(23) := D(6) xor D(1) xor D(0) xor C(15) xor C(24) xor C(25) xor
                  C(30);
         NewCRC(24) := D(7) xor D(2) xor D(1) xor C(16) xor C(25) xor C(26) xor
                  C(31);
         NewCRC(25) := D(3) xor D(2) xor C(17) xor C(26) xor C(27);
         NewCRC(26) := D(6) xor D(4) xor D(3) xor D(0) xor C(18) xor C(24) xor
                  C(27) xor C(28) xor C(30);
         NewCRC(27) := D(7) xor D(5) xor D(4) xor D(1) xor C(19) xor C(25) xor
                  C(28) xor C(29) xor C(31);
         NewCRC(28) := D(6) xor D(5) xor D(2) xor C(20) xor C(26) xor C(29) xor
                  C(30);
         NewCRC(29) := D(7) xor D(6) xor D(3) xor C(21) xor C(27) xor C(30) xor
                  C(31);
         NewCRC(30) := D(7) xor D(4) xor C(22) xor C(28) xor C(31);
         NewCRC(31) := D(5) xor C(23) xor C(29);

         return NewCRC;

      end nextCRC32_D8;

      procedure ETH_CRC32    ( constant DataByte         : in     std_logic_vector( 7 downto 0);
                               variable CRC32            : inout  std_logic_vector(31 downto 0);
                               variable CRC32invSwapped  : out    std_logic_vector(31 downto 0)
                              ) is
         variable v_data            : std_logic_vector( 7 downto 0);
         variable v_dataSwapped     : std_logic_vector( 7 downto 0);
         variable v_nextCRC32_D8    : std_logic_vector(31 downto 0);
         variable v_nextCRC32       : std_logic_vector(31 downto 0);
      begin
                        --## Start
                        v_data   := DataByte;
                        for i in 0 to DataByte'left loop
                           v_dataSwapped(i) := v_data(v_data'left - i);
                        end loop;
                        v_nextCRC32_D8 := CRC32;
                        v_nextCRC32_D8 := nextCRC32_D8(v_dataSwapped, v_nextCRC32_D8);
                        CRC32 := v_nextCRC32_D8;
                        for i in 0 to v_nextCRC32_D8'left loop
                           v_nextCRC32(i) := not v_nextCRC32_D8(v_nextCRC32_D8'left - i);
                        end loop;
                        CRC32invSwapped := v_nextCRC32;
                        --## End
      end ETH_CRC32;
         -- ##################################################################################################
         -- ##################################################################################################
         -- ##################################################################################################
   -- Ethernet Frame
   --    Layer 1 |         | preamble                - 7 octets
   --    Layer 1 |         | sfd                     - 1 octet
   --    Layer 1 | layer 2 | MAC dest                - 6 octets
   --    Layer 1 | layer 2 | MAC src                 - 6 octets
   --    Layer 1 | layer 2 | 802.1Q Tag              - 4 octets (optional)
   --    Layer 1 | layer 2 | Ethernat Type or Length - 2 octets
   --    Layer 1 | layer 2 | Payload                 - 46 octets if 802.1Q Tag is missing otherwise 42 octets
   --    Layer 1 | layer 2 | FCS                     - 4 octets
   --                        Inter Packet cap        - 12 octets
   type t_quadGray is array(0 to 3) of std_logic_vector(1 downto 0);
   constant C_quadGray : t_quadGray := ("00", "01", "11", "10");


begin

   bl_tx : block
         signal s_eth_tx_rst  : std_logic_vector(2 downto 0);
         signal s_axis_wrEn         : std_logic := '0';
         signal s_axis_wrdata       : std_logic_vector(31 downto 0);
         signal s_axis_wrAddr       : std_logic_vector(9 downto 0);
         signal s_axis_wrQuadValue  : std_logic_vector(1 downto 0) := "00"; -- 00->01->11->10->Roudup
         signal s_axis_wrQuadAddr   : std_logic_vector(7 downto 0) := (others => '0');

         type t_axis_QuadAddrCDC is array (2 downto 0) of std_logic_vector(1 downto 0);
         signal s_axis_wrQuadAddrCDC : t_axis_QuadAddrCDC := (others => (others => '0'));
         signal s_axis_rdQuadAddrCDC : t_axis_QuadAddrCDC := (others => (others => '0'));

         signal s_eth_tx_rde        : std_logic := '0';
         signal s_eth_tx_rdData     : std_logic_vector(31 downto 0);
         signal s_eth_tx_rdAddr     : std_logic_vector(9 downto 0);
         signal s_eth_tx_rdQuadValue  : std_logic_vector(1 downto 0) := "00"; -- 00->01->11->10->Roudup
         signal s_eth_tx_QuadAddr   : std_logic_vector(7 downto 0) := (others => '0');
         signal s_eth_tx_QuadAddrCDC_current : std_logic_vector(1 downto 0) := (others => '0');
         signal s_eth_tx_sendEnable          : std_logic := '0';

         type t_tx_header_ROM is array(0 to 21) of std_logic_vector(7 downto 0);
         signal s_eth_tx_header_ROM : t_tx_header_ROM := (
                                              0 => X"55",-- Preamble
                                              1 => X"55",-- Preamble
                                              2 => X"55",-- Preamble
                                              3 => X"55",-- Preamble
                                              4 => X"55",-- Preamble
                                              5 => X"55",-- Preamble
                                              6 => X"55",-- Preamble
                                              7 => X"D5",-- sfd
                                              8 => g_des_mac(47 downto 40),-- dest MAC
                                              9 => g_des_mac(39 downto 32),-- dest MAC
                                             10 => g_des_mac(31 downto 24),-- dest MAC
                                             11 => g_des_mac(23 downto 16),-- dest MAC
                                             12 => g_des_mac(15 downto  8),-- dest MAC
                                             13 => g_des_mac( 7 downto  0),-- dest MAC
                                             14 => g_src_mac(47 downto 40),-- src  MAC
                                             15 => g_src_mac(39 downto 32),-- src  MAC
                                             16 => g_src_mac(31 downto 24),-- src  MAC
                                             17 => g_src_mac(23 downto 16),-- src  MAC
                                             18 => g_src_mac(15 downto  8),-- src  MAC
                                             19 => g_src_mac( 7 downto  0),-- src  MAC
                                             --21 => X"00", -- Payload Len byte 1
                                             --22 => X"20", -- Payload Len byte 0


                                             others => X"00"
                                             );

   begin
         process(i_eth_tx_clk)
         begin
            if rising_edge(i_eth_tx_clk) then
               s_eth_tx_rst <= s_eth_tx_rst(s_eth_tx_rst'left - 1 downto 0) & i_rst;
            end if;
         end process;


         -- RAM for packets to send.
         inst_txRAM: packetRAM
            -- NB! Memory Size is 36Kbits
            generic map(
               g_port1_dat_width => 32,
               g_port1_adr_width => 10,
               g_port2_dat_width => 32,
               g_port2_adr_width => 10

               )
            port map(
               i_clk1 => i_clk,
               i_rst1 => i_rst,
               i_wre1 => s_axis_wrEn,
               i_dat1 => s_axis_wrdata,
               i_adr1 => s_axis_wrAddr,

               i_clk2 => i_eth_tx_clk,
               i_rst2 => s_eth_tx_rst(s_eth_tx_rst'left),
               i_rde2 => s_eth_tx_rde,
               o_dat2 => s_eth_tx_rdData,
               i_adr2 => s_eth_tx_rdAddr
            );

         -- bl_s_axis Description:
         --    Packet ram is divided in quadrants.
         --    Quadrant is coded in Gray code.
         --    s_axis_wrQuadAddr - is address in Quadrant
         --    With s_axis_tlast is quadrant swiching triggered.
         --    By Quadrant switching packet length is written in address zero. Packet itself starts with address 1. And ew quadrand address is generated.

         bl_s_axis : block
            signal s_switchQuad     : std_logic;
            signal s_quadPtr        : unsigned(1 downto 0) := "00";
            signal s_payloadLength  : std_logic_vector(7 downto 0);

            signal s_axis_tready_local  : std_logic;
         begin

            s_axis_tready <= s_axis_tready_local;
            s_axis_wrAddr <= s_axis_wrQuadValue & s_axis_wrQuadAddr;

            process(i_clk)
            begin
               if rising_edge(i_clk) then
                  if i_rst = '1' then
                     s_axis_tready_local     <= '0';
                  else
                     s_axis_tready_local     <= '1';

                     s_switchQuad      <= '0';
                     s_axis_wrEn       <= '0';

                     s_axis_wrQuadValue   <= C_quadGray(to_integer(s_quadPtr));

                     if s_axis_tvalid = '1' and  s_axis_tready_local = '1' then
                        s_axis_wrQuadAddr <= std_logic_vector(unsigned(s_axis_wrQuadAddr) + 1);
                        s_axis_wrdata     <= s_axis_tdata;
                        s_axis_wrEn       <= '1';
                        if s_axis_tlast = '1' then
                           s_switchQuad    <= '1';
                           s_payloadLength <= std_logic_vector(unsigned(s_axis_wrQuadAddr) + 1);
                           s_axis_tready_local   <= '0';
                        end if;
                     end if;

                     if s_switchQuad = '1' then
                        s_axis_tready_local   <= '0';
                        s_axis_wrQuadAddr    <= (others => '0');

                        s_axis_wrdata        <= X"0000_00" & s_payloadLength;
                        s_axis_wrEn          <= '1';
                        if s_axis_rdQuadAddrCDC(s_axis_rdQuadAddrCDC'left) = C_quadGray(to_integer(s_quadPtr + 1)) then
                           s_switchQuad    <= '1';
                        else
                           s_quadPtr            <= s_quadPtr + 1;
                        end if;
                     end if;
                  end if;
               end if;
            end process;
         end block bl_s_axis;

         bl_cdc : block
         begin

            process(i_eth_tx_clk)
            begin
               if rising_edge(i_eth_tx_clk) then
                  s_axis_wrQuadAddrCDC <= s_axis_wrQuadAddrCDC(s_axis_wrQuadAddrCDC'left - 1 downto 0) & s_axis_wrQuadValue;
               end if;
            end process;
            process(i_clk)
            begin
               if rising_edge(i_clk) then
                  s_axis_rdQuadAddrCDC <= s_axis_rdQuadAddrCDC(s_axis_rdQuadAddrCDC'left - 1 downto 0) & s_eth_tx_rdQuadValue;
               end if;
            end process;


         end block bl_cdc;


         -- bl_eth_tx Descripotion
         --    Starts working if current quadrant pointer differs with pointer generated from bl_s_axis.
         bl_eth_tx : block
            signal s_eth_tx_frameLen_Cnt        : unsigned(10 downto 0);
            signal s_eth_tx_PayloadLen_Cnt      : unsigned(15 downto 0);
            signal s_eth_tx_PayloadLen          : std_logic_vector(15 downto 0);
            signal s_eth_tx_PayloadLenValue     : std_logic_vector(15 downto 0);

            signal s_eth_tx_crc_cnt             : unsigned(2 downto 0) := (others => '0');
            signal s_eth_tx_gab_cnt             : unsigned(7 downto 0) := (others => '1');

            signal s_quadPtr                    : unsigned(1 downto 0) := "00";

         begin

            s_eth_tx_rdAddr <= s_eth_tx_rdQuadValue & s_eth_tx_QuadAddr;

            process(i_eth_tx_clk)
               variable v_nextCRC32_D8          : std_logic_vector(31 downto 0);
               variable v_nextCRC32_invSwapped  : std_logic_vector(31 downto 0);
               variable v_eth_tx_dat            : std_logic_vector( 7 downto 0);
            begin
               if rising_edge(i_eth_tx_clk) then

                  s_eth_tx_rde <= '0';

                  s_eth_tx_QuadAddrCDC_current   <= C_quadGray(to_integer(s_quadPtr));

                  if s_axis_wrQuadAddrCDC(s_axis_wrQuadAddrCDC'left) /= s_eth_tx_QuadAddrCDC_current and s_eth_tx_sendEnable = '0' then
                     s_eth_tx_frameLen_Cnt         <= to_unsigned(0, 11);
                     s_eth_tx_rdQuadValue          <= s_eth_tx_QuadAddrCDC_current;
                     --s_eth_tx_QuadAddrCDC_current  <= s_axis_wrQuadAddrCDC(s_axis_wrQuadAddrCDC'left);
                     s_quadPtr                     <= s_quadPtr + 1;
                     s_eth_tx_QuadAddr             <=  (others => '0');
                     s_eth_tx_rde                  <= '1';
                     s_eth_tx_sendEnable           <= '1';
                  end if;


                  o_eth_tx_vld   <= '0';
                  o_eth_tx_dat   <= X"DD";
                  if s_eth_tx_sendEnable = '1' then

                     s_eth_tx_rde                  <= '1';



                     if s_eth_tx_frameLen_Cnt < 8 then
                        o_eth_tx_vld   <= '1';
                        o_eth_tx_dat   <= s_eth_tx_header_ROM(to_integer(s_eth_tx_frameLen_Cnt));
                        s_eth_tx_PayloadLenValue   <= std_logic_vector(shift_left(unsigned(s_eth_tx_rdData(15 downto 0)), 2));
                        if unsigned(s_eth_tx_rdData(15 downto 0))  > to_unsigned(46 / 4 , 16) then
                           s_eth_tx_PayloadLen <= std_logic_vector(shift_left(unsigned(s_eth_tx_rdData(15 downto 0)), 2) - 0);
                        else
                           s_eth_tx_PayloadLen <= std_logic_vector(to_unsigned(46, 16) - 0);
                        end if;
                        v_nextCRC32_D8 := (others=>'1');
                     elsif s_eth_tx_frameLen_Cnt < 20 then
                        o_eth_tx_vld   <= '1';
                        v_eth_tx_dat   := s_eth_tx_header_ROM(to_integer(s_eth_tx_frameLen_Cnt));
                        o_eth_tx_dat   <= v_eth_tx_dat;
                        s_eth_tx_PayloadLenValue   <= std_logic_vector(shift_left(unsigned(s_eth_tx_rdData(15 downto 0)), 2));
                        ETH_CRC32(v_eth_tx_dat, v_nextCRC32_D8, v_nextCRC32_invSwapped);

                     elsif s_eth_tx_frameLen_Cnt < 21 then

                        o_eth_tx_vld   <= '1';
                        v_eth_tx_dat   := s_eth_tx_PayloadLenValue(15 downto 8);
                        o_eth_tx_dat   <= v_eth_tx_dat;
                        s_eth_tx_QuadAddr <= std_logic_vector(unsigned(s_eth_tx_QuadAddr) + 1);
                        ETH_CRC32(v_eth_tx_dat, v_nextCRC32_D8, v_nextCRC32_invSwapped);

                     elsif s_eth_tx_frameLen_Cnt < 22 then
                        o_eth_tx_vld   <= '1';
                        v_eth_tx_dat   := s_eth_tx_PayloadLenValue( 7 downto 0);
                        o_eth_tx_dat   <= v_eth_tx_dat;
                        s_eth_tx_PayloadLen_Cnt <= to_unsigned(0, 16);
                        ETH_CRC32(v_eth_tx_dat, v_nextCRC32_D8, v_nextCRC32_invSwapped);

                     elsif s_eth_tx_frameLen_Cnt >= 22 and s_eth_tx_PayloadLen_Cnt < unsigned(s_eth_tx_PayloadLen) then
                        o_eth_tx_vld   <= '1';
                        s_eth_tx_PayloadLen_Cnt <= s_eth_tx_PayloadLen_Cnt + 1;
                        if s_eth_tx_PayloadLen_Cnt < unsigned(s_eth_tx_PayloadLenValue) then
                           case s_eth_tx_PayloadLen_Cnt(1 downto 0) is
                              when "00" => v_eth_tx_dat := s_eth_tx_rdData(31 downto 24);
                              when "01" => v_eth_tx_dat := s_eth_tx_rdData(23 downto 16);
                              when "10" => v_eth_tx_dat := s_eth_tx_rdData(15 downto  8);
                                               s_eth_tx_QuadAddr <= std_logic_vector(unsigned(s_eth_tx_QuadAddr) + 1);
                              when "11" => v_eth_tx_dat := s_eth_tx_rdData( 7 downto  0);

                              when others => null;
                           end case;
                        else
                           v_eth_tx_dat := (others => '0'); -- Padding Zeros
                        end if;
                        ETH_CRC32(v_eth_tx_dat, v_nextCRC32_D8, v_nextCRC32_invSwapped);


                        o_eth_tx_dat   <= v_eth_tx_dat;
                        s_eth_tx_crc_cnt <= "100";
                     else
                        o_eth_tx_vld   <= '1';


                        case s_eth_tx_crc_cnt(2 downto 0) is
                           when "000" => v_eth_tx_dat := (others => '0');
                           when "001" => v_eth_tx_dat := v_nextCRC32_invSwapped(31 downto 24);
                           when "010" => v_eth_tx_dat := v_nextCRC32_invSwapped(23 downto 16);
                           when "011" => v_eth_tx_dat := v_nextCRC32_invSwapped(15 downto  8);
                           when "100" => v_eth_tx_dat := v_nextCRC32_invSwapped( 7 downto  0);

                           when others => null;
                        end case;
                        o_eth_tx_dat   <= v_eth_tx_dat;

                        if s_eth_tx_crc_cnt = 0 then
                           o_eth_tx_vld   <= '0';
                           s_eth_tx_gab_cnt <= s_eth_tx_gab_cnt - 1;
                           o_eth_tx_dat   <= X"DD";
                        else
                           s_eth_tx_gab_cnt <= X"0F";--(others => '1');
                           s_eth_tx_crc_cnt <= s_eth_tx_crc_cnt - 1;
                        end if;
                        if s_eth_tx_gab_cnt = 0 then
                           s_eth_tx_sendEnable <= '0';
                           o_eth_tx_dat   <= X"DD";
                        end if;

                     end if;

                     s_eth_tx_frameLen_Cnt <= s_eth_tx_frameLen_Cnt + 1;
                  end if;
               end if;
            end process;

         end block bl_eth_tx;

   end block bl_tx;


   bl_rx : block

      signal s_eth_rx_rst           : std_logic_vector(2 downto 0);

      signal s_eth_rx_wrEn          : std_logic := '0';
      signal s_eth_rx_wrdata        : std_logic_vector(15 downto 0);
      signal s_eth_rx_wrAddr        : std_logic_vector(10 downto 0);

      signal s_eth_rx_wrQuadValue   : std_logic_vector(1 downto 0) := "00"; -- 00->01->11->10->Roudup
      signal s_eth_rx_wrQuadAddr    : std_logic_vector(8 downto 0) := (others => '0');

      type t_eth_rx_wrQuadAddrCDC is array (2 downto 0) of std_logic_vector(1 downto 0);
      signal s_eth_rx_wrQuadAddrCDC    : t_eth_rx_wrQuadAddrCDC := (others => (others => '0'));

      signal s_m_axis_rde           : std_logic := '0';
      signal s_m_axis_dat           : std_logic_vector(31 downto 0);
      signal s_m_axis_adr           : std_logic_vector(9 downto 0);
      signal s_m_axis_rdQuadValue   : std_logic_vector(1 downto 0) := "00"; -- 00->01->11->10->Roudup
      signal s_m_axis_QuadAddr      : std_logic_vector(7 downto 0) := (others => '0');
      signal s_m_axis_QuadAddrCDC_current : std_logic_vector(1 downto 0) := (others => '0');



      signal s_crc_err_cnt          : unsigned(7 downto 0) := (others => '0');
      signal s_mac_err_cnt          : unsigned(7 downto 0) := (others => '0');
      signal s_packet_cnt          : unsigned(7 downto 0) := (others => '0');
   begin

         process(i_eth_rx_clk)
         begin
            if rising_edge(i_eth_rx_clk) then
               s_eth_rx_rst <= s_eth_rx_rst(s_eth_rx_rst'left - 1 downto 0) & i_rst;
            end if;
         end process;



         -- RAM for packets to recieve.
         inst_rxRAM: packetRAM
            -- NB! Memory Size is 36Kbits
            generic map(
               g_port1_dat_width => 16,
               g_port1_adr_width => 11,
               g_port2_dat_width => 32,
               g_port2_adr_width => 10

               )
            port map(
               i_clk1 => i_eth_rx_clk,
               i_rst1 => s_eth_rx_rst(s_eth_rx_rst'left),
               i_wre1 => s_eth_rx_wrEn,
               i_dat1 => s_eth_rx_wrdata,
               i_adr1 => s_eth_rx_wrAddr,

               i_clk2 => i_clk,
               i_rst2 => i_rst,
               i_rde2 => s_m_axis_rde,
               o_dat2 => s_m_axis_dat,
               i_adr2 => s_m_axis_adr
            );

         -- bl_eth_rx description
         --    In idle state this process searches OxD5 by i_eth_rx_valid.
         --    After founding it packet is written in packetRAM with MACs and CRC.
         bl_eth_rx : block
            signal s_captureMACptr     : unsigned(3 downto 0) := (others => '0');
            signal s_MACmissmatch      : std_logic := '0';
            signal s_eth_rx_octet      : std_logic_vector(7 downto 0) := (others => '0');
            signal s_eth_layer2_en     : std_logic := '0';

            signal s_eth_rx_octet_cnt  : unsigned(9 downto 0);

            signal s_switchQuad     : std_logic;
            signal s_quadPtr        : unsigned(1 downto 0) := "00";


         begin

            s_eth_rx_wrAddr <= s_eth_rx_wrQuadValue & s_eth_rx_wrQuadAddr;

            process(i_eth_rx_clk)
               variable v_nextCRC32_invSwapped  : std_logic_vector(31 downto 0);
               variable v_nextCRC32_D8          : std_logic_vector(31 downto 0);
               variable v_D8                    : std_logic_vector( 7 downto 0);
            begin
               if rising_edge(i_eth_rx_clk) then

                  s_eth_rx_wrEn <= '0';
                  s_switchQuad  <= '0';
                  s_eth_layer2_en <= '0';

                  s_eth_rx_wrQuadValue   <= C_quadGray(to_integer(s_quadPtr));

                  if i_eth_rx_vld = '1' then
                     -- Search SFD
                     if s_eth_layer2_en = '0' and i_eth_rx_dat = X"D5" then
                        s_MACmissmatch       <= '0';
                        s_eth_layer2_en      <= '1';
                        s_eth_rx_octet_cnt   <= (others => '0');
                        s_eth_rx_wrQuadAddr  <= std_logic_vector(to_unsigned( 1, s_eth_rx_wrQuadAddr'length));
                        s_captureMACptr      <= (others => '0');
                        v_nextCRC32_D8                := (others => '1');
                        s_packet_cnt <= s_packet_cnt + 1;
                     end if;
                     if s_eth_layer2_en = '1' then
                        if s_captureMACptr < 6 then
                           s_captureMACptr <= s_captureMACptr + 1;
                           if g_src_mac((6 - to_integer(s_captureMACptr)) * 8 - 1 downto (6 - to_integer(s_captureMACptr)) * 8  - 8) /= i_eth_rx_dat then
                              s_MACmissmatch <= '1';
                              s_mac_err_cnt <= s_mac_err_cnt + 1;
                           end if;
                        end if;
                        s_eth_rx_wrEn        <= '1';
                        s_switchQuad         <= '1';
                        s_eth_layer2_en      <= '1';
                        s_eth_rx_wrdata      <= s_eth_rx_wrdata(s_eth_rx_wrdata'left - 8 downto 0) & i_eth_rx_dat;
                        s_eth_rx_octet_cnt   <= s_eth_rx_octet_cnt + 1;
                        if s_eth_rx_octet_cnt(0 downto 0) = "0" then
                           s_eth_rx_wrQuadAddr  <= std_logic_vector(unsigned(s_eth_rx_wrQuadAddr) + 1);
                        end if;
                        v_D8 := i_eth_rx_dat;
                        ETH_CRC32(v_D8, v_nextCRC32_D8, v_nextCRC32_invSwapped);
                     end if;
                  else
                     if s_switchQuad = '1' and s_MACmissmatch = '0' then
                        s_MACmissmatch       <= '0';
                        s_eth_rx_wrQuadAddr  <= (others => '0');
                        s_eth_rx_wrdata      <= std_logic_vector(resize(unsigned(s_eth_rx_wrQuadAddr), s_eth_rx_wrdata'length));
                        s_eth_rx_wrEn        <= '1';
                        if v_nextCRC32_D8 = X"C704DD7B" then
                           s_quadPtr            <= s_quadPtr + 1;
                        else
                           s_crc_err_cnt <= s_crc_err_cnt + 1;
                        end if;
                     end if;
                  end if;



               end if;
            end process;

         end block bl_eth_rx;

         bl_cdc_rx : block
         begin

            process(i_clk)
            begin
               if rising_edge(i_clk) then
                  s_eth_rx_wrQuadAddrCDC <= s_eth_rx_wrQuadAddrCDC(s_eth_rx_wrQuadAddrCDC'left - 1 downto 0) & s_eth_rx_wrQuadValue;
               end if;
            end process;

         end block bl_cdc_rx;

         bl_axis_rx : block
            signal s_m_axis_PayloadLen       : std_logic_vector(15 downto 0);
            signal s_m_axis_PayloadPart      : std_logic_vector(15 downto 0);
            signal s_m_axis_sendEnable       : std_logic := '0';

            signal s_quadPtr                 : unsigned(1 downto 0) := "00";

            signal s_master_axis_tvalid      : std_logic := '0';
            signal s_master_axis_tlast       : std_logic := '0';
         begin

            s_m_axis_adr <= s_m_axis_rdQuadValue & s_m_axis_QuadAddr;
            process(i_clk)
            begin
               if rising_edge(i_clk) then

                  s_m_axis_rde <= '0';

                  s_m_axis_QuadAddrCDC_current   <= C_quadGray(to_integer(s_quadPtr));

                  if s_eth_rx_wrQuadAddrCDC(s_eth_rx_wrQuadAddrCDC'left) /= s_m_axis_QuadAddrCDC_current and s_m_axis_sendEnable = '0'  then
                     s_m_axis_rdQuadValue          <= s_m_axis_QuadAddrCDC_current;
                     s_quadPtr                     <= s_quadPtr + 1;
                     s_m_axis_QuadAddrCDC_current  <= s_eth_rx_wrQuadAddrCDC(s_eth_rx_wrQuadAddrCDC'left);
                     s_m_axis_QuadAddr             <= std_logic_vector(to_unsigned(0,s_m_axis_QuadAddr'length));
                     s_m_axis_rde                  <= '1';
                     s_m_axis_sendEnable           <= '1';
                     s_master_axis_tvalid          <= '0';
                     s_master_axis_tlast           <= '0';
                  end if;

                  if s_m_axis_sendEnable = '1' then

                     s_m_axis_rde            <= '1';

                     if s_m_axis_QuadAddr < std_logic_vector(to_unsigned(6,s_m_axis_QuadAddr'length)) then
                        s_m_axis_QuadAddr       <= std_logic_vector(unsigned(s_m_axis_QuadAddr) + 1);
                     end if;

                     if s_m_axis_QuadAddr < std_logic_vector(to_unsigned(6,s_m_axis_QuadAddr'length)) then
                        --s_m_axis_PayloadLen     <= std_logic_vector(shift_right(unsigned(s_m_axis_dat(31 downto 16)), 2) - 1);
                        s_m_axis_PayloadLen     <= std_logic_vector(shift_right(unsigned(s_m_axis_dat(15 downto 0)), 2) - 1);
                        s_m_axis_PayloadPart    <= s_m_axis_dat(31 downto 16);
                     end if;
                     if s_m_axis_QuadAddr = std_logic_vector(to_unsigned(6,s_m_axis_QuadAddr'length)) and s_master_axis_tvalid = '0' then
                        --m_axis_tdata            <= s_m_axis_dat(15 downto 0) & s_m_axis_dat(31 downto 16);
                        m_axis_tdata            <= s_m_axis_PayloadPart & s_m_axis_dat(15 downto 0);
                        s_m_axis_PayloadPart    <= s_m_axis_dat(31 downto 16);
                        s_master_axis_tvalid    <= '1';
                        if unsigned(s_m_axis_PayloadLen) = 0 then
                           s_master_axis_tlast     <= '1';
                        else
                           s_m_axis_PayloadLen     <= std_logic_vector(unsigned(s_m_axis_PayloadLen) - 1);
                        end if;
                     end if;
                     if s_m_axis_QuadAddr >= std_logic_vector(to_unsigned(6,s_m_axis_QuadAddr'length)) then
                        if s_master_axis_tvalid = '1' then
                           if  m_axis_tready = '1' then
                              s_m_axis_QuadAddr       <= std_logic_vector(unsigned(s_m_axis_QuadAddr) + 1);
                              --m_axis_tdata            <= s_m_axis_dat(15 downto 0) & s_m_axis_dat(31 downto 16);
                              m_axis_tdata            <= s_m_axis_PayloadPart & s_m_axis_dat(15 downto 0);
                              s_m_axis_PayloadPart    <= s_m_axis_dat(31 downto 16);
                              s_master_axis_tvalid    <= '0';
                              if unsigned(s_m_axis_PayloadLen) = 0 then
                                 s_master_axis_tlast     <= '1';
                              else
                                 s_m_axis_PayloadLen     <= std_logic_vector(unsigned(s_m_axis_PayloadLen) - 1);
                              end if;
                              if s_master_axis_tlast = '1' then
                                 s_master_axis_tvalid  <= '0';
                                 s_master_axis_tlast   <= '0';
                                 s_m_axis_sendEnable   <= '0';
                              end if;
                           end if;
                        else
                           s_master_axis_tvalid    <= '1';
                        end if;
                     end if;
                  end if;

               end if;
            end process;

            m_axis_tvalid  <= s_master_axis_tvalid;
            m_axis_tlast   <= s_master_axis_tlast;
            m_axis_tstrb   <= (others => '1');

            o_crc_err_cnt  <= std_logic_vector(s_crc_err_cnt);
            o_mac_err_cnt  <= std_logic_vector(s_mac_err_cnt);
            o_packet_cnt   <= std_logic_vector(s_packet_cnt);

         end block bl_axis_rx;



   end block bl_rx;

end Behavioral;
