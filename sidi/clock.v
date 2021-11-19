//-------------------------------------------------------------------------------------------------
module clock
//-------------------------------------------------------------------------------------------------
(
	input  wire       i,
	input  wire       model,
	output wire       clock,
	output wire       sdrck,
	output wire       power,

	output reg        ne14M,

	output reg        pe7M0,
	output reg        ne7M0,

	output reg        pe3M5,
	output reg        ne3M5
);
//-------------------------------------------------------------------------------------------------

wire clock0, sdrck0, locked0;

pll0 Clock0
(
	.inclk0 (i      ),
	.c0     (clock0 ), // 56.0000 MHz output
	.c1     (sdrck0 ),
	.locked (locked0)
);

//-------------------------------------------------------------------------------------------------

wire clock1, sdrck1, locked1;

pll1 Clock1
(
	.inclk0 (i      ),
	.c0     (clock1 ), // 56.7504 MHz output
	.c1     (sdrck1 ),
	.locked (locked1)
);

//-------------------------------------------------------------------------------------------------

reg[3:0] ce = 4'd1;
always @(negedge clock) if(power) begin
	ce <= ce+1'd1;
	ne14M <= ~ce[0] & ~ce[1];
	pe7M0 <= ~ce[0] & ~ce[1] &  ce[2];
	ne7M0 <= ~ce[0] & ~ce[1] & ~ce[2];
	pe3M5 <= ~ce[0] & ~ce[1] & ~ce[2] &  ce[3];
	ne3M5 <= ~ce[0] & ~ce[1] & ~ce[2] & ~ce[3];
end

//-------------------------------------------------------------------------------------------------

assign clock = model ? clock1 : clock0;
assign sdrck = model ? sdrck1 : sdrck0;
assign power = locked0 & locked1;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
