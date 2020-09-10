#!/bin/bash

# paths
TOP_DIR="../top"
TOP_PATH=$TOP_DIR/top.v

# get script arguments
# ---------------------------------------------------------------------------------------------
OPTS=""
while getopts "hi:" opt; do	
  case ${opt} in
    i)	OPTS=$OPTARG
      	;;

	h|\?)	echo "Usage:"
		echo " 	-h: Show this menu"
		echo "	-i: module name to generate"
		exit
      	;;
  esac
done

if [ "$OPTS" == "" ]; then 
	echo "Error: need to specify script argument"
	exit 
fi

# remove existing folders
find -mindepth 1 -maxdepth 1 -type d -exec rm -r {} \;

# create folders
mkdir src include config cpp project
mkdir cpp/src cpp/include cpp/lib
mkdir project/log

# copy in necessary files
cp /home/ian/Documents/research/hardware/tools/sim.sh project

# create template source files
# ---------------------------------------------------------------------------------------------

# package
# ------------------------------------------------------
printf \
'package package_'$OPTS';
	`include "uvm_macros.svh"
	import  uvm_pkg::*;
	`include "configuration_'$OPTS'.sv"
	`include "sequencer_'$OPTS'.sv"	
	`include "driver_'$OPTS'.sv"
	`include "monitor_'$OPTS'.sv"
	`include "model_'$OPTS'.sv"
	`include "agent_'$OPTS'.sv"
	`include "environment_'$OPTS'.sv"
	`include "testcase_'$OPTS'.sv"
endpackage' \
> src/package_$OPTS.sv

# configuration file
# ------------------------------------------------------
printf \
'class configuration_'$OPTS' extends uvm_component;
`uvm_component_utils(configuration_'$OPTS');

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
			//if($fscanf(fileID, "%d", iterations) != 1) $fatal("Error - parse");
		end
		//$display(">> Error: Could not open configuration file, defaulting");

		// register configurations
		//uvm_resource_db#(int)::set(.scope("ifs"), .name("iterations"), .val(iterations));

	endfunction

endclass
'\
> src/configuration_$OPTS.sv

# interface
# ------------------------------------------------------
# populate interface for ports of the top level design module

printf \
'import package_'$OPTS'::*; 	// for set method

interface interface_'$OPTS';\n' > src/interface_$OPTS.sv

# loop through source file
declare -a port_name_arr 		# array to store port names
DUT_PORTS=""
INTERFACE_PORTS=""
TRANSACTION_PORTS=""

while IFS= read -r line
do
	# if port then parse down to signals
	if [[ $line =~ (input|output)(.*)(,|) ]]; then	
		DB_NAMES="${BASH_REMATCH[2]}"
		DB_NAMES=${DB_NAMES%,*}; 		# remove trailig comma if it exists
		INTERFACE_PORTS=$INTERFACE_PORTS'\tvar logic'$DB_NAMES';\n'
		TRANSACTION_PORTS=$TRANSACTION_PORTS'\tlogic'$DB_NAMES';\n'

		# get port info
		TEMP=`echo $DB_NAMES | awk '{printf $NF}'`
		DUT_PORTS=$DUT_PORTS"\t\t."$TEMP"(intf.$TEMP),""\n"
		port_name_arr+=("$TEMP")
	fi
done < "$TOP_PATH"

# continue printing interface module
printf "$INTERFACE_PORTS" >> src/interface_$OPTS.sv

printf \
'
	// methods
	task reset();
	endtask

	task set(transaction_'$OPTS' txrx_inst);
	endtask
'\
>> src/interface_$OPTS.sv

printf 'endinterface' >> src/interface_$OPTS.sv

# testbench header
# ------------------------------------------------------
printf \
'`ifndef _TESTBENCH_H_
`define _TESTBENCH_H_

// top level
`include "../../top/top.h"

// package and interface
`include "../src/package_'$OPTS'.sv"
`include "../src/interface_'$OPTS'.sv"

