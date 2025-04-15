LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_signed.ALL;

ENTITY low_pass_filter IS
  PORT (
    CLOCK_50  : IN STD_LOGIC;
    reset_n   : IN STD_LOGIC;
    filter_en : IN STD_LOGIC;
    data_in   : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    data_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END low_pass_filter;

ARCHITECTURE rtl OF low_pass_filter IS
	component multiplier
		port (
			dataa  : in  std_logic_vector(15 downto 0);
			datab  : in  std_logic_vector(15 downto 0);
			result : out std_logic_vector(31 downto 0)
		);
	end component;
	
	CONSTANT max_index : INTEGER := 16;
	TYPE t_array_in IS ARRAY (0 TO 16) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
	TYPE t_array_out IS ARRAY (0 TO 16) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL dataa_signals : t_array_in;
	SIGNAL datab_signals : t_array_in;
	SIGNAL result_signals : t_array_out;
	SIGNAL result : t_array_in;

	SIGNAL delay_reg : t_array_in;
BEGIN
	datab_signals(0)  <= X"003E";
	datab_signals(1)  <= X"FF9A";
	datab_signals(2)  <= X"FE9F";
	datab_signals(3)  <= X"0000";
	datab_signals(4)  <= X"0535";
	datab_signals(5)  <= X"05B2";
	datab_signals(6)  <= X"F5AC";
	datab_signals(7)  <= X"DAB7";
	datab_signals(8)  <= X"4C91";
	datab_signals(9)  <= X"DAB7";
	datab_signals(10) <= X"F5AC";
	datab_signals(11) <= X"05B2";
	datab_signals(12) <= X"0525";
	datab_signals(13) <= X"0000";
	datab_signals(14) <= X"FE9F";
	datab_signals(15) <= X"FF9B";
	datab_signals(16) <= X"003E";

	delay_reg(0) <= data_in;

	shift_gen : FOR i IN 1 TO max_index GENERATE
		shift_reg : PROCESS (CLOCK_50, reset_n)
		BEGIN
			IF (reset_n = '0') THEN
				delay_reg(i) <= (OTHERS => '0');
			ELSIF rising_edge(CLOCK_50) THEN
				IF (filter_en = '1') THEN
					delay_reg(i) <= delay_reg(i - 1);
				END IF;
			END IF;
		END PROCESS;
	END GENERATE shift_gen;

	multi_gen : FOR i IN 0 TO max_index GENERATE
	BEGIN
		dataa_signals(i) <= delay_reg(i);
		MULTX : multiplier
		PORT MAP
		(
			dataa  => dataa_signals(i),
			datab  => datab_signals(i),
			result => result_signals(i)
		);
	END GENERATE multi_gen;

	adder_gen : FOR i IN 1 TO max_index GENERATE
	BEGIN
		result(0) <= STD_LOGIC_VECTOR(SIGNED(result_signals(0)(30 DOWNTO 15)));
		result(i) <= STD_LOGIC_VECTOR(SIGNED(result(i - 1)) + SIGNED(result_signals(i)(30 DOWNTO 15)));
	END GENERATE adder_gen;

	data_out <= result(max_index);
END rtl;