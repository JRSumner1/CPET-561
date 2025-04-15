
module nios_system (
	clk_clk,
	leds_export,
	reset_reset_n,
	switches_export,
	pushbuttons_export,
	hex0_export);	

	input		clk_clk;
	output	[7:0]	leds_export;
	input		reset_reset_n;
	input	[7:0]	switches_export;
	input	[3:0]	pushbuttons_export;
	output	[6:0]	hex0_export;
endmodule
