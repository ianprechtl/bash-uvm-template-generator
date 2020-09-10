import package_comp::*; 	// for set method

interface interface_comp;
	var logic 					clock;
	var logic 					resetn;
	var logic 	[`TOP_BW-1:0]	opA_i;
	var logic 	[`TOP_BW-1:0]	opB_i;
	var logic 					match_o;

	// methods
	task reset();
		resetn = 1'b0;
	endtask

	task set(transaction_comp txrx_inst);
		resetn = txrx_inst.resetn;
		opA_i = txrx_inst.opA_i;
		opB_i = txrx_inst.opB_i;
	endtask
endinterface