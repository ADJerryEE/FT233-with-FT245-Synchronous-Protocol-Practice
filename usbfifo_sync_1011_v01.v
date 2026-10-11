// MODULE NAME: usbfifo
// Description: 8x256 FIFO DESIGN (WIDTH = 8 bits wide, DEPTH = 1024. [1023:0]
// Ver_00
// Author: Jerry Cheng


// 10012026 Modify
/*
	1.  Change fifo into BRAM instaed of Distrubuted RAM (thousands of DFF). This is to optimize the latency and 
		avoid route congestion.
	

*/


module usbfifo_sync #(
	parameter WIDTH 	= 8,
	parameter DEPTH 	= 1024,
	parameter WIDTH_PTR = 10				// 2^10 = 1024. Num of pointers
)(

	// INPUT
	input wire i_clk_60mhz,					// FT233 CLKOUT 60MHZ
	input wire i_rst_n,						// System reset, Low active
	input wire [WIDTH-1:0] i_wr_data,		// input write data during read operation of FT233
	
	input wire i_wr_en,						// Write enable, High active
	input wire i_rd_en,						// Read enable , High active
	
	
	// OUTPUT
	output reg [WIDTH-1:0] o_rd_data,		// Output read data during write operation of FT233
	output wire o_empty,					// Flag of fifo empty status
	output wire o_full						// Flag of fifo full status
	

);

	// Flags of wr_valid and rd_valid 
	wire wr_valid = i_wr_en && !o_full;		// wr enable asserts and fifo isn't full.  Real write enable to fifo
	wire rd_valid = i_rd_en && !o_empty; 	// rd enable asserts and fifo isn't empty. Real read enable to fifo
	
	// Memory Initialization
	// Initialize 8x1024 memory
	// integer i;
	// Test to synthesize BRAM
	// reg [WIDTH-1:0] mem [0:DEPTH-1];
	
	
	// Methos 1: Synthesize BRAM, by UG901
	/*
	initial begin
	mem[0] 	 = 8'h00;	mem[1] 	 = 8'h00;	mem[2]   = 8'h00;	mem[3]   = 8'h00;
	mem[4] 	 = 8'h00;	mem[5] 	 = 8'h00;	mem[6]   = 8'h00;	mem[7]   = 8'h00;
	mem[8] 	 = 8'h00;	mem[9] 	 = 8'h00;	mem[10]  = 8'h00;	mem[11]  = 8'h00;
	mem[12]  = 8'h00;	mem[13]  = 8'h00;	mem[14]  = 8'h00;	mem[15]  = 8'h00;
	mem[16]  = 8'h00;	mem[17]  = 8'h00;	mem[18]  = 8'h00;	mem[19]  = 8'h00;
	mem[20]  = 8'h00;	mem[21]  = 8'h00;	mem[22]  = 8'h00;	mem[23]  = 8'h00;
	mem[24]  = 8'h00;	mem[25]  = 8'h00;	mem[26]  = 8'h00;	mem[27]  = 8'h00;
	mem[28]  = 8'h00;	mem[29]  = 8'h00;	mem[30]  = 8'h00;	mem[31]  = 8'h00;
	mem[32]  = 8'h00;	mem[33]  = 8'h00;	mem[34]  = 8'h00;	mem[35]  = 8'h00;
	mem[36]  = 8'h00;	mem[37]  = 8'h00;	mem[38]  = 8'h00;	mem[39]  = 8'h00;
	mem[40]  = 8'h00;	mem[41]  = 8'h00;	mem[42]  = 8'h00;	mem[43]  = 8'h00;
	mem[44]  = 8'h00;	mem[45]  = 8'h00;	mem[46]  = 8'h00;	mem[47]  = 8'h00;
	mem[48]  = 8'h00;	mem[49]  = 8'h00;	mem[50]  = 8'h00;	mem[51]  = 8'h00;
	mem[52]  = 8'h00;	mem[53]  = 8'h00;	mem[54]  = 8'h00;	mem[55]  = 8'h00;
	mem[56]  = 8'h00;	mem[57]  = 8'h00;	mem[58]  = 8'h00;	mem[59]  = 8'h00;
	mem[60]  = 8'h00;	mem[61]  = 8'h00;	mem[62]  = 8'h00;	mem[63]  = 8'h00;
	mem[64]  = 8'h00;	mem[65]  = 8'h00;	mem[66]  = 8'h00;	mem[67]  = 8'h00;
	mem[68]  = 8'h00;	mem[69]  = 8'h00;	mem[70]  = 8'h00;	mem[71]  = 8'h00;
	mem[72]  = 8'h00;	mem[73]  = 8'h00;	mem[74]  = 8'h00;	mem[75]  = 8'h00;
	mem[76]  = 8'h00;	mem[77]  = 8'h00;	mem[78]  = 8'h00;	mem[79]  = 8'h00;
	mem[80]  = 8'h00;	mem[81]  = 8'h00;	mem[82]  = 8'h00;	mem[83]  = 8'h00;
	mem[84]  = 8'h00;	mem[85]  = 8'h00;	mem[86]  = 8'h00;	mem[87]  = 8'h00;
	mem[88]  = 8'h00;	mem[89]  = 8'h00;	mem[90]  = 8'h00;	mem[91]  = 8'h00;
	mem[92]  = 8'h00;	mem[93]  = 8'h00;	mem[94]  = 8'h00;	mem[95]  = 8'h00;
	mem[96]  = 8'h00;	mem[97]  = 8'h00;	mem[98]  = 8'h00;	mem[99]  = 8'h00;
	mem[100] = 8'h00;	mem[101] = 8'h00;	mem[102] = 8'h00;	mem[103] = 8'h00;
	mem[104] = 8'h00;	mem[105] = 8'h00;	mem[106] = 8'h00;	mem[107] = 8'h00;
	mem[108] = 8'h00;	mem[109] = 8'h00;	mem[110] = 8'h00;	mem[111] = 8'h00;
	mem[112] = 8'h00;	mem[113] = 8'h00;	mem[114] = 8'h00;	mem[115] = 8'h00;
	mem[116] = 8'h00;	mem[117] = 8'h00;	mem[118] = 8'h00;	mem[119] = 8'h00;
	mem[120] = 8'h00;	mem[121] = 8'h00;	mem[122] = 8'h00;	mem[123] = 8'h00;
	mem[124] = 8'h00;	mem[125] = 8'h00;	mem[126] = 8'h00;	mem[127] = 8'h00;
	mem[128] = 8'h00;	mem[129] = 8'h00;	mem[130] = 8'h00;	mem[131] = 8'h00;
	mem[132] = 8'h00;	mem[133] = 8'h00;	mem[134] = 8'h00;	mem[135] = 8'h00;
	mem[136] = 8'h00;	mem[137] = 8'h00;	mem[138] = 8'h00;	mem[139] = 8'h00;
	mem[140] = 8'h00;	mem[141] = 8'h00;	mem[142] = 8'h00;	mem[143] = 8'h00;
	mem[144] = 8'h00;	mem[145] = 8'h00;	mem[146] = 8'h00;	mem[147] = 8'h00;
	mem[148] = 8'h00;	mem[149] = 8'h00;	mem[150] = 8'h00;	mem[151] = 8'h00;
	mem[152] = 8'h00;	mem[153] = 8'h00;	mem[154] = 8'h00;	mem[155] = 8'h00;
	mem[156] = 8'h00;	mem[157] = 8'h00;	mem[158] = 8'h00;	mem[159] = 8'h00;
	mem[160] = 8'h00;	mem[161] = 8'h00;	mem[162] = 8'h00;	mem[163] = 8'h00;
	mem[164] = 8'h00;	mem[165] = 8'h00;	mem[166] = 8'h00;	mem[167] = 8'h00;
	mem[168] = 8'h00;	mem[169] = 8'h00;	mem[170] = 8'h00;	mem[171] = 8'h00;
	mem[172] = 8'h00;	mem[173] = 8'h00;	mem[174] = 8'h00;	mem[175] = 8'h00;
	mem[176] = 8'h00;	mem[177] = 8'h00;	mem[178] = 8'h00;	mem[179] = 8'h00;
	mem[180] = 8'h00;	mem[181] = 8'h00;	mem[182] = 8'h00;	mem[183] = 8'h00;
	mem[184] = 8'h00;	mem[185] = 8'h00;	mem[186] = 8'h00;	mem[187] = 8'h00;
	mem[188] = 8'h00;	mem[189] = 8'h00;	mem[190] = 8'h00;	mem[191] = 8'h00;
	mem[192] = 8'h00;	mem[193] = 8'h00;	mem[194] = 8'h00;	mem[195] = 8'h00;
	mem[196] = 8'h00;	mem[197] = 8'h00;	mem[198] = 8'h00;	mem[199] = 8'h00;
	mem[200] = 8'h00;	mem[201] = 8'h00;	mem[202] = 8'h00;	mem[203] = 8'h00;
	mem[204] = 8'h00;	mem[205] = 8'h00;	mem[206] = 8'h00;	mem[207] = 8'h00;
	mem[208] = 8'h00;	mem[209] = 8'h00;	mem[210] = 8'h00;	mem[211] = 8'h00;
	mem[212] = 8'h00;	mem[213] = 8'h00;	mem[214] = 8'h00;	mem[215] = 8'h00;
	mem[216] = 8'h00;	mem[217] = 8'h00;	mem[218] = 8'h00;	mem[219] = 8'h00;
	mem[220] = 8'h00;	mem[221] = 8'h00;	mem[222] = 8'h00;	mem[223] = 8'h00;
	mem[224] = 8'h00;	mem[225] = 8'h00;	mem[226] = 8'h00;	mem[227] = 8'h00;
	mem[228] = 8'h00;	mem[229] = 8'h00;	mem[230] = 8'h00;	mem[231] = 8'h00;
	mem[232] = 8'h00;	mem[233] = 8'h00;	mem[234] = 8'h00;	mem[235] = 8'h00;
	mem[236] = 8'h00;	mem[237] = 8'h00;	mem[238] = 8'h00;	mem[239] = 8'h00;
	mem[240] = 8'h00;	mem[241] = 8'h00;	mem[242] = 8'h00;	mem[243] = 8'h00;
	mem[244] = 8'h00;	mem[245] = 8'h00;	mem[246] = 8'h00;	mem[247] = 8'h00;
	mem[248] = 8'h00;	mem[249] = 8'h00;	mem[250] = 8'h00;	mem[251] = 8'h00;
	mem[252] = 8'h00;	mem[253] = 8'h00;	mem[254] = 8'h00;	mem[255] = 8'h00;
	end
	*/
	
	// Methos 2: Synthesize BRAM with for loop method with initial begin (Need to check synthesis result) 
	/*
	integer i;
	reg [WIDTH-1:0] mem [0:DEPTH-1];
	initial begin
		for (i = 0; i < DEPTH; i = i + 1) mem[i] = 8'hf0;
	end
	*/
	
	// Methos 3: Synthesize BRAM with ram_style = "block" attribute
	// Tell Vivado to synthesize BRAM
    (* ram_style = "block" *) reg [WIDTH-1:0] mem [0: DEPTH-1];
    
	// Given initial values (8'h00) to BRAM
	integer i;
	initial begin
		for (i=0; i<DEPTH; i=i+1) mem[i] <= 8'h00;
	end
	
	
	// Write port: write pointer and i_wr_data
	reg  [WIDTH_PTR:0] 	 wr_ptr;								
	wire [WIDTH_PTR-1:0] wr_addr = wr_ptr[WIDTH_PTR-1:0];	
	always@ (posedge i_clk_60mhz or negedge i_rst_n) begin
		if (!i_rst_n) 	  wr_ptr <= 0; 
		else if(wr_valid) wr_ptr <= wr_ptr + 1'b1;
	end
	
	
	// Read port: Read pointer and o_rd_data
	reg  [WIDTH_PTR:0] rd_ptr;												// read pointers
	wire [WIDTH_PTR-1:0] rd_addr = rd_ptr[WIDTH_PTR-1:0];					// address line of read inside fifo
	always@ (posedge i_clk_60mhz or negedge i_rst_n) begin
		if (!i_rst_n) 	  rd_ptr <= 0;
		else if(rd_valid) rd_ptr <= rd_ptr + 1'b1;
		
		// if rd_valid disasserts, release io_data bus. 
		// else o_rd_data	<= 8'hzz;
	end

	
	// FIFO store/ push 
    always@ (posedge i_clk_60mhz) begin
		if (wr_valid) begin
			mem[wr_addr] <= i_wr_data;
		end
	end
    
	
	// FIFO send/ pop
    always@ (posedge i_clk_60mhz) begin
		if (rd_valid) begin
			o_rd_data <= mem[rd_addr];
		end
	end


	// Flags of o_full and o_empty 
	assign o_full  = (wr_ptr[WIDTH_PTR-1:0] == rd_ptr[WIDTH_PTR-1:0]) &&	// the remaing bits match except MSB.
					 (wr_ptr[WIDTH_PTR] 	!= rd_ptr[WIDTH_PTR]);			// AND MSB mismatches
					 				 
	assign o_empty = (wr_ptr == rd_ptr);
	
	
endmodule