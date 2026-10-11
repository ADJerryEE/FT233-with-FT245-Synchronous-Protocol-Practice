// MODULE NAME: usbfifo
// Ver_00
// Author: Jerry Cheng



// Modification 0920
/*
	1. o_rd_data should be a critical path. Need to check timing report since it may be too long
*/

	// Data flow direction: Based on the definition from datashet of FT233
	// Read  operation: FT233 --> FPGA
	// Write operation: FPGA  --> FT233

module usbfifo_top(

	// INPUT
	input wire i_clk_60mhz,					// FT233 CLKOUT 60MHZ
	input wire i_rst_n,						// System reset
	input wire i_rxf_l,						// RXF# from FT233 to enable read operation. Low active.
	input wire i_txe_l,						// TXE# from FT233 to enable write operation. Low active.
	
	
	// OUTPUT 
	output wire o_oe_l,						// FPGA acks FT233 to change the dir of data bus. Low active.
	output wire o_rd_l,						// FPGA acks FT233 to be ready for read operation. 
	output wire o_wr_l,						// FPGA acks FT233 to be ready for write operation
	//output wire o_simu_l,					// SIMU_L#


	// INOUT
	inout [7:0] io_data						// Data bus
	
	
);

	
	// Internal Wires onnection
	wire [7:0] i_rx_data, o_rx_data;
	wire [7:0] i_tx_data, o_tx_data;
	wire o_tx_rden;
	wire o_rx_wren;
	wire rx_active, tx_active;				// Set 1st priority as read operation when i_rxf_l and i_txe_l are both asserted
	wire w_empty, w_full;
	
	
	// Tri-state buffer with dir control
	assign io_data	 = (o_oe_l) ? o_tx_data : 8'hzz;
	assign i_rx_data = io_data;
	

	// SUB MODULES INST
	// fifo_rx
	usbfifo_rx usbfifo_rx(
	
		.i_clk_60mhz(i_clk_60mhz),						
		.i_rst_n(i_rst_n),	
	
		.i_rxf_l(i_rxf_l),							
		.o_oe_l(o_oe_l),							
		.o_rd_l(o_rd_l),
		
		.i_rx_data(i_rx_data),					// data from FT233
		.o_rx_data(o_rx_data),					// data to internal fifo memory							
		
		.o_rx_active(rx_active),
		.i_tx_active(tx_active),
		
		.i_full(w_full),
		
		.o_data_valid(o_rx_wren)
	);


	// fifo_tx
	usbfifo_tx usbfifo_tx(
	
		.i_clk_60mhz(i_clk_60mhz), 				
		.i_rst_n(i_rst_n),
	
		.i_txe_l(i_txe_l),
		.o_wr_l(o_wr_l),
	
		.i_data_tx(i_tx_data),					// data from internal fifo memory
		.o_tx_data(o_tx_data),					// data sent out to FT233
	
		.o_tx_active(tx_active),
		.i_rx_active(rx_active),
		
		.i_empty(w_empty),
		.o_tx_rden(o_tx_rden)					// To internal fifo memory	
			
	);


	// fifo_sync
	usbfifo_sync usbfifo_sync(
		.i_clk_60mhz(i_clk_60mhz), 				
		.i_rst_n(i_rst_n),
	
		.i_wr_en(o_rx_wren),					// data wr enable
		.i_rd_en(o_tx_rden),					// data rd enable
		
		.i_wr_data(o_rx_data),					// data stores to internal fifo memory. connect usbfifo_rx.
		.o_rd_data(i_tx_data),					// data sent out to internal fifo memory. connect usbfifo_tx.
		
		.o_empty(w_empty),
		.o_full(w_full)	

	);


endmodule