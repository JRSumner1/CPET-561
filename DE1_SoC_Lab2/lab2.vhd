library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

------------------------------------------------------------------------
--  Entity Declaration for your top-level
------------------------------------------------------------------------
entity lab2 is
	port (
		CLOCK_50       : in  std_logic;
		KEY            : in  std_logic_vector(3 downto 0);
		SW             : in  std_logic_vector(7 downto 0);
		HEX0           : out std_logic_vector(7 downto 0)
	);
end entity lab2;

architecture lab2_arch of lab2 is

	component nios_system
		port (
			clk_clk         : in  std_logic;
			reset_reset_n   : in  std_logic;
			buttons_export  : in  std_logic_vector(3 downto 0);
			switches_export : in  std_logic_vector(7 downto 0);
			hex0_export     : out std_logic_vector(7 downto 0)
		);
	end component;

begin
	u0 : nios_system
		port map (
			clk_clk       		=> CLOCK_50,
			reset_reset_n 		=> KEY(0),
			buttons_export    => KEY,
			switches_export	=> SW,
			hex0_export   		=> HEX0
		);
	
end architecture lab2_arch;
