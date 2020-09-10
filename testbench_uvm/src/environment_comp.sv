class environment_comp extends uvm_env;
`uvm_component_utils(environment_comp);

	// members
	agent_comp 		agent_h;
	sequencer_comp 	seqr_h;

	// constructor
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	// build agent and sequencer
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		agent_h = agent_comp::type_id::create(.name("agent_h"), .parent(this)); 
		seqr_h 	= sequencer_comp::type_id::create(.name("seqr_h"), .parent(this));
	endfunction

	// connect sequencer to driver (in environment)
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		agent_h.driver_h.seq_item_port.connect(seqr_h.seq_item_export);
	endfunction

endclass
