class agent_comp extends uvm_agent;
`uvm_component_utils(agent_comp);

	// members
	driver_comp 						driver_h;
	monitor_comp 						monitor_h;
	model_comp 						model_h;
	uvm_tlm_fifo #(transaction_comp) 	driver2model_fifo; 		// input
	uvm_tlm_fifo #(transaction_comp) 	model2monitor_fifo; 	// output
	//uvm_tlm_fifo #(transaction_comp) 	driver2monitor_fifo; 	// control (reset, etc.)

	// constructor
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	// build components
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		// driver, monitor, model
		driver_h 	= driver_comp::type_id::create(.name("driver_h"), .parent(this));
		monitor_h 	= monitor_comp::type_id::create(.name("monitor_h"), .parent(this));
		model_h 	= model_comp::type_id::create(.name("model_h"), .parent(this));

		// transaction/data fifos
		driver2model_fifo = new(.name("driver2model_fifo"), .parent(this), .size(1));
		model2monitor_fifo = new(.name("model2monitor_fifo"), .parent(this), .size(1));
		//driver2monitor_fifo = new(.name("driver2monitor_fifo"), .parent(this), .size(1));

	endfunction

	// connect 
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);

		// driver to model ports
		driver_h.model_put_port.connect(driver2model_fifo.put_export);
		model_h.driver_get_port.connect(driver2model_fifo.get_export);

		// model to monitor ports
		model_h.monitor_put_port.connect(model2monitor_fifo.put_export);
		monitor_h.model_get_port.connect(model2monitor_fifo.get_export);

		// driver to monitor ports
		//driver_h.monitor_put_port.connect(driver2monitor_fifo.put_export);
		//monitor_h.driver_get_port.connect(driver2monitor_fifo.get_export);

	endfunction

	// run phase (empty)
	task run_phase(uvm_phase phase);
	endtask

endclass
