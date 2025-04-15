LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;

ENTITY filter_tb IS
END filter_tb;

ARCHITECTURE sim OF filter_tb IS
--	component low_pass_filter
--		port (
--			CLOCK_50  : in  std_logic;
--			reset_n   : in  std_logic;
--			filter_en : in  std_logic;
--			data_in   : in  std_logic_vector(15 downto 0);
--			data_out  : out std_logic_vector(15 downto 0)
--		);
--	end component;

	-- High‑pass FIR
	component high_pass_filter
		port (
			CLOCK_50  : in  std_logic;
			reset_n   : in  std_logic;
			filter_en : in  std_logic;
			data_in   : in  std_logic_vector(15 downto 0);
			data_out  : out std_logic_vector(15 downto 0)
		);
	end component;

	CONSTANT period  : TIME := 20 ns;
	SIGNAL CLOCK_50  : STD_LOGIC                     := '0';
	SIGNAL reset     : STD_LOGIC                     := '0';
	SIGNAL filter_en : STD_LOGIC                     := '0';
	SIGNAL data_in   : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL data_out  : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

	TYPE audioSampleArrayType IS ARRAY (0 TO 39) OF signed(15 DOWNTO 0);
	SIGNAL audioSampleArray : audioSampleArrayType;

	SIGNAL sim_done : BOOLEAN := false;

BEGIN
	uut : high_pass_filter
	PORT MAP
	(
		CLOCK_50  => CLOCK_50,
		reset_n   => reset,
		filter_en => filter_en,
		data_in   => data_in,
		data_out  => data_out
	);
	
	CLOCK_50_gen : PROCESS
	BEGIN
		CLOCK_50 <= '0';
		WAIT FOR period / 2;
		CLOCK_50 <= '1';
		WAIT FOR period / 2;
	END PROCESS;

	async_reset : PROCESS
	BEGIN
		reset <= '0';
		WAIT FOR 100 ns;
		reset <= '1';
		WAIT;
	END PROCESS;

	stimulus : PROCESS IS
		FILE read_file      : text OPEN read_mode IS "one_cycle_200_8k.csv";
		FILE results_file   : text OPEN write_mode IS "output_waveform.csv";
		VARIABLE lineIn     : line;
		VARIABLE lineOut    : line;
		VARIABLE readValue  : INTEGER;
		VARIABLE writeValue : INTEGER;
	BEGIN
		WAIT FOR 100 ns;

		FOR i IN 0 TO 39 LOOP
			readline(read_file, lineIn);
			read(lineIn, readValue);
			audioSampleArray(i) <= to_signed(readValue, 16);
			WAIT FOR 50 ns;
		END LOOP;
		file_close(read_file);

		FOR i IN 1 TO 10 LOOP
			FOR j IN 0 TO 39 LOOP
				data_in   <= STD_LOGIC_VECTOR(audioSampleArray(j));
				filter_en <= '1';
				WAIT FOR period;
				filter_en <= '0';

				WAIT FOR period * 2;

				writeValue := to_integer(signed(data_out));
				write(lineOut, writeValue);
				writeline(results_file, lineOut);
			END LOOP;
		END LOOP;
		file_close(results_file);
 
		sim_done <= true;
		WAIT FOR 100 ns;
		WAIT;
	END PROCESS stimulus;
END sim;