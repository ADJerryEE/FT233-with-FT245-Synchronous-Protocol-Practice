// MODULE NAME: usbfifo_tx
// Ver_00
// Author: Jerry Cheng



module usbfifo_tx(
	
	// INPUT 
	input  wire i_clk_60mhz, 				// FT233 CLKOUT 60MHZ
	input  wire i_rst_n,					// System reset, Low active.
	input  wire i_txe_l,					// Write request from FT233
	input  wire [7:0] i_data_tx,			// Data from an internal fifo buffer
	
	input  wire i_rx_active,  				// Flag of usbfifo_rx status. High active. (High means busy)
	input  wire i_empty,					// Flag of empty status from usbfifo_sync. High active (empty)
	
	
	// OUTPUT
	output wire o_tx_active, 				// Flag of usbfifo_tx status. High active.
	output reg  o_wr_l,						// Ack to FT233 to be ready for write operation. Low active.

	output wire o_tx_rden,					// Flag of read enable to the internal fifo memory
	output wire [7:0] o_tx_data				// Data sent out to the FT233

);


	// STATE MACHEINE DECLARATION
	// TX_RLS_WR_L may could be removed.  Consider TX_WAIT to be removed to optimize
	localparam TX_IDLE			= 3'h0;		// IDLE
	localparam TX_DETE_TX_L 	= 3'h1;		// Detect i_txe_l from FT233
	localparam TX_DATA_WR_L		= 3'h2;		// Assert o_wr_l to ack FT233 and enable wrtie operation
	localparam TX_RLS_WR_L	 	= 3'h3;		// Detect i_txe_l and release o_wr_l to end of write operation
	localparam TX_WAIT			= 3'h4;		// Wait 1 clock cycles on purpose
	

	// Main State Machine
	reg [2:0] st_state, nt_state;
	always@ (posedge i_clk_60mhz or negedge i_rst_n) begin
		if(!i_rst_n) st_state <= 3'h0;
		else 		 st_state <= nt_state;
	end


	// Interlock design
	// Bus ownership indicator
	assign o_tx_active = (st_state == TX_DATA_WR_L) || (st_state == TX_RLS_WR_L) || (st_state == TX_WAIT);


	// Combinational Inputs
	always@ (*) begin
	
		// Initial values
		nt_state	= 3'h0;
		
		case(st_state)
		
			TX_IDLE: nt_state = TX_DETE_TX_L;
			TX_DETE_TX_L: begin
				if(i_empty) nt_state = TX_DETE_TX_L;
				
			// interlock design
			// i_txe_l asserts and usbfifo_rx isn't busy
				else if(!i_txe_l && !i_rx_active) nt_state = TX_DATA_WR_L;	
				else nt_state = TX_DETE_TX_L;
			end
			TX_DATA_WR_L: begin
			
			// End the write operation when i_txe_l disasserts
			// Should enter TX_WAIT when i_empty asserts to avoid dead loop in TX_DATA_WR_L
				if(i_txe_l || i_empty) nt_state = TX_RLS_WR_L;
				else nt_state = TX_DATA_WR_L;
			end					
			TX_RLS_WR_L: nt_state = TX_WAIT;
			TX_WAIT: nt_state = TX_IDLE;
			// default:
			
		endcase
	end
	
	
	// Flag of Valid_Trigger 
	wire en_vaild_data  = ((st_state == TX_DETE_TX_L) && !i_rx_active) || (st_state == TX_DATA_WR_L);
	// wire en_vaild_data  = (st_state == TX_DATA_WR_L);								// Make gate here to implement interlock design
	wire vaild_data		= (en_vaild_data && !i_txe_l && !i_empty);						// When i_empty asserts, o_wr_l disasserts
	
	
	// Check if (i_rx_active == 1'b1); o_wr_l = 1'b1; (drives to high)
	// Synchronous Output Method
	always@ (posedge i_clk_60mhz or negedge i_rst_n) begin
		if(!i_rst_n) 					 o_wr_l	<= 1'b1;
		else if(vaild_data) 			 o_wr_l	<= 1'b0;
		else if(nt_state == TX_RLS_WR_L) o_wr_l	<= 1'b1;								// To meet protocol when releasing o_wr_l
	end


	
	assign o_tx_rden = vaild_data;
	assign o_tx_data = i_data_tx;


endmodule