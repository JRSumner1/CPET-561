library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TimeQuest_Demo is
    port (
        clk    : in  std_logic;
        A      : in  std_logic_vector(15 downto 0);
        B      : in  std_logic_vector(15 downto 0);
        Result : out std_logic_vector(15 downto 0)
    );
end TimeQuest_Demo;

architecture Behavioral of TimeQuest_Demo is

    -- Internal 16-bit registers for A, B, and the result
    signal regA      : std_logic_vector(15 downto 0);
    signal regB      : std_logic_vector(15 downto 0);
    signal sum_comb  : std_logic_vector(15 downto 0);
    signal regResult : std_logic_vector(15 downto 0);

begin

    ------------------------------------------------------------------------
    -- 1) Register A on the rising edge of clk
    ------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            regA <= A;
        end if;
    end process;

    ------------------------------------------------------------------------
    -- 2) Register B on the rising edge of clk
    ------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            regB <= B;
        end if;
    end process;

    ------------------------------------------------------------------------
    -- 3) Combinational adder (outputs the sum of regA and regB each cycle)
    ------------------------------------------------------------------------
    sum_comb <= std_logic_vector(unsigned(regA) + unsigned(regB));

    ------------------------------------------------------------------------
    -- 4) Register the sum into regResult on the rising edge of clk
    ------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            regResult <= sum_comb;
        end if;
    end process;

    ------------------------------------------------------------------------
    -- 5) Drive the external output from the result register
    ------------------------------------------------------------------------
    Result <= regResult;

end Behavioral;
