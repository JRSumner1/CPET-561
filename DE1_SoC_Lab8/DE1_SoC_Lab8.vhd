library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE1_SoC_Lab8 is
  port (
    CLOCK_50 : in  std_logic;
    KEY      : in  std_logic_vector(3 downto 0)
  );
end DE1_SoC_Lab8;

architecture rtl of DE1_SoC_Lab8 is
	component low_pass_filter is
		port (
			CLOCK_50  : in std_logic;
			reset_n   : in std_logic;
			filter_en : in std_logic;
			data_in   : in std_logic_vector(15 DOWNTO 0);
			data_out  : out std_logic_vector(15 DOWNTO 0)
		);
	end component;

	component high_pass_filter is
		port (
			CLOCK_50  : in std_logic;
			reset_n   : in std_logic;
			filter_en : in std_logic;
			data_in   : in std_logic_vector(15 DOWNTO 0);
			data_out  : out std_logic_vector(15 DOWNTO 0)
		);
	end component;

	SIGNAL key0_d1 : std_logic;
	SIGNAL key0_d2 : std_logic;
	SIGNAL key0_d3 : std_logic;

	SIGNAL keys_d1  : std_logic_vector(3 DOWNTO 0);
	SIGNAL keys_d2  : std_logic_vector(3 DOWNTO 0);
	SIGNAL keys_d3  : std_logic_vector(3 DOWNTO 0);
	SIGNAL keys_sig : std_logic_vector(3 DOWNTO 0);

	signal reset_n    : std_logic := '0';
	signal data_out_low : std_logic_vector(15 downto 0);
	signal data_out_high : std_logic_vector(15 downto 0);
begin
	synchReset_proc : process (CLOCK_50, reset_n)
	begin
		if (rising_edge(CLOCK_50)) then
			key0_d1 <= KEY(0);
			key0_d2 <= key0_d1;
			key0_d3 <= key0_d2;
			reset_n <= key0_d3;
	end if;
	end process synchReset_proc;

	synchKeys_proc : process (CLOCK_50, reset_n)
	begin
		if (reset_n = '0') then
			keys_d1 <= (others => '0');
			keys_d3 <= (others => '0');
		elsif (rising_edge(CLOCK_50)) then
			keys_d1 <= KEY;
			keys_d2 <= keys_d1;
			keys_d3 <= keys_d2;
			keys_sig <= keys_d3;
		end if;
	end process synchKeys_proc;

	my_fir_filter : low_pass_filter
	port map (
		CLOCK_50  => CLOCK_50,
		reset_n   => reset_n,
		filter_en => '0',
		data_in   => (others => '0'),
		data_out  => data_out_low
	);
end rtl;
