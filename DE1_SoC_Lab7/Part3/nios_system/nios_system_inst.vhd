	component nios_system is
		port (
			clk_clk            : in  std_logic                    := 'X'; -- clk
			key_export_export  : in  std_logic                    := 'X'; -- export
			leds_export_export : out std_logic_vector(7 downto 0)         -- export
		);
	end component nios_system;

	u0 : component nios_system
		port map (
			clk_clk            => CONNECTED_TO_clk_clk,            --         clk.clk
			key_export_export  => CONNECTED_TO_key_export_export,  --  key_export.export
			leds_export_export => CONNECTED_TO_leds_export_export  -- leds_export.export
		);

