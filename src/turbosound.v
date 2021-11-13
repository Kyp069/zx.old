//-------------------------------------------------------------------------------------------------
module turbosound
//-------------------------------------------------------------------------------------------------
(
	input  wire        clock,
	input  wire        ce,

	input  wire        reset,
	input  wire        iorq,
	input  wire        wr,
	input  wire        rd,
	input  wire[ 7: 0] d,
	output wire[ 7: 0] q,
	input  wire[15:14] ah,
	input  wire[ 1: 1] al,

	output wire[ 7: 0] a1,
	output wire[ 7: 0] b1,
	output wire[ 7: 0] c1,

	output wire[ 7: 0] a2,
	output wire[ 7: 0] b2,
	output wire[ 7: 0] c2,

	output wire        midi
);
//-------------------------------------------------------------------------------------------------

wire bdir = !iorq && ah[15] && !al[1] && !wr;
wire bc1  = !iorq && ah[15] && !al[1] && ah[14] && (!rd || !wr);
wire[7:0] psgQ;

reg sel;
always @(posedge clock) if(!reset) sel <= 1'b0; else if(bdir && bc1 && d[4]) sel <= ~d[0];

//-------------------------------------------------------------------------------------------------

wire bdir1 = !sel ? bdir : 1'b0;
wire bc11 = !sel ? bc1 : 1'b0;

wire[7:0] q1;
wire[7:0] io1;

jt49_bus Psg1
(
	.clk    (clock  ),
	.sel    (1'b0   ),
	.clk_en (ce     ),
	.rst_n  (reset  ),
	.bdir   (bdir1  ),
	.bc1    (bc11   ),
	.din    (d      ),
	.dout   (q1     ),
	.A      (a1     ),
	.B      (b1     ),
	.C      (c1     ),
	.IOA_in (8'h00  ),
	.IOA_out(io1    ),
	.IOB_in (8'h00  ),
	.IOB_out(       )
);

//-------------------------------------------------------------------------------------------------

wire bdir2 = sel ? bdir : 1'b0;
wire bc12 = sel ? bc1 : 1'b0;

wire[7:0] q2;
wire[7:0] io2;

jt49_bus Psg2
(
	.clk    (clock  ),
	.sel    (1'b0   ),
	.clk_en (ce     ),
	.rst_n  (reset  ),
	.bdir   (bdir2  ),
	.bc1    (bc12   ),
	.din    (d      ),
	.dout   (q2     ),
	.A      (a2     ),
	.B      (b2     ),
	.C      (c2     ),
	.IOA_in (8'h00  ),
	.IOA_out(io2    ),
	.IOB_in (8'h00  ),
	.IOB_out(       )
);

//-------------------------------------------------------------------------------------------------

assign q = !sel ? q1 : q2;
assign midi = !sel ? io1[2] : io2[2];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
