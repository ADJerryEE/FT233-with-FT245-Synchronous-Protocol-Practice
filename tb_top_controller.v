`timescale 1ns / 1ps



// Testbench for usbfifo_top
module tb_top_controller();

	// Stimulus Signals
	reg i_clk_60mhz, i_rst_n;
	reg i_rxf_l, i_txe_l;
	// reg [7:0] io_data_stimu;			// Stimulus FT233 Data
	wire [7:0] io_data_stimu;
	
	// Probed(output) Signals
	wire o_oe_l;
	wire o_rd_l;
	wire o_wr_l;

	wire [7:0] w_io_data_stimu = io_data_stimu;
    // wire [7:0] w_io_data_stimu;
	// Internal Wires
	
	
	
	
	
	
	
	// Tasks with array method
	/*
	reg [7:0] stimulus_bytes [0:7];
	integer idx;
	
	initial begin
		stimulus_bytes[0] = 8'hf0;
		
	end
	*/
	
	// Tasks method wo array	
	// Counter to generate stimulus bytes
	
	reg [9:0] byte_counter;
	reg counter_en;
	always@ (posedge i_clk_60mhz or negedge i_rst_n) begin
		if (!i_rst_n || byte_counter == 10'h3ff) byte_counter <= 10'h00;
		else if (!o_rd_l)						 byte_counter <= byte_counter + 1'b1;
	end
	
	// Feed Stimulus Signals during read operation when counter_en == 1'b1;
	// When coounter_en == 1'b0; it's under idle or write operation
	/* always@ (posedge i_clk_60mhz or negedge i_rst_n) begin
		// #5;
		if ()
			io_data_stimu <= counter_en ? byte_counter : 8'hzz;
	end
	*/
	assign io_data_stimu = (!o_oe_l) ? byte_counter : 8'hzz;
	// assign w_io_data_stimu = (!o_oe_l) ? io_data_stimu : 8'hzz;
	
	
	
	

/////////////////////////////////////////////////////////////////////////////////// Stimulus Signals Patterns //////////////////////////////////////////////////////////////////////////////////////////
	
	// Generate Clock Signal
	initial begin
		clk_ctrl(16);
		// 16 refers to 16ns. ~=60MHZ Clock
		// 10  refers to 10ns for a single period, f=100Mhz
		// 50  refers to 50ns, 20Mhz
		// 100 refers to 100ns, 1Mhz
		// unit 1ns
	end

	// Generate Reset Signal
	initial begin
		i_rst_n	= 1'bx;
		#33;
		reset_task(30); //reset 100ns;
	end

	// Scenarios
	initial begin
		
		
		// Initial Config with i_clk_60mhz, i_rst_n
		// This is to simulate the FPGA during power on
		i_rxf_l = 1'b1;	i_txe_l = 1'b1;
		#88ns;
		 
//////////////////////////////////////////////////////////////////////////////////// Initialization Completed ///////////////////////////////////////////////////////////////////////////////////////////
		
		// Secnario 1: Read Operation
		// i_rxf_l asserts and i_txe_l disasserts
		/*
		
		i_rxf_l = 1'b0;							// Start read operaiton
		@ (posedge i_clk_60mhz);				// Delay one clock cycle only with two @(posedge i_clk_60mhz);
		// #5;										// This delay is to avoid race condition on purpose. Line 104
		
		// Test to full flag
		
		wait_cycles (1024);
		wait_cycles (1);						// This delay is to meet protocol timing diagram.
		// wait_cycles (100);					// To test when room of fifo is full, while i_rxf_l is still driven low
		#5;
		i_rxf_l = 1'b1;							// End of read operation
		
		
		// Test for FT233 disasserts i_rxf_l while the fifo isn't full.
		/*
		wait_cycles (20);
		#5;
		i_rxf_l = 1'b1;							// End of read operation
		*/
		
		// Secnario 2: Write Operation
		// i_rxf_l disasserts and i_txe_l asserts
		
		// Test to empty flag
		/*
		wait_cycles (5);						// Delay two clock cycles on purpose
		#5;
		i_txe_l = 1'b0;							// Start Write operaiton
		
		wait_cycles (1024);						// usbfifo_sync send data out to usbfifo_top through usbfifo_tx
		wait_cycles (1);
		// i_txe_l = 1'b0;						// To test when room of fifo is empty, while i_txe_l is still driven low
		// wait_cycles (100);					// Last another 100 cycles for driving i_txe_l low
		#5;
		i_txe_l = 1'b1;
		*/
		
		/*
		wait_cycles (1);						// This delay is to meet protocol timing diagram.
		#5;
		
		wait_cycles (20);						// On purpose delays to see how o_wr_l works
		i_txe_l = 1'b1;							// End of Write operation
		*/
		
		/*
		// just test FSM of usbfifo_tx
		wait_cycles (5);
		i_rxf_l = 1'b0;	
		*/
		
		// Test for FT233 disasserts i_txe_l while the fifo isn't empty.
		/*
		wait_cycles (5);						// Delay 4-5 clocks cycles on purpose						
		#5;
		i_txe_l = 1'b0;
		
		wait_cycles (10);						
		#5;
		i_txe_l = 1'b1;							// End of Write operation
		*/
		
		
		
		// Secnario 3: Interlock Operation (Priority Definition)
		// i_rxf_l and i_txe_l both assert (Verify priority/ interlock design)
		
		
		i_rxf_l = 1'b0;	i_txe_l = 1'b0;			// FT233 asserts read and write operation simultaneously.
		wait_cycles (20);						// Last 8 cycles on purpose	
		#5;
		i_rxf_l = 1'b1;
		
		
		
		// i_rxf_l asserts first and i_txe_l asserts (Verify priority/ interlock design)
		/*
		i_rxf_l = 1'b0;
		wait_cycles (8);						// Last 8 cycles on purpose
		i_txe_l = 1'b0;
		
		wait_cycles (6);
		i_txe_l = 1'b1;
		*/
		

		// i_txe_l asserts first, then i_rxf_l asserts (Verify priority/ interlock design)
		/*
		wait_cycles (6);
		i_txe_l = 1'b0; 
		wait_cycles (5);						// Last 8 cycles on purpose
		i_rxf_l = 1'b0;
		
		wait_cycles (20);
		i_rxf_l = 1'b1;
		*/
		
		
		
		// Secnario 4: IDLE
		// i_rxf_l and i_txe_l both disasserts
		// i_rxf_l = 1'b1; i_txe_l = 1'b1;
		
		
	end


//////////////////////////////////////////////////////////////////////////////// Devices Under Test /////////////////////////////////////////////////////////////////////////////////////////////////////
	usbfifo_top DUT(
	
		// INPUT 
		.i_clk_60mhz(i_clk_60mhz),			// FT233 CLKOUT 60MHZ
		.i_rst_n(i_rst_n),					// System reset
		.i_rxf_l(i_rxf_l),					// RXF# from FT233 to enable read operation
		.i_txe_l(i_txe_l),					// TXE# from FT233 to enable write operation
	
	
		// OUTPUT 
		.o_oe_l(o_oe_l),					// Ack FT233 to be ready for read
		.o_rd_l(o_rd_l),					// Ack FT233 to be ready for read
		.o_wr_l(o_wr_l),					// Ack FT233 to be ready for write
		// output wire o_simu_l,			// SIMU_L#

	// INOUT
	// .io_data(io_data)					// FIFO data in parallel to FT233
	.io_data(w_io_data_stimu)				// Test usbfifo_rx only.
);

//////////////////////////////////////////////////////////////////////////////// Clk and Task Group //////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// System Clock Task
	task clk_ctrl;
		// parameter PERIOD = 10; //10ns fpr one clock period
		input[15:0] i_clk_60mhz_period;
		// input wire [15:0] i_clk_60mhz_period;
		// reg [15:0] i_clk_60mhz_period;
		begin
			i_clk_60mhz = 1'b0; 
			#20;
			forever begin
				i_clk_60mhz = ~i_clk_60mhz; #(i_clk_60mhz_period/2);
			end
		end
	endtask

	// System Reset Task
	task reset_task;
		input [15:0] reset_time;
		begin
			i_rst_n = 1'b0;
			# reset_time;
		
			i_rst_n = 1'b1;
		end
	endtask


//////////////////////////////////////////////////////////////////////////////// Stimulus Task Group //////////////////////////////////////////////////////////////////////////////////////////////////////

	// Stimulus to verify usbfifo_rx
	// Wait N*clock cycles
	task wait_cycles;
	input integer n;
	integer k;
		begin
			for (k=0; k<n; k=k+1) @(posedge i_clk_60mhz);	// input how many clock cycles need
		end
	endtask

	// Generate Stimulus Data with Edge of i_clk_60mhz
	/*
	task stimulus_bytes; 
		input [7:0] value;
		begin
			@(posedge i_clk_60mhz);		// When clk rising edge comes
			#5;							// delay 5ns to aviod race condition
			io_data_stimu = value;		// Stimulus signals update
		end
	endtask
	
	
	// Release the bus and go back to high-z
	task release_highz;
		begin
			@(posedge i_clk_60mhz);	
			#5;
			io_data_stimu = 8'hzz;	
		end
	endtask
*/


//////////////////////////////////////////////////////////////////////////////// Common Task Group //////////////////////////////////////////////////////////////////////////////////////////////////////
//	Only System Verilog complier can support nested module
//	print module
/*

	module print_task();
		task warning;
			input wire [30*8:1] msg_warn;
			input wire en;
			begin
				if(~en)
				begin
					$write("The time value is at %t ns\n", $time);
					$write("The value is at %s\n",msg_warn);
					// $write("The the value is !!! at %t",$time);
				end
			end
		endtask
	
	task error;
		input wire [80*8:1] msg_error;
		begin
			$display("Please show error\n");
			$display("Please show %s\n", msg_error);
		end
	endtask
	
	task sim_complete;
		begin
			$display("The simulation is complete !\n");
		end
	endtask
	
	task state_machice_status;
		input wire [80*8:1] msg_sms; //sms refers to state machine status
		begin
			$display("The current state machine is %s\n", msg_sms);
		end
	endtask
	endmodule : print_task

*/



//////////////////////////////////////////////////////////////////////////////// Call Module for tasks ///////////////////////////////////////////////////////////////////////////////////////////////////
// print_task print();




endmodule
