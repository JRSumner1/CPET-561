
module nios_system (
	clk_clk,
	hex0_export,
	reset_reset_n,
	switches_export,
	buttons_export);	

	input		clk_clk;
	output	[7:0]	hex0_export;
	input		reset_reset_n;
	input	[7:0]	switches_export;
	input	[3:0]	buttons_export;
endmodule
