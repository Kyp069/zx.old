//-------------------------------------------------------------------------------------------------
module flash
//-------------------------------------------------------------------------------------------------
(
	input  wire clock,
	input  wire pe,
	input  wire ne,

	output reg  vga,

	output reg  cs,
	output wire ck,
	input  wire miso,
	output wire mosi
);
//-------------------------------------------------------------------------------------------------

reg tx;
reg rx;
reg biosVga;

reg[7:0] d;
reg[7:0] fc;

always @(posedge clock) if(pe)
if(!fc[7]) begin
	fc <= fc+1'd1;
	case(fc)
		 0: cs <= 1'b1;
		14: cs <= 1'b0;

//		 0: begin tx <= 1'b1; d <= 8'h13; end
//		 1: begin tx <= 1'b0; end

		16: begin tx <= 1'b1; d <= 8'h03; end
		17: begin tx <= 1'b0; end

		32: begin tx <= 1'b1; d <= 8'h00; end
		33: begin tx <= 1'b0; end

		48: begin tx <= 1'b1; d <= 8'h70; end
		49: begin tx <= 1'b0; end

		64: begin tx <= 1'b1; d <= 8'h4D; end
		65: begin tx <= 1'b0; end

		80: rx <= 1'b1;
		81: rx <= 1'b0;

		96: rx <= 1'b1;
		97: rx <= 1'b0;

		98: vga <= q == 2'b10;
		99: cs <= 1'b1;
	endcase
end

//-------------------------------------------------------------------------------------------------

wire[7:0] q;

spi Flash
(
	.clock  (clock  ),
	.ce     (ne     ),
	.tx     (tx     ),
	.rx     (rx     ),
	.d      (d      ),
	.q      (q      ),
	.ck     (ck     ),
	.miso   (miso   ),
	.mosi   (mosi   )
);

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
