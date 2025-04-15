
module nios_system (
	clk_clk,
	reset_reset_n,
	custom_ip_ext_addr,
	custom_ip_ext_data,
	custom_ip_invalid);	

	input		clk_clk;
	input		reset_reset_n;
	input	[2:0]	custom_ip_ext_addr;
	output	[31:0]	custom_ip_ext_data;
	input		custom_ip_invalid;
endmodule
