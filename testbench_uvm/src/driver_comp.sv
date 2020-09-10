class driver_comp extends uvm_driver#(transaction_comp);
`uvm_component_utils(driver_comp);

	// members
	virtual interface_comp 			intf_h;
	uvm_put_port #(transaction_comp) 	model_put_port;
	//uvm_put_port #(transaction_comp) 	monitor_put_port;

	// constructor
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	// build drive ports
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		void'(uvm_resource_db#(virtual interface_comp)::read_by_name( .scope("ifs"), .name("interface_comp"), .val(intf_h) ));
		model_put_port 		= new(.name("model_put_port"), .parent(this));
		//monitor_put_port 	= new(.name("monitor_put_port"), .parent(this));
	endfunction

	// driver run thread
	task run_phase(uvm_phase phase);

		transaction_comp txrx_temp;

		forever begin
			@(posedge intf_h.clock);

			// get next sequence item
			seq_item_port.get_next_item(txrx_temp);

			// drive submodules
			drive(txrx_temp);

			// unblock item
			seq_item_port.item_done();
		end

	endtask

	// misc. methods
	task drive(transaction_comp txrx_inst);

		// create copy and add to fifo
		transaction_comp txrx_copy = new();
		txrx_copy.do_copy(txrx_inst);
		model_put_port.put(txrx_copy);
		//monitor_put_port.put(txrx_copy);

		// do stuff to interface
		if (!txrx_inst.resetn) 	intf_h.reset();
		else 					intf_h.set(txrx_inst);

	endtask

endclass
