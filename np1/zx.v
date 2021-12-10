//-------------------------------------------------------------------------------------------------
module zx
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock50,

	output wire[ 1:0] sync,
	output wire[17:0] rgb,

	input  wire       tape,

	output wire       dsgR,
	output wire       dsgL,

	output wire       i2sCk,
	output wire       i2sLr,
	output wire       i2sD,

	input  wire       midiCk,
	input  wire       midiLr,
	input  wire       midiD,
	output wire       midiQ,

	input  wire       ps2kCk,
	input  wire       ps2kD,

	output wire       joyCk,
	output wire       joyLd,
	output wire       joyS,
	input  wire       joyD,

	output wire       usdCs,
	output wire       usdCk,
	input  wire       usdMiso,
	output wire       usdMosi,

//	output wire       dramCk,
//	output wire       dramCe,
//	output wire       dramCs,
//	output wire       dramWe,
//	output wire       dramRas,
//	output wire       dramCas,
//	output wire[ 1:0] dramDQM,
//	inout  wire[15:0] dramDQ,
//	output wire[ 1:0] dramBA,
//	output wire[12:0] dramA,

	output wire       sramUb,
	output wire       sramLb,
	output wire       sramOe,
	output wire       sramWe,
	inout  wire[15:0] sramDQ,
	output wire[20:0] sramA,

	output wire       stm,
	output wire       led
);
//-------------------------------------------------------------------------------------------------

localparam VGA = 1'b0;
localparam MODEL = 1'b1;
localparam MAPPER = 1'b1;

//-------------------------------------------------------------------------------------------------

wire clock;
wire power;
wire ne14M;
wire pe7M0, ne7M0;
wire pe3M5, ne3M5;

clock Clock
(
	.i      (clock50),
	.model  (model  ),
	.clock  (clock  ),
	.power  (power  ),
	.ne14M  (ne14M  ),
	.pe7M0  (pe7M0  ),
	.ne7M0  (ne7M0  ),
	.pe3M5  (pe3M5  ),
	.ne3M5  (ne3M5  )
);

//-------------------------------------------------------------------------------------------------

