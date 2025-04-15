LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_signed.ALL;

-- Import components
LIBRARY WORK;
USE WORK.components.ALL;

ENTITY low_pass_filter IS
  PORT (
    CLOCK_50  : IN STD_LOGIC; -- 50MHz clock
    reset_n   : IN STD_LOGIC; -- Active low reset
    filter_en : IN STD_LOGIC;
    data_in   : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

    -- Outputs
    data_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END low_pass_filter;

ARCHITECTURE Structure OF low_pass_filter IS
  CONSTANT max_index : INTEGER := 16; -- Max number for the generate statements

  -- Arrays to hold several versions of the input and output signals.
  TYPE t_array_in IS ARRAY (0 TO 16) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
  TYPE t_array_out IS ARRAY (0 TO 16) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL dataa_signals  : t_array_in;  -- Signal at the triangle’s input
  SIGNAL datab_signals  : t_array_in;  -- Coefficient constants
  SIGNAL result_signals : t_array_out; -- Holds the output of the individual multiplier
  SIGNAL result         : t_array_in;  -- Holds the final value of the filter to be output

  SIGNAL delay_reg : t_array_in;

BEGIN
  -- Port map datab to the hex values coefficient constants.
  datab_signals(0)  <= X"0052";
  datab_signals(1)  <= X"00BB";
  datab_signals(2)  <= X"01E2";
  datab_signals(3)  <= X"0408";
  datab_signals(4)  <= X"071B";
  datab_signals(5)  <= X"0AAD";
  datab_signals(6)  <= X"0E11";
  datab_signals(7)  <= X"1080";
  datab_signals(8)  <= X"1162";
  datab_signals(9)  <= X"1080";
  datab_signals(10) <= X"0E11";
  datab_signals(11) <= X"0AAD";
  datab_signals(12) <= X"071B";
  datab_signals(13) <= X"0408";
  datab_signals(14) <= X"01E2";
  datab_signals(15) <= X"00BB";
  datab_signals(16) <= X"0052";

  delay_reg(0) <= data_in;

  generate_shift : FOR i IN 1 TO max_index GENERATE
    -- Enable process with data increment
    shift_reg : PROCESS (CLOCK_50, reset_n)
    BEGIN
      IF (reset_n = '0') THEN
        delay_reg(i) <= (OTHERS => '0'); -- Reset output
      ELSIF rising_edge(CLOCK_50) THEN
        IF (filter_en = '1') THEN
          delay_reg(i) <= delay_reg(i - 1);
        END IF;
      END IF;
    END PROCESS;
  END GENERATE generate_shift;

  -- Instantiate 16 multipliers using a generate statement.
  generate_multi : FOR i IN 0 TO max_index GENERATE
  BEGIN
    dataa_signals(i) <= delay_reg(i); -- Set data_in as input for each multiplier

    MULTX : multiplier
    PORT MAP
    (
      dataa  => dataa_signals(i),
      datab  => datab_signals(i),
      result => result_signals(i)
    );
  END GENERATE generate_multi;

  generate_adder : FOR i IN 1 TO max_index GENERATE
  BEGIN
    result(0) <= STD_LOGIC_VECTOR(SIGNED(result_signals(0)(30 DOWNTO 15)));
    result(i) <= STD_LOGIC_VECTOR(SIGNED(result(i - 1)) + SIGNED(result_signals(i)(30 DOWNTO 15)));
  END GENERATE generate_adder;

  data_out <= result(max_index);

END Structure;