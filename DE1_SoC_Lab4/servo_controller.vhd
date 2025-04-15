library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity servo_controller is
	port (
		clk              : in  std_logic;
		reset_n          : in  std_logic;
		write            : in  std_logic;
		address          : in  std_logic;
		writedata        : in  std_logic_vector(31 downto 0);
		outwave_export   : out std_logic;
		interrupt_sender : out std_logic
	);
end entity servo_controller;

architecture rtl of servo_controller is
	type state_type is (SWEEP_RIGHT, SWEEP_LEFT, INT_RIGHT, INT_LEFT);
	signal fsm_state : state_type := SWEEP_RIGHT;

	constant PERIOD_MAX : unsigned(31 downto 0) := to_unsigned(1000000, 32);

	signal min_angle_count : unsigned(31 downto 0) := to_unsigned(50000, 32);
	signal max_angle_count : unsigned(31 downto 0) := to_unsigned(100000, 32);
	signal period_counter  : unsigned(31 downto 0) := (others => '0');

	signal angle_counter : unsigned(31 downto 0) := to_unsigned(50000, 32);
	signal flag, irq : std_logic := '0';
	
--	write            : in  std_logic := '1';
--	address          : in  std_logic := '0';
--	writedata        : in  std_logic_vector(31 downto 0) := 0xC350;
begin
	-- 1) Register Write
	process(clk, reset_n)
	begin
		if reset_n = '0' then
			min_angle_count <= to_unsigned(50000, 32);
			max_angle_count <= to_unsigned(100000, 32);
		elsif rising_edge(clk) then
			if write = '1' then
				if address = '0' then
					min_angle_count <= unsigned(writedata);
				else
					max_angle_count <= unsigned(writedata);
				end if;
			end if;
		end if;
	end process;

	-- 2) Period Counter
	process(clk, reset_n)
	begin
		if reset_n = '0' then
			period_counter <= (others => '0');
		elsif rising_edge(clk) then
			if period_counter <= PERIOD_MAX - 1 then
				period_counter <= period_counter + 1;
			else
				period_counter <= (others => '0');
			end if;
		end if;
	end process;

	-- 3) Angle Counter
	process(clk, reset_n)
	begin
		if reset_n = '0' then
			angle_counter <= to_unsigned(50000, 32);
			flag <= '0';
		elsif rising_edge(clk) then
			flag <= '0';
			if period_counter >= PERIOD_MAX - 1 then
				case fsm_state is
					when SWEEP_RIGHT =>
						if angle_counter >= max_angle_count then
							angle_counter <= angle_counter;
							flag <= '1';
						else
							angle_counter <= angle_counter + 500;
						end if;
					when SWEEP_LEFT =>
						if angle_counter <= min_angle_count then
							angle_counter <= angle_counter;
							flag <= '1';
						else
							angle_counter <= angle_counter - 500;
						end if;
					when others =>
						angle_counter <= angle_counter;
				end case;
			end if;
		end if;
	end process;

	-- 4) IRQ
	process(clk, reset_n)
	begin
		if reset_n = '0' then
			irq <= '0';
		elsif rising_edge(clk) then
			if write = '1' then
				irq <= '0';
			elsif flag = '1' then
				irq <= '1';
			end if;
		end if;
	end process;

	-- 5) FSM State
	process(clk, reset_n)
	begin
		if reset_n = '0' then
			fsm_state <= SWEEP_RIGHT;
		elsif rising_edge(clk) then
			case fsm_state is
				when SWEEP_RIGHT =>
					if angle_counter >= max_angle_count then
						fsm_state <= INT_RIGHT;
					end if;
				when SWEEP_LEFT =>
					if angle_counter <= min_angle_count then
						fsm_state <= INT_LEFT;
					end if;
				when INT_RIGHT =>
					if write = '1' then
						fsm_state <= SWEEP_LEFT;
					end if;
				when INT_LEFT =>
					if write = '1' then
						fsm_state <= SWEEP_RIGHT;
					end if;
				end case;
		end if;
	end process;

	outwave_export <= '1' when period_counter < angle_counter else '0';
	interrupt_sender <= irq;

end architecture rtl;