reg tapeini, tapegot;
always @(posedge clock) if(power) if(!tapegot) { tapeini, tapegot } <= { tape, 1'b1 };

//-------------------------------------------------------------------------------------------------

wire strb;
wire make;
wire[7:0] code;

ps2 PS2
(
	.clock  (clock  ),
	.ce     (pe7M0  ),
	.ps2Ck  (ps2kCk ),
	.ps2D   (ps2kD  ),
	.strb   (strb   ),
	.make   (make   ),
	.code   (code   )
);

reg F1 = 1'b1, F2 = 1'b1, F4 = 1'b1, F5 = 1'b1, F8 = 1'b1;
reg alt = 1'b1, del = 1'b1, ctrl = 1'b1;
reg scrlck = 1'b1;

always @(posedge clock) if(pe7M0)
if(strb)
	case(code)
		8'h05: F1 <= make;
		8'h06: F2 <= make;
		8'h0C: F4 <= make;
		8'h03: F5 <= make;
		8'h0A: F8 <= make;
		8'h11: alt <= make;
		8'h71: del <= make;
		8'h14: ctrl <= make;
		8'h7E: scrlck <= make;
	endcase

reg vga = VGA;
reg model = MODEL;
reg mapper = MAPPER;

reg F1d = 1'b1, F2d = 1'b1, F4d = 1'b1, scrlckd = 1'b1, modelp = 1'b1;

always @(posedge clock) if(pe7M0) begin
	modelp <= 1'b1;
	if(strb) begin
		F1d <= F1;
		F2d <= F2;
		F4d <= F4;
		scrlckd <= scrlck;

		if(!F1 && F1d) begin model <= 1'b0; modelp <= 1'b0; end
		if(!F2 && F2d) begin model <= 1'b1; modelp <= 1'b0; end
		if(!F4 && F4d) mapper <= ~mapper;
		if(!scrlck && scrlckd) vga <= ~vga;
	end
end

//-------------------------------------------------------------------------------------------------

wire[7:0] joy1;
wire[7:0] joy2;

joystick Joystick
(
	.clock  (clock  ),
	.ce     (ne7M0  ),
	.joyCk  (joyCk  ),
	.joyLd  (joyLd  ),
	.joyS   (joyS   ),
	.joyD   (joyD   ),
	.joy1   (joy1   ),
	.joy2   (joy2   )
);

//-------------------------------------------------------------------------------------------------

wire reset = power & ready & init & F8 & (alt | del | ctrl) & modelp;
wire nmi = F5;

wire blank;
wire hsync, vsync;
wire r, g, b, i;

wire       ear = tape ^ tapeini;
wire[10:0] laudio;
wire[10:0] raudio;

wire       vmmCe;
wire[13:0] vmmA1;
wire[13:0] vmmA2;
wire[ 7:0] vmmD = init ? dprQ1 : 8'h00;

wire       memCe;
wire       memRf;
wire       memRd;
wire       memWr;
wire[18:0] memA;
wire[ 7:0] memD =  sramDQ[7:0]; // sdrQ[7:0]; // sramDQ[7:0]
wire[ 7:0] memQ;

main Main
(
	.model  (model  ),
	.mapper (mapper ),

	.clock  (clock  ),
	.pe7M0  (pe7M0  ),
	.ne7M0  (ne7M0  ),
	.pe3M5  (pe3M5  ),
	.ne3M5  (ne3M5  ),

	.reset  (reset  ),
	.nmi    (nmi    ),

	.blank  (blank  ),
	.hsync  (hsync  ),
	.vsync  (vsync  ),
	.r      (r      ),
	.g      (g      ),
	.b      (b      ),
	.i      (i      ),

	.ear    (ear    ),
	.laudio (laudio ),
	.raudio (raudio ),
	.midi   (midiQ  ),

	.strb   (strb   ),
	.make   (make   ),
	.code   (code   ),

	.joy1   (joy1   ),
	.joy2   (joy2   ),

	.cs     (usdCs  ),
	.ck     (usdCk  ),
	.miso   (usdMiso),
	.mosi   (usdMosi),

	.vmmCe  (vmmCe  ),
	.vmmA1  (vmmA1  ),
	.vmmA2  (vmmA2  ),
	.vmmD   (vmmD   ),

	.memCe  (memCe  ),
	.memRf  (memRf  ),
	.memRd  (memRd  ),
	.memWr  (memWr  ),
	.memA   (memA   ),
	.memD   (memD   ),
	.memQ   (memQ   )
);

//-------------------------------------------------------------------------------------------------

wire[15:0] lmidi;
wire[15:0] rmidi;

i2s_decoder Midi
(
	.clock  (clock  ),
	.ck     (midiCk ),
	.lr     (midiLr ),
	.d      (midiD  ),
	.lmidi  (lmidi  ),
	.rmidi  (rmidi  )
);

wire[15:0] rmix = { rmidi[15:1] ^ 16'h4000 }+{ 1'd0, raudio, 4'd0 };
wire[15:0] lmix = { lmidi[15:1] ^ 16'h4000 }+{ 1'd0, laudio, 4'd0 };

//-------------------------------------------------------------------------------------------------

dsg #(.MSBI(15)) dsgRight
(
	.clock  (clock  ),
	.reset  (reset  ),
	.d      (rmix   ),
	.q      (dsgR   )
);

dsg #(.MSBI(15)) dsgLeft
(
	.clock  (clock  ),
	.reset  (reset  ),
	.d      (lmix   ),
	.q      (dsgL   )
);

//-------------------------------------------------------------------------------------------------

i2s I2S
(
	.clock  (clock  ),
	.r      (rmix   ),
	.l      (lmix   ),
	.ck     (i2sCk  ),
	.lr     (i2sLr  ),
	.d      (i2sD   )
);

//-------------------------------------------------------------------------------------------------

reg[20:0] ic = 0;
wire init = ic[20];
always @(posedge clock) if(vmmCe) if(ready) if(!init) ic <= ic+1'd1;

wire[18:0] iniA = ic[19:1];

//-------------------------------------------------------------------------------------------------

wire[15:0] dprA1 = init ? { 2'b00, vmmA1 } : iniA[15:0];
wire[ 7:0] dprQ1;

wire       dprW2 = memWr && memA[18:17] == 2'b01 && (memA[16:14] == 3'd5 || memA[16:14] == 3'd7) && !memA[13];
wire[15:0] dprA2 = vmmA2;
wire[ 7:0] dprD2 = memQ;

dprs #(.KB(64), .FN("rom.hex")) Dpr
(
	.clock  (clock  ),
	.ce1    (vmmCe  ),
	.a1     (dprA1  ),
	.q1     (dprQ1  ),
	.ce2    (memCe  ),
	.we2    (dprW2  ),
	.a2     (dprA2  ),
	.d2     (dprD2  )
);

//-------------------------------------------------------------------------------------------------

wire ready = 1'b1;

assign sramUb = 1'b1;
assign sramLb = 1'b0;
assign sramOe = 1'b0;
assign sramWe = init ? !(memWr && (memA[18] || memA[17])) : !ic[0];
assign sramDQ = sramWe ? 16'bZ : {2{ init ? memQ : iniA[18:17] == 2'b00 ? dprQ1 : 8'h00 }};
assign sramA  = { 2'b00, init ? memA : iniA };

//-------------------------------------------------------------------------------------------------
/*
wire ready;

wire sdrRf = init ? !memRf : 1'b1;
wire sdrRd = init ? !memRd : 1'b1;
wire sdrWr = init ? !(memWr && (memA[18] || memA[17])) : !ic[0];

wire[23:0] sdrA = { 5'd0, init ? memA : iniA };
wire[15:0] sdrD = {2{ init ? memQ : iniA[18:17] == 2'b00 ? dprQ1 : 8'h00 }};
wire[15:0] sdrQ;

sdram SDRam
(
	.clock  (clock  ),
	.ready  (ready  ),
	.reset  (reset  ),
	.rfsh   (sdrRf  ),
	.rd     (sdrRd  ),
	.wr     (sdrWr  ),
	.a      (sdrA   ),
	.d      (sdrD   ),
	.q      (sdrQ   ),
	.dramCs (dramCs ),
	.dramRas(dramRas),
	.dramCas(dramCas),
	.dramWe (dramWe ),
	.dramDQM(dramDQM),
	.dramDQ (dramDQ ),
	.dramBA (dramBA ),
	.dramA  (dramA  )
);

assign dramCk = clock;
assign dramCe = 1'b1;
*/
//-------------------------------------------------------------------------------------------------

reg[17:0] palette[0:15];
initial $readmemb("palette18.bin", palette, 0);

wire ohsync;
wire ovsync;

wire[17:0] irgb = blank ? 1'd0 : model ? { r,r,{4{r&i}}, g,g,{4{g&i}}, b,b,{4{b&i}} } : palette[{ i, r, g, b }];
wire[17:0] orgb;

scandoubler #(.RGBW(18)) Scandoubler
(
	.clock  (clock  ),
	.ice    (ne7M0  ),
	.ihs    (hsync  ),
	.ivs    (vsync  ),
	.irgb   (irgb   ),
	.oce    (ne14M  ),
	.ohs    (ohsync ),
	.ovs    (ovsync ),
	.orgb   (orgb   )
);

//-------------------------------------------------------------------------------------------------

assign sync = vga ? { ovsync, ohsync } : { 1'b1, ~(hsync^vsync) };
assign rgb = vga ? orgb : irgb;

assign stm = 1'b0;
assign led = usdCs;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
