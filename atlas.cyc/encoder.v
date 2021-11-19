//-------------------------------------------------------------------------------------------------
module encoder
//-------------------------------------------------------------------------------------------------
(
	input  wire      clock,
	input  wire      blank,
	input  wire[1:0] c,
	input  wire[7:0] d,
	output reg [9:0] q
);
//-------------------------------------------------------------------------------------------------

wire[8:0] xored  = { 1'b1, d[7] ^ xored[6], d[6] ^ xored[5], d[5] ^ xored[4], d[4] ^ xored[3], d[3] ^ xored[2], d[2] ^ xored[1], d[1] ^ xored[0], d[0] };
wire[8:0] xnored = { 1'b0, d[7] ~^ xnored[6], d[6] ~^ xnored[5], d[5] ~^ xnored[4], d[4] ~^ xnored[3], d[3] ~^ xnored[2], d[2] ~^ xnored[1], d[1] ~^ xnored[0], d[0] };

wire[3:0] ones = 4'b0000+d[0]+d[1]+d[2]+d[3]+d[4]+d[5]+d[6]+d[7];

wire[8:0] data_word     = ones > 4 || (ones == 4 && !d[0]) ?  xnored :  xored;
wire[8:0] data_word_inv = ones > 4 || (ones == 4 && !d[0]) ? ~xnored : ~xored;

wire[3:0] data_word_disparity = 4'b1100+data_word[0]+data_word[1]+data_word[2]+data_word[3]+data_word[4]+data_word[5]+data_word[6]+data_word[7];

//-------------------------------------------------------------------------------------------------

reg[3:0] dc_bias;

always @(posedge clock)
if(blank)
begin
	case(c)
		0: q <= 10'b1101010100;
		1: q <= 10'b0010101011;
		2: q <= 10'b0101010100;
		3: q <= 10'b1010101011;
	endcase
	dc_bias <= 4'b0000;
end
else
begin
	if(!dc_bias || !data_word_disparity)
	begin
		if(data_word[8])
		begin
			q <= { 2'b01, data_word[7:0] };
			dc_bias <= dc_bias + data_word_disparity;
		end
		else
		begin
			q <= { 2'b10, data_word_inv[7:0] };
			dc_bias <= dc_bias-data_word_disparity;
		end
	end
	else
	if((!dc_bias[3] && !data_word_disparity[3]) || (dc_bias[3] && data_word_disparity[3]))
	begin
		q <= { 1'b1, data_word[8], data_word_inv[7:0] };
		dc_bias <= dc_bias + data_word[8]-data_word_disparity;
	end
	else
	begin
		q <= { 1'b0, data_word };
		dc_bias <= dc_bias-data_word_inv[8]+data_word_disparity;
	end
end

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
