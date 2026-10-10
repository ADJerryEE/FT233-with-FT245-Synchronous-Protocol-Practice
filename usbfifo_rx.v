// MODULE NAME: usbfifo_rx
// Ver_00
// Author: Jerry Cheng

// Modify_10092026
/*
	1. Remove Line 59 to 74 (compared to-1008_v00)
	2. Remove output reg [7:0] o_rx_data and output reg o_data_valid
	3. Revise state and nt_state bit width into 3'h from 4'h. This is to optimize registers
	
*/



module usbfifo_rx(
	
	// INPUT 
	input  wire i_clk_60mhz,				// FT233 CLKOUT 60MHZ
	input  wire i_rst_n,					// System reset
	input  wire i_rxf_l,					// Read request from FT233. Active low. 
	input  wire [7:0] i_rx_data,			// Data bus from FT233
	
	input  wire i_tx_active,				// High refers to usbfifo_tx owns the bus, High active.
	input  wire i_full,						// full flag of usbfifo_sync
	
	// OUTPUT
	output reg o_oe_l,						// FPGA asserts o_oe_l to change direction of io_data (FT233 --> FPGA). Active low.
	output reg o_rd_l,						// Ack FT233 to be ready for read operation
	
	output wire [7:0] o_rx_data,			// Data to internal fifo memory
	
	output wire o_data_valid,				// Flag of data valid to usbfifo_sync. High active. When it's high, fifo memory could start sampled data.
	output wire o_rx_active					// To usbfifo_tx. High refers to usbfifo_rx is busy; used for read/write bus arbitration
											// Interlock design
	
);


	// STATES DECLARATION
	// Condiser to remove 3'h0, 3'h4 and 3'h5 states
	localparam RX_IDLE				= 3'h0;				// IDLE
	localparam RX_DETE_RXF_N		= 3'h1;				// Detect (!i_rxf_l)
	localparam RX_DATA_PRE_OE_N 	= 3'h2;				// Assert o_oe_l low so that fifo data of FT233 cuold be turn-around
	localparam RX_DATA_PRE_RD_N		= 3'h3;				// Assert RD to tell FT233 that read operation is ready
	localparam RX_RLS_DATA_RD_OE_N 	= 3'h4;				// Release o_rd_l and o_oe_l to end the read communication
	localparam RX_WAIT				= 3'h5;				// Wait one clock cycle on purpose 
	
		
	// This register is to use to meet protocol by delaying one clock of i_rxf_l
	reg r_rxf_n;
	always@ (posedge i_clk_60mhz or negedge i_rst_n) begin
		if(!i_rst_n) r_rxf_n <= 1'b1;
		else 		 r_rxf_n <= i_rxf_l;
	end
	
	
	// Main State Machine
	reg [2:0] st_state, nt_state;
	always@ (posedge i_clk_60mhz or negedge i_rst_n) begin
		if(!i_rst_n) st_state <= 3'h0;
		else 		 st_state <= nt_state;
	end

	
	// o_rx_active is a flag which indicates usbfifo_rx is busy
	// (st_state == RX_DETE_RXF_N && !i_rxf_l) --> Very tight timing. This is to assert before state enters into RX_DATA_PRE_OE_N.
	assign o_rx_active = (st_state == RX_DATA_PRE_OE_N)	   || (st_state == RX_DATA_PRE_RD_N) ||
						 (st_state == RX_RLS_DATA_RD_OE_N) || (st_state == RX_WAIT) || (st_state == RX_DETE_RXF_N && !i_rxf_l);
	
	
	// Flag of Data Vaild
	wire valid_trigger = (st_state == RX_DATA_PRE_RD_N && !i_rxf_l && !i_full);     // st_state = RD_DATA_PRE_RD_N, i_rxf_l == 1'b0;, fifo isn't full.

	
	// Combinational Inputs
	always@ (*) begin
		nt_state = 3'h0;
		
		case(st_state)
			RX_IDLE: nt_state = RX_DETE_RXF_N;
			RX_DETE_RXF_N: begin
			
			// Avoid bus contention when i_rxf_l and i_txe_l both assert simultaneously
			// i_rxf_l asserts and usbfifo_tx isn't busy
			if(!i_rxf_l && !i_tx_active) nt_state = RX_DATA_PRE_OE_N;
			else nt_state = RX_DETE_RXF_N;
			end
			RX_DATA_PRE_OE_N: nt_state = RX_DATA_PRE_RD_N;
			RX_DATA_PRE_RD_N: begin
			//	if(i_rxf_l) nt_state = RX_RLS_DATA_RD_OE_N; *Confirm the reason
			//  should consider when r_rxf_n keeps low while usbfifo_sync is full. (need to implement later)
				if(r_rxf_n) nt_state = RX_RLS_DATA_RD_OE_N;
				else nt_state = RX_DATA_PRE_RD_N;
			end
			RX_RLS_DATA_RD_OE_N: nt_state = RX_WAIT;
			RX_WAIT: nt_state = RX_IDLE;
			default: nt_state = 3'h0;
		endcase
	end
	
	
	// Combinational Outputs
	always@ (*) begin
	
		// Initial values
		o_oe_l = 1'b1;
		o_rd_l = 1'b1;
		
		case(st_state)
			RX_IDLE:;
			RX_DETE_RXF_N:;
			RX_DATA_PRE_OE_N: o_oe_l = 1'b0;
			RX_DATA_PRE_RD_N: begin
				o_oe_l 	= (!r_rxf_n) ? 1'b0 : 1'b1;				// follow r_rxf_n (registered 1 cycle) for clean external timing at OE#. To meet the protocol.			
				o_rd_l 	= (!r_rxf_n && !i_full) ? 1'b0 : 1'b1;	// follow r_rxf_n (registered 1 cycle) for clean external timing at RD#. To meet the protocol.
																// i_rxf_l keeps low and usbfifo_sync isn't full. Could keep consuming data from FT233
			end
			RX_RLS_DATA_RD_OE_N:;
			RX_WAIT:;
		// default:
		endcase
	end
	
	
	assign o_rx_data 	= i_rx_data;
	assign o_data_valid = valid_trigger;
	
endmodule