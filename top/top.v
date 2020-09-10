`ifndef _TOP_V_
`define _TOP_V_

`include "top.h"

module top(
	input 	[`TOP_BW-1:0]	opA_i,
	input 	[`TOP_BW-1:0]	opB_i,
	output 					match_o
);

identity_comparator #(
	.BW(`TOP_BW)
) top_inst (.*);

endmodule

`endif // _TOP_V_