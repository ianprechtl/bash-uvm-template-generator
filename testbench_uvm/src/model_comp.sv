import "DPI-C" function chandle pGetModelHandle();
import "DPI-C" function int 	getModelResult(chandle, int, int);

class model_comp extends uvm_component;
`uvm_component_utils(model_comp);

	// members
	chandle  							pHandle;
	uvm_get_port#(transaction_comp) 	driver_get_port;
	uvm_put_port#(transaction_comp) 	monitor_put_port;

	// constructor
	function new(string name, uvm_component parent);
		super.new(name, parent);
		// get model handle
		pHandle = pGetModelHandle();
	endfunction

	// build ports
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		driver_get_port = new(.name("driver_get_port"), .parent(this));
		monitor_put_port = new(.name("monitor_put_port"), .parent(this));
	endfunction

	// generic connect
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
	endfunction

	// main model thread
	task run_phase(uvm_phase phase);

		// thread memories
		transaction_comp txrx_temp;
		txrx_temp = transaction_comp::type_id::create(.name("txrx_temp"), .contxt(get_full_name()));

		// main thread
		forever begin

			// get input 
			driver_get_port.get(txrx_temp);

			// process and modify transaction packet
			if (txrx_temp.resetn) begin
				txrx_temp.match_o = getModelResult(pHandle,txrx_temp.opA_i,txrx_temp.opB_i);

				// put output
				monitor_put_port.put(txrx_temp);
			end

		end

	endtask

endclass
