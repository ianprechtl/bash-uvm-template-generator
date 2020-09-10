class configuration_comp extends uvm_component;
`uvm_component_utils(configuration_comp);

	// members
	int  	fileID;
	string  config_path="../config/test.config";

	// constructor
	function new(string name, uvm_component parent);
		super.new(name, parent);

		// open config file
		fileID = $fopen(config_path, "r");
		if (fileID) begin
			// extract fields
			//if($fscanf(fileID, "0", iterations) != 1) $fatal("Error - parse");
		end
		//$display(">> Error: Could not open configuration file, defaulting");

		// register configurations
		//uvm_resource_db#(int)::set(.scope("ifs"), .name("iterations"), .val(iterations));

	endfunction

endclass
