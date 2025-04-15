LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
ENTITY raminfr_be IS
	PORT(
		clk : IN std_logic;
		reset_n : IN std_logic;
		writebyteenable_n : IN std_logic_vector(3 downto 0);
		address : IN std_logic_vector(11 DOWNTO 0);
		writedata : IN std_logic_vector(31 DOWNTO 0);
		--
		readdata : OUT std_logic_vector(31 DOWNTO 0)
		);
	END ENTITY raminfr_be;

ARCHITECTURE rtl OF raminfr_be IS

	TYPE ram_byte IS ARRAY (4095 DOWNTO 0) OF std_logic_vector (7 DOWNTO 0);
	SIGNAL RAM0 : ram_byte;
	SIGNAL RAM1 : ram_byte;
	SIGNAL RAM2 : ram_byte;
	SIGNAL RAM3 : ram_byte;
	SIGNAL read_addr : std_logic_vector(11 DOWNTO 0);

BEGIN

	RamBlock : PROCESS(clk)
	BEGIN
		IF (clk'event AND clk = '1') THEN
			IF (reset_n = '0') THEN
				read_addr <= (OTHERS => '0');
			ELSE
				IF (writebyteenable_n(0) = '0') THEN
					RAM0(conv_integer(address)) <= writedata(7 downto 0);
				END IF;
				IF (writebyteenable_n(1) = '0') THEN
					RAM1(conv_integer(address)) <= writedata(15 downto 8);
				END IF;
				IF (writebyteenable_n(2) = '0') THEN
					RAM2(conv_integer(address)) <= writedata(23 downto 16);
				END IF;
				IF (writebyteenable_n(3) = '0') THEN
					RAM3(conv_integer(address)) <= writedata(31 downto 24);
				END IF;
				read_addr <= address;
			END IF;
		END IF;
	END PROCESS RamBlock;
	readdata <= RAM3(conv_integer(read_addr)) & 
					RAM2(conv_integer(read_addr)) &
					RAM1(conv_integer(read_addr)) &
					RAM0(conv_integer(read_addr));
END ARCHITECTURE rtl;