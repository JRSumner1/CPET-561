library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE1_SoC_Lab3 is
	port (
		CLOCK_50       : in  std_logic;
		KEY            : in  std_logic_vector(3 downto 0);
		SW             : in  std_logic_vector(7 downto 0);
		HEX0           : out std_logic_vector(6 downto 0);
		LEDR				: out std_logic_vector(7 downto 0)
	);
end entity DE1_SoC_Lab3;

ARCHITECTURE Structure OF DE1_SoC_Lab3 IS	
	component nios_system is
		port (
			clk_clk            : in  std_logic                    := 'X';             -- clk
			leds_export        : out std_logic_vector(7 downto 0);                    -- export
			reset_reset_n      : in  std_logic                    := 'X';             -- reset_n
			switches_export    : in  std_logic_vector(7 downto 0) := (others => 'X'); -- export
			pushbuttons_export : in  std_logic_vector(3 downto 0) := (others => 'X'); -- export
			hex0_export        : out std_logic_vector(6 downto 0)                     -- export
		);
	end component nios_system;
BEGIN
	u0 : component nios_system
		port map (
			clk_clk            => CLOCK_50,
			leds_export        => LEDR(7 downto 0),
			reset_reset_n      => KEY(0),
			switches_export    => SW,
			pushbuttons_export => KEY,
			hex0_export        => HEX0
		);
END Structure; 