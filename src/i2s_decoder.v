module i2s_decoder
(
	input wire clock,
	input wire ck,
	input wire lr,
	input wire d,
	output reg [15:0] lmidi,
	output reg [15:0] rmidi
);

reg[ 1:0] sck_synch = 2'b00, ws_synch = 2'b00, sd_synch = 2'b00;
reg[17:0] sreg = 17'b0_0000_0000_0000_0001;

reg scks_prev = 1'b0, wss_prev = 1'b0;
wire scks = sck_synch[1], wss = ws_synch[1], sds = sd_synch[1];

always @(posedge clock)
begin
	sck_synch[1] <= sck_synch[0];
	sck_synch[0] <= ck;
	ws_synch[1] <= ws_synch[0];
	ws_synch[0] <= lr;
	sd_synch[1] <= sd_synch[0];
	sd_synch[0] <= d;

	scks_prev <= scks;
	if (scks_prev == 1'b0 && scks == 1'b1) begin  // flanco positivo de SCK
		wss_prev <= wss;

		if (wss_prev != wss) begin // ha ocurrido flanco en WS ?
			if (wss_prev == 1'b0) lmidi <= sreg[15:0]; else rmidi <= sreg[15:0];
			sreg <= 17'b0_0000_0000_0000_0001;
		end
		else begin
			if (sreg[16] == 1'b0) begin
				sreg <= {sreg[15:0], sds};
			end
		end
	end
end

endmodule
