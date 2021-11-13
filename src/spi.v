//-------------------------------------------------------------------------------------------------
module spi
//-------------------------------------------------------------------------------------------------
#
(
	parameter QW = 8
)
(
	input  wire         clock,
	input  wire         ce,
	input  wire         tx,
	input  wire         rx,
	input  wire[   7:0] d,
	output wire[QW-1:0] q,
	output wire         ck,
	input  wire         miso,
	output wire         mosi
);
//-------------------------------------------------------------------------------------------------

reg[QW-1:0] md;
reg[7:0] sd;
reg[4:0] count = 5'b10000;

always @(posedge clock) if(ce)
	if(count[4])
	begin
		if(tx || rx)
		begin
			md <= sd[QW-1:0];
			sd <= tx ? d : 8'hFF;
			count <= 5'd0;
		end
	end
	else
	begin
		if(count[0]) sd <= { sd[6:0], miso };
		count <= count+5'd1;
	end

//-------------------------------------------------------------------------------------------------

assign q = md;
assign ck = count[0];
assign mosi = sd[7];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
