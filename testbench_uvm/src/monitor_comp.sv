class monitor_comp extends uvm_monitor;
`uvm_component_utils(monitor_comp);

	// members
	virtual interface_comp 			intf_h;
	uvm_get_port#(transaction_comp) model_get_port;
	//uvm_get_port#(transaction_comp) driver_get_port;
	int n_correct;
	int n_wrong;

	// constructor
	function new(string name, uvm_component parent);
		super.new(name, parent);
		n_correct = 0;
		n_wrong = 0;
	endfunction

	// build get ports
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		void'(uvm_resource_db#(virtual interface_comp)::read_by_name( .scope("ifs"), .name("interface_comp"), .val(intf_h) ));
		model_get_port = new(.name("model_get_port"), .parent(this));
		//driver_get_port = new(.name("driver_get_port"), .parent(this));
	endfunction

	// main monitor thread
	task run_phase(uvm_phase phase);

		transaction_comp txrx_model;
		//transaction_comp txrx_monitor;

		forever begin
			// driver_get_port.get(txrx_monitor)
			// get model result and compare to interface value
			model_get_port.get(txrx_model); 
			if (txrx_model.match_o != intf_h.match_o) begin
				n_wrong++;
				$display("Wrong @ %t --- Model: %d, Intf: %d", $time, txrx_model.match_o, intf_h.match_o);
			end
			else begin
				n_correct++;
			end
		end

	endtask

endclass
