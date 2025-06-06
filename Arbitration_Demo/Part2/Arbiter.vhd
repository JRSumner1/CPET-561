LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY Bus_Arbiter IS

-------------------------------------------------------------------------------
--                             Port Declarations                             --
-------------------------------------------------------------------------------
PORT (
	-- Inputs
	clk                  : IN STD_LOGIC;
	reset_n              : IN STD_LOGIC;
	cpu_0_address        : IN STD_LOGIC_VECTOR (10 DOWNTO 0);
	cpu_0_bus_enable     : IN STD_LOGIC;
	cpu_0_byte_enable    : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
	cpu_0_rw             : IN STD_LOGIC;
	cpu_0_write_data     : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
	cpu_1_address        : IN STD_LOGIC_VECTOR (10 DOWNTO 0);
	cpu_1_bus_enable     : IN STD_LOGIC;
	cpu_1_byte_enable    : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
	cpu_1_rw             : IN STD_LOGIC;
	cpu_1_write_data     : IN STD_LOGIC_VECTOR (15 DOWNTO 0);

	
	-- Outputs
	cpu_0_acknowledge    : OUT STD_LOGIC;
	cpu_0_read_data      : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
	cpu_1_acknowledge    : OUT STD_LOGIC;
	cpu_1_read_data      : OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END Bus_Arbiter;

ARCHITECTURE Bus_Arbiter_rtl OF Bus_Arbiter IS

--The Ram controller is taken from part 1. it is an interface from the bus bridge to the RAM

 COMPONENT RAM_controller is
	PORT( clk                : in  std_logic                     := 'X';             -- clk
			reset_n            : in  std_logic                     := 'X';             -- reset_n
         ---- Bridge Interface 
			bridge_acknowledge : out  std_logic                     := 'X';             -- acknowledge
			bridge_irq         : out  std_logic                     := 'X';             -- irq
			bridge_address     : in std_logic_vector(10 downto 0);                    -- address
			bridge_bus_enable  : in std_logic;                                        -- bus_enable
			bridge_byte_enable : in std_logic_vector(1 downto 0);                     -- byte_enable
			bridge_rw          : in std_logic;                                        -- rw (0 = write, 1= read)
			bridge_write_data  : in std_logic_vector(15 downto 0);                    -- write_data
			bridge_read_data   : out  std_logic_vector(15 downto 0) := (others => 'X');  -- read_data
			---- RAM interface
			ram_address		: out STD_LOGIC_VECTOR (10 DOWNTO 0);
			ram_data		   : out STD_LOGIC_VECTOR (15 DOWNTO 0);
			ram_wren		   : out STD_LOGIC ;
			ram_q		      : in STD_LOGIC_VECTOR (15 DOWNTO 0));
	end component;

--the external RAM is generated by Altera MegaWizard Plug-in Manager	
	component external_RAM IS
		PORT(
			address		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			wren		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		);
	END Component;

--the arbiter is a state machine so define the states here
type state_type is (IDLE,CPU_0,CPU_1);
signal current_state,next_state : state_type;
		
-------------------------------------------------------------------------------
--                 Internal Wires                                            --
-------------------------------------------------------------------------------
-- Internal Wires
signal priority_reg, next_priority : std_logic;

signal bus_enable_both : std_logic_vector(1 downto 0);	
signal acknowledge,bus_enable,rw : std_logic;
signal read_data, write_data : std_logic_vector(15 downto 0);
signal address : std_logic_vector(10 downto 0);
signal byte_enable : std_logic_vector(1 downto 0);
signal irq : std_logic;
	
signal ram_address_int : STD_LOGIC_VECTOR (10 DOWNTO 0);
signal ram_data_int 	 : STD_LOGIC_VECTOR (15 DOWNTO 0);
signal ram_wren_int	 : STD_LOGIC;
signal ram_q_int		 : STD_LOGIC_VECTOR (15 DOWNTO 0);
	
begin

-- create a signal to indicate which bridge has been enabled
bus_enable_both <= cpu_0_bus_enable & cpu_1_bus_enable;

-------------------------------------------------------------------------------
--                         Finite State Machine                              --
-------------------------------------------------------------------------------
sync: process(clk,reset_n)
  begin
    if (reset_n = '0') then
      current_state <= IDLE;
    elsif (clk'event and clk = '1') then
      current_state <= next_state;
    end if;
 end process;
-------------------------------------------------------------------------------
--                            Combinational Logic                            --
-------------------------------------------------------------------------------
comb: process(current_state,bus_enable_both,bus_enable)
  begin
    case(current_state) is
      when idle =>
        case (bus_enable_both) is
          when "10" =>
            next_state <= CPU_0;
          when "01" =>
            next_state <= CPU_1;
          when "11" =>  
				if priority_reg = '0' then
					-- CPU_0 has priority this time
					next_state    <= CPU_0;
					next_priority <= '1';  -- flip for next time
				else
					-- CPU_1 has priority this time
					next_state    <= CPU_1;
					next_priority <= '0';  -- flip for next time
				end if;
		 when others =>
              next_state <= IDLE;
          end case;
      when CPU_0 =>
        if (bus_enable = '0') then
          next_state <= IDLE;
        else
          next_state <= CPU_0;
        end if;
      when CPU_1 =>
        if (bus_enable = '0') then
          next_state <= IDLE;
        else 
          next_state <= CPU_1;
        end if;
      when others =>
        next_state <= IDLE;
      end case;
  end process;

  
 --this process assigns all of the signals based on which bridge is selected
 --Note - it is not the best coding style to use one process for all the 
 --  outputs (j. christman)
 
process(current_state,cpu_0_bus_enable,cpu_0_byte_enable,cpu_0_rw,
	 cpu_0_address,cpu_0_write_data,cpu_1_bus_enable,cpu_1_byte_enable,cpu_1_rw,
	 cpu_1_address,cpu_1_write_data) is
  begin
    case (current_state) is
       when CPU_0 =>
         bus_enable <= cpu_0_bus_enable;
         byte_enable <= cpu_0_byte_enable;
         rw <= cpu_0_rw;
         address <= cpu_0_address;
         write_data <= cpu_0_write_data;  
		cpu_0_acknowledge <= acknowledge;
		cpu_0_read_data <= read_data;
		cpu_1_acknowledge <= '0';
		cpu_1_read_data <= (others => '0');
       
      when others =>
         bus_enable <= cpu_1_bus_enable;
         byte_enable <= cpu_1_byte_enable;
         rw <= cpu_1_rw;
         address <= cpu_1_address;
         write_data <= cpu_1_write_data;  
		cpu_0_acknowledge <= '0';
		cpu_0_read_data <= (others => '0');
		cpu_1_acknowledge <= acknowledge;
		cpu_1_read_data <= read_data;
         
      end case;
    end process;  
    


             
-------------------------------------------------------------------------------
--                              Internal Modules                             --
-------------------------------------------------------------------------------


u1: RAM_controller 
		PORT map ( 	clk               => clk,
						reset_n                   => reset_n,                   
						---- Bridge Interface 
						bridge_acknowledge => acknowledge,
						bridge_irq         => irq,
						bridge_address     => address,
						bridge_bus_enable  => bus_enable,
						bridge_byte_enable => byte_enable,
						bridge_rw          => rw,
						bridge_write_data  => write_data,
						bridge_read_data   => read_data,
						---- RAM interface
						ram_address		=> ram_address_int,
						ram_data		   => ram_data_int,
						ram_wren		   => ram_wren_int,
						ram_q		      => ram_q_int
			);

u2: external_RAM 
		PORT map (
			address	=> ram_address_int,
			clock		=> clk,
			data		=> ram_data_int,
			wren		=> ram_wren_int,
			q		   => ram_q_int
		); 

END Bus_Arbiter_rtl;
