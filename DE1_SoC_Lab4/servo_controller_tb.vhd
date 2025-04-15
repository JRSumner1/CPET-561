library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity servo_controller_tb is
end servo_controller_tb;

architecture sim of servo_controller_tb is

    signal clk           : std_logic := '0';
    signal reset_n       : std_logic := '0';
    signal write_s       : std_logic := '0';
    signal address_s     : std_logic := '0';
    signal writedata_s   : std_logic_vector(31 downto 0) := (others => '0');
    signal outwave_s     : std_logic;
    signal interrupt_s   : std_logic;

    constant CLK_PERIOD  : time := 20 ns;
begin
    UUT: entity work.servo_controller
        port map (
            clk              => clk,
            reset_n          => reset_n,
            write            => write_s,
            address          => address_s,
            writedata        => writedata_s,
            outwave_export   => outwave_s,
            interrupt_sender => interrupt_s
        );

    clk_proc: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    reset_proc: process
    begin
        reset_n <= '0';
        wait for CLK_PERIOD;
        reset_n <= '1';
        wait;
    end process;

    test_proc: process
    begin
		wait until interrupt_s = '1';
		write_s <= '1';
		address_s <= '0';
		writedata_s <= std_logic_vector(to_unsigned(15000 + 10000, 32));
		wait for CLK_PERIOD*2;
		write_s <= '0';

		wait until interrupt_s = '1';
		write_s <= '1';
		address_s <= '1';
		writedata_s <= std_logic_vector(to_unsigned(80000 + 10000, 32));
		wait for CLK_PERIOD*2;
		write_s <= '0';
		
    end process;

end architecture sim;
