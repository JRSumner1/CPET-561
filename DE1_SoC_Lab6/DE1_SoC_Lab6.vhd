library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE1_SoC_Lab6 is
	port (
		CLOCK_50       : in  std_logic;
		KEY				: in  std_logic_vector(3 downto 0);
		LEDR				: out std_logic_vector(7 downto 0)
	);
end entity DE1_SoC_Lab6;

architecture rtl of DE1_SoC_Lab6 is
	component nios_system is
		port (
			clk_clk            : in  std_logic;
			leds_export_export : out std_logic_vector(7 downto 0);
			key_export_export  : in  std_logic
		);
	end component nios_system;
begin
	u0 : nios_system
	port map (
		clk_clk            => CLOCK_50,
		leds_export_export => LEDR,
		key_export_export  => KEY(1)
	);
end architecture rtl;