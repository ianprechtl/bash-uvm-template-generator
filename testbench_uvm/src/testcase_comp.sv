class testcase_comp extends uvm_test;
`uvm_component_utils(testcase_comp);

	// members
	virtual interface_comp 	intf_h;
	environment_comp 			env_h;
	sequencer_comp 			seqr_h;
	configuration_comp 		config_h;

	// constructor
	function new(string name = "testcase_comp", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	// build
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env_h = environment_comp::type_id::create(.name("env_h"), .parent(this));
		config_h = configuration_comp::type_id::create(.name("config_h"), .parent(this));
	endfunction

	// sequencer extension
	function void end_of_elaboration_phase(uvm_phase phase);
		seqr_h = env_h.seqr_h;
	endfunction

	// run
	task run_phase(uvm_phase phase);
		// define environment input
		sequence_comp seq_h;
		seq_h = sequence_comp::type_id::create(.name("seq_h"), .contxt(get_full_name()));

		// begin test sequence
		phase.raise_objection(.obj(this));
		seq_h.start(seqr_h);
		phase.drop_objection(.obj(this));
	endtask

	// report
	function void report_phase(uvm_phase phase);
		$display("-------------------------------------------");
		$display("----------- Simulation Complete -----------");
		$display("-------------------------------------------");
		$display("Correct: %d",env_h.agent_h.monitor_h.n_correct);
		$display("Wrong:   %d",env_h.agent_h.monitor_h.n_wrong);
		$display("-------------------------------------------");
	endfunction

endclass
