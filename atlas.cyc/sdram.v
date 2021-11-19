//-------------------------------------------------------------------------------------------------
module sdram
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock,
	output reg        ready,

	input  wire       reset,
	input  wire       rfsh,
	input  wire       rd,
	input  wire       wr,
	input  wire[21:0] a,
	input  wire[15:0] d,
	output reg [15:0] q,

	output reg        dramCs,
	output reg        dramWe,
	output reg        dramRas,
	output reg        dramCas,
	output reg [ 1:0] dramDQM,
	inout  wire[15:0] dramDQ,
	output reg [ 1:0] dramBA,
	output reg [11:0] dramA
);
//-------------------------------------------------------------------------------------------------
`include "sdram_cmd.v"
//-------------------------------------------------------------------------------------------------

reg resetd = 1'b1, resetp = 1'b0;
always @(negedge clock) begin resetd <= reset; resetp <= !reset && resetd; end

reg rfshd = 1'b1, rfshp = 1'b0;
always @(negedge clock) begin rfshd <= rfsh; rfshp <= !rfsh && rfshd; end

reg rdd = 1'b1, rdp = 1'b0;
always @(negedge clock) begin rdd <= rd; rdp <= !rd && rdd; end

reg wrd = 1'b1, wrp = 1'b0;
always @(negedge clock) begin wrd <= wr; wrp <= !wr && wrd; end

//-------------------------------------------------------------------------------------------------

localparam sINIT = 0;
localparam sIDLE = 1;
localparam sREAD = 2;
localparam sWRITE = 3;
localparam sREFRESH = 4;

reg counting = 1'b0;
reg[13:0] count = 1'd0;
reg[ 2:0] state = 1'd0;

always @(posedge clock)
if(resetp) state <= sINIT;
else begin
	NOP;													// default state is NOP
	if(counting) count <= count+1'd1; else count <= 1'd0;

	case(state)
	sINIT: begin
		counting <= 1'b1;

		case(count)
		    0: ready <= 1'b0;
		11200: PRECHARGE(2'b00, 1'b1);						// PRECHARGE: all, tRP's minimum value is 20ns
		11208: LMR(14'b0000_1_00_010_0_000);				// LDM: CL = 2, BT = seq, BL = 1, 20ns
		11216: REFRESH;										// REFRESH, tRFC's minimum value is 60ns
		11224: REFRESH;										// REFRESH, tRFC's minimum value is 60ns
		11232: REFRESH;										// REFRESH, tRFC's minimum value is 60ns
		11240: REFRESH;										// REFRESH, tRFC's minimum value is 60ns
		11248: REFRESH;										// REFRESH, tRFC's minimum value is 60ns
		11256: REFRESH;										// REFRESH, tRFC's minimum value is 60ns
		11264: REFRESH;										// REFRESH, tRFC's minimum value is 60ns
		11272: REFRESH;										// REFRESH, tRFC's minimum value is 60ns
		11280: begin
			ready <= 1'b1;
			state <= sIDLE;
		end
		endcase
	end
	sIDLE: begin
		counting <= 1'b0;

		if(rdp) state <= sREAD; else
		if(wrp) state <= sWRITE; else
		if(rfshp) state <= sREFRESH;
	end
	sREAD: begin
		counting <= 1'b1;

		case(count)
		0: ACTIVE(a[21:20], a[19:8]);
		3: READ(2'b00, a[21:20], a[7:0], 1'b1);
		6: q <= dramDQ;
		7: state <= sIDLE;
		endcase
	end
	sWRITE: begin
		counting <= 1'b1;

		case(count)
		0: ACTIVE(a[21:20], a[19:8]);
		3: WRITE(2'b00, a[21:20], a[7:0], 1'b1);
		7: state <= sIDLE;
		endcase
	end
	sREFRESH: begin
		counting <= 1'b1;

		case(count)
		1: REFRESH;
		7: state <= sIDLE;
		endcase
	end
	endcase
end

//-------------------------------------------------------------------------------------------------

assign dramDQ = dramWe ? 16'bZ : d;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
