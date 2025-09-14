LIBRARY ieee;
USE ieee.STD_LOGIC_1164.ALL;
-- synthesis translate_off
library UNISIM;
use UNISIM.VComponents.all;
-- synthesis translate_on
ENTITY cdc IS
   GENERIC (
            g_inp_FF : string := "yes";         -- Use "yes" or "no" (Is relevant only if Level is in input)
            g_type   : string := "Level2Level"  -- Use "Level2Level", "Level2Pulse", "Pulse2Level" or "Pulse2Pulse"
            );
   PORT (
          clk_CD1_I : in  std_logic; -- First clock domain CLK
          dat_CD1_I : in  std_logic; -- First clock domain data
          clk_CD2_I : in  std_logic; -- Second clock domain CLK
          dat_CD2_O : out std_logic  -- Second clock domain data
         );
END cdc;



ARCHITECTURE arch_cdc OF cdc IS
BEGIN
-------------------------------------------------------
-- LEVEL 2 LEVEL
-------------------------------------------------------
--         Optional: g_inp_FF
--                      |
--                    _____       _____       _____
--                   |     |     |     |     |     |
-- dat_CD1_I --------|     |-----|     |-----|     |------ dat_CD1_O
--                   |     |     |     |     |     |
--                   |\    |     |\    |     |\    |
-- clk_CD1_I --------|/____|  /--|/____|  /--|/____|
--                            |           |
-- clk_CD1_O -----------------------------
--
  bl_level2level : if (g_type = "Level2Level") generate
    signal s_dat_tmp_CD1 : std_logic := '0';
    signal s_dat_tmp_CD2 : std_logic_vector(1 downto 0) := (others => '0');

    -- set attribute to tell VIVADO that the following two registers are CDC purpose. Don't Touch and place next to each other
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of s_dat_tmp_CD2 : signal is "true";

  begin
       -- Flip-Flop in input clock domain
       process(clk_CD1_I)
       begin
         if rising_edge(clk_CD1_I) then
           s_dat_tmp_CD1 <= dat_CD1_I;
         end if;
       end process;

       -- Synchronizer Flip-Flops in output clock domain
       process(clk_CD2_I)
       begin
         if rising_edge(clk_CD2_I) then
           if (g_inp_FF = "yes") then
             s_dat_tmp_CD2 <= s_dat_tmp_CD2(s_dat_tmp_CD2'left - 1 downto 0) & s_dat_tmp_CD1;
           elsif (g_inp_FF = "no") then
             s_dat_tmp_CD2 <= s_dat_tmp_CD2(s_dat_tmp_CD2'left - 1 downto 0) & dat_CD1_I;
           end if;
         end if;
       end process;

       dat_CD2_O <= s_dat_tmp_CD2(s_dat_tmp_CD2'left);

  end generate bl_level2level;
-------------------------------------------------------
-- LEVEL 2 PULSE
-------------------------------------------------------
--         Optional: g_inp_FF
--                      |
--                      |                                              ___
--                      |                             /---------------|   |
--                    _____       _____       _____   |    _____      |XOR|-----   dat_CD1_O
--                   |     |     |     |     |     |  |   |     |     |   |
-- dat_CD1_I --------|     |-----|     |-----|     |------|     |-----|___|
--                   |     |     |     |     |     |      |     |
--                   |\    |     |\    |     |\    |      |\    |
-- clk_CD1_I --------|/____|  /--|/____|  /--|/____|      |/____|
--                            |           |
-- clk_CD1_O -----------------------------
--
  bl_level2pulse : if (g_type = "Level2Pulse") generate
    signal s_dat_tmp_CD1 : std_logic := '0';
    signal s_dat_tmp_CD2 : std_logic_vector(2 downto 0) := (others => '0');
    -- set attribute to tell VIVADO that the following two registers are CDC purpose. Don't Touch and place next to each other
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of s_dat_tmp_CD2 : signal is "true";
  begin
       -- Flip-Flop in input clock domain
       process(clk_CD1_I)
       begin
         if rising_edge(clk_CD1_I) then
           s_dat_tmp_CD1 <= dat_CD1_I;
         end if;
       end process;

       -- Synchronizer Flip-Flops in output clock domain
       process(clk_CD2_I)
       begin
         if rising_edge(clk_CD2_I) then
           if (g_inp_FF = "yes") then
             s_dat_tmp_CD2 <= s_dat_tmp_CD2(s_dat_tmp_CD2'left - 1 downto 0) & s_dat_tmp_CD1;
           elsif (g_inp_FF = "no") then
             s_dat_tmp_CD2 <= s_dat_tmp_CD2(s_dat_tmp_CD2'left - 1 downto 0) & dat_CD1_I;
           end if;
         end if;
       end process;

       dat_CD2_O <= s_dat_tmp_CD2(s_dat_tmp_CD2'left) xor s_dat_tmp_CD2(s_dat_tmp_CD2'left - 1);

  end generate bl_level2pulse;
-------------------------------------------------------
-- PULSE 2 LEVEL
-------------------------------------------------------
--
--              /-------------------------------\
--              |          ___          _____   |   _____       _____
--              |----|>0--|1  |        |     |  |  |     |     |     |
-- dat_CD1_I \  |         |MUX|--------|     |-----|     |-----|     |------ dat_CD1_O
--            \ \---------|0__|        |     |     |     |     |     |
--             \-----------/           |\    |     |\    |     |\    |
-- clk_CD1_I --------------------------|/____|  /--|/____|  /--|/____|
--                                              |           |
-- clk_CD1_O ------------------------------------------------
--
  bl_pulse2level : if (g_type = "Pulse2Level") generate
    signal s_dat_tmp_CD1 : std_logic := '0';
    signal s_dat_tmp_CD2 : std_logic_vector(1 downto 0) := (others => '0');
    -- set attribute to tell VIVADO that the following two registers are CDC purpose. Don't Touch and place next to each other
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of s_dat_tmp_CD2 : signal is "true";
  begin
       -- Flip-Flop in input clock domain
       process(clk_CD1_I)
       begin
         if rising_edge(clk_CD1_I) then
             if (dat_CD1_I = '0') then
               s_dat_tmp_CD1 <=     s_dat_tmp_CD1;
             else
               s_dat_tmp_CD1 <= not s_dat_tmp_CD1;
             end if;
         end if;
       end process;

       -- Synchronizer Flip-Flops in output clock domain
       process(clk_CD2_I)
       begin
         if rising_edge(clk_CD2_I) then
             s_dat_tmp_CD2 <= s_dat_tmp_CD2(s_dat_tmp_CD2'left - 1 downto 0) & s_dat_tmp_CD1;
         end if;
       end process;

       dat_CD2_O <= s_dat_tmp_CD2(s_dat_tmp_CD2'left);

  end generate bl_pulse2level;
-------------------------------------------------------
-- PULSE 2 PULSE
-------------------------------------------------------
--                                                                                       ___
--              /-------------------------------\                       /---------------|   |
--              |          ___          _____   |   _____       _____   |    _____      |XOR|-----   dat_CD1_O
--              |----|>0--|1  |        |     |  |  |     |     |     |  |   |     |     |   |
-- dat_CD1_I \  |         |MUX|--------|     |-----|     |-----|     |------|     |-----|___|
--            \ \---------|0__|        |     |     |     |     |     |      |     |
--             \-----------/           |\    |     |\    |     |\    |      |\    |
-- clk_CD1_I --------------------------|/____|  /--|/____|  /--|/____|      |/____|
--                                              |           |
-- clk_CD1_O ------------------------------------------------
--
  bl_pulse2pulse : if (g_type = "Pulse2Pulse") generate
    signal s_dat_tmp_CD1 : std_logic := '0';
    signal s_dat_tmp_CD2 : std_logic_vector(2 downto 0) := (others => '0');
    -- set attribute to tell VIVADO that the following two registers are CDC purpose. Don't Touch and place next to each other
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of s_dat_tmp_CD2 : signal is "true";
  begin
       -- Flip-Flop in input clock domain
       process(clk_CD1_I)
       begin
         if rising_edge(clk_CD1_I) then
             if (dat_CD1_I = '0') then
               s_dat_tmp_CD1 <=     s_dat_tmp_CD1;
             else
               s_dat_tmp_CD1 <= not s_dat_tmp_CD1;
             end if;
         end if;
       end process;

       -- Synchronizer Flip-Flops in output clock domain
       process(clk_CD2_I)
       begin
         if rising_edge(clk_CD2_I) then
           s_dat_tmp_CD2 <= s_dat_tmp_CD2(s_dat_tmp_CD2'left - 1 downto 0) & s_dat_tmp_CD1;
         end if;
       end process;

       dat_CD2_O <= s_dat_tmp_CD2(s_dat_tmp_CD2'left) xor s_dat_tmp_CD2(s_dat_tmp_CD2'left - 1);

  end generate bl_pulse2pulse;
-------------------------------------------------------
END arch_cdc;
