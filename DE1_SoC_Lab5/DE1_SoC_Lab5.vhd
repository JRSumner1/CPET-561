library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE1_SoC_Lab5 is
	port (
		CLOCK_50       : in  std_logic;
		KEY				: in  std_logic_vector(3 downto 0);
		GPIO_0			: out std_logic_vector(35 downto 0)
	);
end entity DE1_SoC_Lab5;

architecture rtl of DE1_SoC_Lab5 is
	component nios_system is
		port (
			clk_clk            : in  std_logic;
			reset_reset_n      : in  std_logic;
			hex0_export        : out std_logic_vector(6 downto 0);
			hex1_export        : out std_logic_vector(6 downto 0);
			hex2_export        : out std_logic_vector(6 downto 0);
			hex4_export        : out std_logic_vector(6 downto 0);
			hex5_export		    : out std_logic_vector(6 downto 0);
			pushbuttons_export : in  std_logic_vector(3 downto 0);
			switches_export    : in  std_logic_vector(7 downto 0);
			servo_controller_writeresponsevalid_n : out std_logic
		);
	end component nios_system;

	component servo_controller is
		port (
			clk              : in  std_logic;
			reset_n          : in  std_logic;
			write            : in  std_logic;
			address          : in  std_logic;
			writedata        : in  std_logic_vector(31 downto 0);
			outwave_export   : out std_logic;
			interrupt_sender : out std_logic
		);
	end component servo_controller;

	signal nios_reset_n : std_logic;
   signal servo_irq    : std_logic;
	
	signal hex0 : std_logic_vector(6 downto 0);
   signal hex1 : std_logic_vector(6 downto 0);
   signal hex2 : std_logic_vector(6 downto 0);
   signal hex3 : std_logic_vector(6 downto 0);
   signal hex4 : std_logic_vector(6 downto 0);
   signal hex5 : std_logic_vector(6 downto 0);
	 
	signal switches : std_logic_vector(7 downto 0) := (others => '0');
	signal interrupt : std_logic;
begin
	nios_reset_n <= KEY(0);
	
	u_nios_system : nios_system
		port map (
			clk_clk        => CLOCK_50,
			reset_reset_n  => nios_reset_n,
			pushbuttons_export => KEY,
			switches_export    => switches,
			hex0_export => hex0,
			hex1_export => hex1,
			hex2_export => hex2,
			hex4_export => hex4,
			hex5_export => hex5,
			servo_controller_writeresponsevalid_n => interrupt
		);

	u_servo_controller : servo_controller
		port map (
			clk => CLOCK_50,
			reset_n => nios_reset_n,
			interrupt_sender => servo_irq,
			outwave_export => GPIO_0(0),
			write => '1',
			address => '0',
			writedata => x"0000C350"
		);
end architecture rtl;
			