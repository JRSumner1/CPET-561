-------------------------------------------------------------------------
-- Holly Dickens 
-- 01/31/2021
-- Lab 1 part 1 sample code 
-- Drives LED0 from counter bit 25 (blinks) 
-- Other LEDs configured from hardcoded values
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

ENTITY lightsNoNios is
  port (
    CLOCK_50 : in  std_logic;
    KEY      : in  std_logic_vector(3 downto 0);
    LEDR     : out std_logic_vector(9 downto 0)
   );
end entity lightsNoNios;

architecture lights_arch of lightsNoNios is
  -- signal declarations
  signal led0    : std_logic;
  signal cntr    : std_logic_vector(25 downto 0);
  signal ledNios : std_logic_vector(4 downto 0);
  signal reset_n : std_logic;
  signal key0_d1 : std_logic;
  signal key0_d2 : std_logic;
  signal key0_d3 : std_logic;
  signal sw_d1   : std_logic_vector(9 downto 0);
  signal sw_d2   : std_logic_vector(9 downto 0);
  
begin

  -- Drive LED outputs
  LEDR(9 downto 5) <= ledNios;
  LEDR(4 downto 0) <= x"F" & led0;
  led0             <= cntr(25);
  ledNios          <= "10101";
  
  ----- Synchronize the PBs and create reset 
  synchReset_proc : process (CLOCK_50) begin
    if (rising_edge(CLOCK_50)) then
      key0_d1 <= KEY(0);
      key0_d2 <= key0_d1;
      key0_d3 <= key0_d2;
    end if;
  end process synchReset_proc;
  reset_n <= key0_d3;
  
  ----- Create synchronous counter to drive output LED
  syncCntr_proc : process (CLOCK_50) begin
    if (rising_edge(CLOCK_50)) then
      if (reset_n = '0') then
        cntr <= "00" & x"000000";
      else
        cntr <= cntr + ("00" & x"000001");
      end if;
    end if;
  end process syncCntr_proc;
    
end architecture lights_arch;