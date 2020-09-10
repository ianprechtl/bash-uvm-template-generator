`include "../include/testbench.h"
`include "uvm_macros.svh"

module testbench;

	// package imports
	import uvm_pkg::*;
	import package_comp::*;

	// interface declaration
	interface_comp intf();

	// clock generation
	initial begin
		intf.clock = 1'b0;
		forever begin
			#10 intf.clock = ~intf.clock;
		end
	end

	// hardware-under-test
	top dut(
		.opA_i(intf.opA_i),
		.opB_i(intf.opB_i),
		.match_o(intf.match_o)
	);

	// testcase
	initial begin

		// register interface with factory
		uvm_resource_db #(virtual interface_comp)::set(.scope("ifs"),.name("interface_comp"),.val(intf));
		
		// execute testcase
		run_test("testcase_comp");
	end

endmodule