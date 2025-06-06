LIBRARY ieee;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY tb_raminfr_be IS
END tb_raminfr_be;

ARCHITECTURE behavior OF tb_raminfr_be IS

	COMPONENT raminfr_be IS
		PORT(
			clk               : IN std_logic;
			reset_n           : IN std_logic;
			writebyteenable_n : IN std_logic_vector(3 DOWNTO 0);
			address           : IN std_logic_vector(11 DOWNTO 0);
			writedata         : IN std_logic_vector(31 DOWNTO 0);
			readdata          : OUT std_logic_vector(31 DOWNTO 0)
		);
	END COMPONENT;

	SIGNAL clk               : std_logic := '0';
	SIGNAL reset_n           : std_logic := '0';
	SIGNAL writebyteenable_n : std_logic_vector(3 DOWNTO 0) := (others => '1'); -- inactive (high)
	SIGNAL address           : std_logic_vector(11 DOWNTO 0) := (others => '0');
	SIGNAL writedata         : std_logic_vector(31 DOWNTO 0) := (others => '0');
	SIGNAL readdata          : std_logic_vector(31 DOWNTO 0);

	CONSTANT clk_period : time := 20 ns;

BEGIN
	uut: raminfr_be
		PORT MAP (
			clk               => clk,
			reset_n           => reset_n,
			writebyteenable_n => writebyteenable_n,
			address           => address,
			writedata         => writedata,
			readdata          => readdata
		);

	clk_process : PROCESS
	BEGIN
		clk <= '0';
		WAIT FOR clk_period/2;
		clk <= '1';
		WAIT FOR clk_period/2;
	END PROCESS clk_process;

	stim_proc: PROCESS
	BEGIN
		reset_n <= '0';
		WAIT FOR clk_period*2;
		reset_n <= '1';
		WAIT FOR clk_period*2;

		-- Full word
		for i in 0 to 11 loop
			address <= std_logic_vector(to_unsigned(i, 12));
			writedata <= x"00000000";
			writebyteenable_n <= "0000";
			WAIT FOR clk_period*2;
			ASSERT readdata = x"00000000" report "Full word write failed at address: " & integer'image(i);
		end loop;
		
		-- Top half word
		for i in 0 to 11 loop
			address <= std_logic_vector(to_unsigned(i, 12));
			writedata <= x"11111111";
			writebyteenable_n <= "0011";
			WAIT FOR clk_period*2;
			ASSERT readdata = x"11110000" report "Top half word write failed at address: " & integer'image(i);
		end loop;
		
		-- Bottom half word
		for i in 0 to 11 loop
			address <= std_logic_vector(to_unsigned(i, 12));
			writedata <= x"22222222";
			writebyteenable_n <= "1100";
			WAIT FOR clk_period*2;
			ASSERT readdata = x"11112222" report "Bottom half word write failed at address: " & integer'image(i);
		end loop;
		
		-- Byte 3
		for i in 0 to 11 loop
			address <= std_logic_vector(to_unsigned(i, 12));
			writedata <= x"AAAAAAAA";
			writebyteenable_n <= "0111";
			WAIT FOR clk_period*2;
			ASSERT readdata = x"AA112222" report "Byte 0 write failed at address: " & integer'image(i);
		end loop;
		
		-- Byte 2
		for i in 0 to 11 loop
			address <= std_logic_vector(to_unsigned(i, 12));
			writedata <= x"BBBBBBBB";
			writebyteenable_n <= "1011";
			WAIT FOR clk_period*2;
			ASSERT readdata = x"AABB2222" report "Byte 1 word write failed at address: " & integer'image(i);
		end loop;
		
		-- Byte 1
		for i in 0 to 11 loop
			address <= std_logic_vector(to_unsigned(i, 12));
			writedata <= x"CCCCCCCC";
			writebyteenable_n <= "1101";
			WAIT FOR clk_period*2;
			ASSERT readdata = x"AABBCC22" report "Byte 2 word write failed at address: " & integer'image(i);
		end loop;
		
		-- Byte 0
		for i in 0 to 11 loop
			address <= std_logic_vector(to_unsigned(i, 12));
			writedata <= x"DDDDDDDD";
			writebyteenable_n <= "1110";
			WAIT FOR clk_period*2;
			ASSERT readdata = x"AABBCCDD" report "Byte 3 word write failed at address: " & integer'image(i);
		end loop;
	
		WAIT FOR 50 ns;
		assert false report "End of simulation";
	END PROCESS stim_proc;
END ARCHITECTURE behavior;
