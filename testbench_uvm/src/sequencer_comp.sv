class transaction_comp extends uvm_sequence_item;
`uvm_object_utils(transaction_comp);

	// interface inclusive members
	logic 					resetn;
	logic 	[`TOP_BW-1:0]	opA_i;
	logic 	[`TOP_BW-1:0]	opB_i;
	logic 					match_o;

	// constructor
	function new(string name = "");
		super.new(name);
	endfunction

	// misc. methods
	function void do_copy(uvm_object rhs);
		// create copy 
		transaction_comp temp_copy;
		super.do_copy(rhs);
		$cast(temp_copy,rhs);
		// assign to copy
		this.resetn = temp_copy.resetn;
		this.opA_i = temp_copy.opA_i;
		this.opB_i = temp_copy.opB_i;
	endfunction

	task do_reset;
		resetn = 1'b0;
	endtask

	task do_randomize;
		resetn = 1'b1;
		opA_i = $urandom();
		opB_i = $urandom();
	endtask;

endclass

class sequence_comp extends uvm_sequence#(transaction_comp);
`uvm_object_utils(sequence_comp);

	// members

	// constructor
	function new(string name = "");
		super.new(name);
	endfunction

	// main sequence method
	task body();

		// create sequence item
		transaction_comp txrx_temp;
		txrx_temp = transaction_comp::type_id::create(.name("txrx_temp"), .contxt(get_full_name()));

		// sequence
		// -------------------------------------

		// reset
		
		start_item(txrx_temp);
		txrx_temp.do_reset();
		finish_item(txrx_temp);

		// active
		repeat(1000) begin
		start_item(txrx_temp);
		txrx_temp.do_randomize();
		finish_item(txrx_temp);
		end

	endtask

	// misc. methods

endclass

// typedef to make calling the sequencer syntactically easier 
typedef uvm_sequencer#(transaction_comp) sequencer_comp;