`endif
' \
> include/testbench.h


# testbench
# ------------------------------------------------------
printf \
'`include "../include/testbench.h"
`include "uvm_macros.svh"

module testbench;

	// package imports
	import uvm_pkg::*;
	import package_'$OPTS'::*;

	// interface declaration
	interface_'$OPTS' intf();

	// clock generation
	initial begin
		intf.clock = 1'"'"'b0;
		forever begin
			#10 intf.clock = ~intf.clock;
		end
	end

	// hardware-under-test
	top dut(
' \
> src/testbench.sv

DUT_PORTS=${DUT_PORTS%,*}; 		# remove trailig comma if it exists
printf "$DUT_PORTS\n" >> src/testbench.sv

printf \
'	);

	// testcase
	initial begin

		// register interface with factory
		uvm_resource_db #(virtual interface_'$OPTS')::set(.scope("ifs"),.name("interface_'$OPTS'"),.val(intf));
		
		// execute testcase
		run_test("testcase_'$OPTS'");
	end

endmodule' \
>> src/testbench.sv

# testcase
# ------------------------------------------------------
printf \
'class testcase_'$OPTS' extends uvm_test;
`uvm_component_utils(testcase_'$OPTS');

	// members
	virtual interface_'$OPTS' 	intf_h;
	environment_'$OPTS' 			env_h;
	sequencer_'$OPTS' 			seqr_h;
	configuration_'$OPTS' 		config_h;

	// constructor
	function new(string name = "testcase_'$OPTS'", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	// build
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env_h = environment_'$OPTS'::type_id::create(.name("env_h"), .parent(this));
		config_h = configuration_'$OPTS'::type_id::create(.name("config_h"), .parent(this));
	endfunction

	// sequencer extension
	function void end_of_elaboration_phase(uvm_phase phase);
		seqr_h = env_h.seqr_h;
	endfunction

	// run
	task run_phase(uvm_phase phase);
		// define environment input
		sequence_'$OPTS' seq_h;
		seq_h = sequence_'$OPTS'::type_id::create(.name("seq_h"), .contxt(get_full_name()));

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
		$display("Correct: %%d",env_h.agent_h.monitor_h.n_correct);
		$display("Wrong:   %%d",env_h.agent_h.monitor_h.n_wrong);
		$display("-------------------------------------------");
	endfunction

endclass
' \
> src/testcase_$OPTS.sv

# environment
# ------------------------------------------------------
printf \
'class environment_'$OPTS' extends uvm_env;
`uvm_component_utils(environment_'$OPTS');

	// members
	agent_'$OPTS' 		agent_h;
	sequencer_'$OPTS' 	seqr_h;

	// constructor
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	// build agent and sequencer
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		agent_h = agent_'$OPTS'::type_id::create(.name("agent_h"), .parent(this)); 
		seqr_h 	= sequencer_'$OPTS'::type_id::create(.name("seqr_h"), .parent(this));
	endfunction

	// connect sequencer to driver (in environment)
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		agent_h.driver_h.seq_item_port.connect(seqr_h.seq_item_export);
	endfunction

endclass
' \
> src/environment_$OPTS.sv

# sequencer
# ------------------------------------------------------
printf \
'class transaction_'$OPTS' extends uvm_sequence_item;
`uvm_object_utils(transaction_'$OPTS');

	// interface inclusive members
'\
> src/sequencer_$OPTS.sv

# print core transaction signals
printf "$TRANSACTION_PORTS\n" >> src/sequencer_$OPTS.sv

printf \
'	// constructor
	function new(string name = "");
		super.new(name);
	endfunction

	// misc. methods
	function void do_copy(uvm_object rhs);
		// create copy 
		transaction_'$OPTS' temp_copy;
		super.do_copy(rhs);
		$cast(temp_copy,rhs);
		// assign to copy
'\
>> src/sequencer_$OPTS.sv

# print copy methods
for i in "${!port_name_arr[@]}"; do
	printf '\t\tthis.'"${port_name_arr[i]}"' = temp_copy.'${port_name_arr[i]}';\n' >> src/sequencer_$OPTS.sv
done

printf \
'	endfunction

	task do_reset;
	endtask

	task do_randomize;
	endtask;

endclass

class sequence_'$OPTS' extends uvm_sequence#(transaction_'$OPTS');
`uvm_object_utils(sequence_'$OPTS');

	// members

	// constructor
	function new(string name = "");
		super.new(name);
	endfunction

	// main sequence method
	task body();

		// create sequence item
		transaction_'$OPTS' txrx_temp;
		txrx_temp = transaction_'$OPTS'::type_id::create(.name("txrx_temp"), .contxt(get_full_name()));

		// sequence
		// -------------------------------------

		// reset
		/*
		start_item(txrx_temp);
		txrx_temp.do_reset();
		finish_item(txrx_temp);

		// active
		start_item(txrx_temp);
		txrx_temp.do_randomize();
		finish_item(txrx_temp);
		*/

	endtask

	// misc. methods

endclass

// typedef to make calling the sequencer syntactically easier 
typedef uvm_sequencer#(transaction_'$OPTS') sequencer_'$OPTS';
' \
>> src/sequencer_$OPTS.sv

# agent
# ------------------------------------------------------
printf \
'class agent_'$OPTS' extends uvm_agent;
`uvm_component_utils(agent_'$OPTS');

	// members
	driver_'$OPTS' 						driver_h;
	monitor_'$OPTS' 						monitor_h;
	model_'$OPTS' 						model_h;
	uvm_tlm_fifo #(transaction_'$OPTS') 	driver2model_fifo; 		// input
	uvm_tlm_fifo #(transaction_'$OPTS') 	model2monitor_fifo; 	// output
	//uvm_tlm_fifo #(transaction_'$OPTS') 	driver2monitor_fifo; 	// control (reset, etc.)

	// constructor
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	// build components
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		// driver, monitor, model
		driver_h 	= driver_'$OPTS'::type_id::create(.name("driver_h"), .parent(this));
		monitor_h 	= monitor_'$OPTS'::type_id::create(.name("monitor_h"), .parent(this));
		model_h 	= model_'$OPTS'::type_id::create(.name("model_h"), .parent(this));

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
' \
> src/agent_$OPTS.sv


# driver
# ------------------------------------------------------
printf \
'class driver_'$OPTS' extends uvm_driver#(transaction_'$OPTS');
`uvm_component_utils(driver_'$OPTS');

	// members
	virtual interface_'$OPTS' 			intf_h;
	uvm_put_port #(transaction_'$OPTS') 	model_put_port;
	//uvm_put_port #(transaction_'$OPTS') 	monitor_put_port;

	// constructor
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	// build drive ports
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		void'"'"'(uvm_resource_db#(virtual interface_'$OPTS')::read_by_name( .scope("ifs"), .name("interface_'$OPTS'"), .val(intf_h) ));
		model_put_port 		= new(.name("model_put_port"), .parent(this));
		//monitor_put_port 	= new(.name("monitor_put_port"), .parent(this));
	endfunction

	// driver run thread
	task run_phase(uvm_phase phase);

		transaction_'$OPTS' txrx_temp;

		forever begin
			// get next sequence item
			seq_item_port.get_next_item(txrx_temp);

			// drive submodules
			drive(txrx_temp);

			// unblock item
			seq_item_port.item_done();
		end

	endtask

	// misc. methods
	task drive(transaction_'$OPTS' txrx_inst);

		// create copy and add to fifo
		transaction_'$OPTS' txrx_copy = new();
		txrx_copy.do_copy(txrx_inst);
		model_put_port.put(txrx_copy);
		//monitor_put_port.put(txrx_copy);

		// do stuff to interface
		if (!txrx_inst.resetn) 	intf_h.reset();
		else 					intf_h.set(txrx_inst);

	endtask

endclass
' \
> src/driver_$OPTS.sv

# monitor
# ------------------------------------------------------
printf \
'class monitor_'$OPTS' extends uvm_monitor;
`uvm_component_utils(monitor_'$OPTS');

	// members
	virtual interface_'$OPTS' 			intf_h;
	uvm_get_port#(transaction_'$OPTS') model_get_port;
	//uvm_get_port#(transaction_'$OPTS') driver_get_port;
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
		void'"'"'(uvm_resource_db#(virtual interface_'$OPTS')::read_by_name( .scope("ifs"), .name("interface_'$OPTS'"), .val(intf_h) ));
		model_get_port = new(.name("model_get_port"), .parent(this));
		//driver_get_port = new(.name("driver_get_port"), .parent(this));
	endfunction

	// main monitor thread
	task run_phase(uvm_phase phase);

		transaction_'$OPTS' txrx_model;
		//transaction_'$OPTS' txrx_monitor;

		/*forever begin
			// driver_get_port.get(txrx_monitor)
			// get model result and compare to interface value
			model_get_port.get(txrx_model); 
			if (txrx_model.match != intf_h.match_o) begin
				n_wrong++;
				$display("Wrong @ %%t --- Model: %%d, Intf: %%d", $time, txrx_model.match, intf_h.match_o);
			end
			else begin
				n_correct++;
			end
		//end*/

	endtask

endclass
' \
> src/monitor_$OPTS.sv

# model
# ------------------------------------------------------
printf \
'//import "DPI-C" function chandle pGetModelHandle();
//import "DPI-C" function int 	getModelResult(chandle, int, int);

class model_'$OPTS' extends uvm_component;
`uvm_component_utils(model_'$OPTS');

	// members
	chandle  							pHandle;
	uvm_get_port#(transaction_'$OPTS') 	driver_get_port;
	uvm_put_port#(transaction_'$OPTS') 	monitor_put_port;

	// constructor
	function new(string name, uvm_component parent);
		super.new(name, parent);
		// get model handle
		// pHandle = pGetModelHandle();
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
		transaction_'$OPTS' txrx_temp;
		txrx_temp = transaction_'$OPTS'::type_id::create(.name("txrx_temp"), .contxt(get_full_name()));

		// main thread
		forever begin

			// get input 
			driver_get_port.get(txrx_temp);

			// process and modify transaction packet
			// xxx = getModelResult(aaa,bbb,ccc);

			// put output
			monitor_put_port.put(txrx_temp);

		end

	endtask

endclass
' \
> src/model_$OPTS.sv