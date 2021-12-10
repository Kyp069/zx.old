//-------------------------------------------------------------------------------------------------
module zx
//-------------------------------------------------------------------------------------------------
(
	input  wire       clock27,

	output wire[ 1:0] sync,
	output wire[17:0] rgb,

	input  wire       tape,

	output wire       dsgR,
	output wire       dsgL,

	output wire       dramCk,
	output wire       dramCe,
	output wire       dramCs,
	output wire       dramWe,
	output wire       dramRas,
	output wire       dramCas,
	output wire[ 1:0] dramDQM,
	inout  wire[15:0] dramDQ,
	output wire[ 1:0] dramBA,
	output wire[12:0] dramA,

	input  wire       cfgD0,
	input  wire       spiCk,
	input  wire       spiS2,
	input  wire       spiS3,
	input  wire       spiDi,
	output wire       spiDo,

	output wire       led
);
//-------------------------------------------------------------------------------------------------

wire clock;
wire sdrck;
wire power;
wire ne14M;
wire pe7M0, ne7M0;
wire pe3M5, ne3M5;

clock Clock
(
	.i      (clock27),
	.model  (model  ),
	.clock  (clock  ),
	.sdrck  (sdrck  ),
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

reg ps2k10;
reg F5 = 1'b1, F8 = 1'b1;
reg alt = 1'b1, del = 1'b1, ctrl = 1'b1;

always @(posedge clock) if(pe7M0) begin
	ps2k10 <= ps2k[10];
	if(strb)
		case(code)
			8'h03: F5 <= make;
			8'h0A: F8 <= make;
			8'h11: alt <= make;
			8'h71: del <= make;
			8'h14: ctrl <= make;
		endcase
end

//-------------------------------------------------------------------------------------------------

wire reset = power & ready & ~busy & F8 & (alt | del | ctrl) & ~status[0];// & modelp
wire nmi = F5 & ~status[1];

wire blank;
wire hsync, vsync;
wire r, g, b, i;

wire       ear = tape ^ tapeini;
wire[10:0] laudio;
wire[10:0] raudio;

wire strb = ps2k10 != ps2k[10];
wire make = !ps2k[9];
wire[7:0] code = ps2k[7:0];

wire[7:0] joy1;
wire[7:0] joy2;

wire usdCs;
wire usdCk;
wire usdMiso;
wire usdMosi;

wire       vmmCe;
wire[13:0] vmmA1;
wire[13:0] vmmA2;
wire[ 7:0] vmmD = busy ? 8'h00 : dprQ1;

wire       memCe;
wire       memRf;
wire       memRd;
wire       memWr;
wire[18:0] memA;
wire[ 7:0] memD = sdrQ[7:0];
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
	.midi   (       ),

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

wire[15:0] rmix = { 1'd0, raudio, 4'd0 };
wire[15:0] lmix = { 1'd0, laudio, 4'd0 };

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

wire[13:0] dprA1 = vmmA1;
wire[ 7:0] dprQ1;

wire       dprW2 = memWr && memA[18:17] == 2'b01 && (memA[16:14] == 3'd5 || memA[16:14] == 3'd7) && !memA[13];
wire[15:0] dprA2 = vmmA2;
wire[ 7:0] dprD2 = memQ;

dprs #(.KB(16)) Dpr
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

wire busy = ioctl && ioctlI == 8'h00;
wire ready;

wire sdrRf = busy ? 1'b1 : !memRf;
wire sdrRd = busy ? 1'b1 : !memRd;
wire sdrWr = busy ? !ioctlW : !(memWr && (memA[18] || memA[17]));

wire[23:0] sdrA = { 5'd0, busy ? ioctlA[18:0] : memA };
wire[15:0] sdrD = {2{ busy ? (ioctlA[18:17] == 2'b00 ? ioctlQ : 8'h00) : memQ }};
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

//-------------------------------------------------------------------------------------------------

wire model = !status[2];
wire mapper = !status[3];

localparam CONF_STR = {
	"ZX;;",
	"T0,Reset;",
	"T1,NMI;",
	"O2,Model,128K,48K;",
	"O3,DivMMC automapper,on,off;",
	"V,v1.0"
};

wire[10:0] ps2k;

wire[ 7:0] joystick_0;
wire[ 7:0] joystick_1;

wire       sd_conf;
wire[ 1:0] img_mounted;
wire[31:0] img_size;

wire[31:0] sd_lba;
wire[ 1:0] sd_rd;
wire[ 1:0] sd_wr;
wire       sd_ack;
wire       sd_ack_conf;

wire[ 8:0] sd_buff_addr;
wire[ 7:0] sd_buff_din;
wire[ 7:0] sd_buff_dout;

wire       ioctl;
wire[ 7:0] ioctlI;
wire       ioctlW;
wire[24:0] ioctlA;
wire[ 7:0] ioctlQ;
wire       ioctlCe = ready && pe3M5;

wire[ 1:0] buttons;
wire[31:0] status;

//wire scandoubler_disable;

mist_io #(.STRLEN(($size(CONF_STR)>>3))) mistIo
(
	.conf_str      (CONF_STR),

	.clk_sys       (clock   ),

	.SPI_SCK       (spiCk   ),
	.CONF_DATA0    (cfgD0   ),
	.SPI_SS2       (spiS2   ),
	.SPI_DI        (spiDi   ),
	.SPI_DO        (spiDo   ),

	.ps2_key       (ps2k    ),

	.joystick_0    (joy1    ),
	.joystick_1    (joy2    ),

	.sd_conf       (sd_conf     ),
	.sd_sdhc       (sd_sdhc     ),
	.img_mounted   (img_mounted ),
	.img_size      (img_size    ),

	.sd_lba        (sd_lba      ),
	.sd_rd         (sd_rd       ),
	.sd_wr         (sd_wr       ),
	.sd_ack        (sd_ack      ),
	.sd_ack_conf   (sd_ack_conf ),

	.sd_buff_addr  (sd_buff_addr),
	.sd_buff_din   (sd_buff_din ),
	.sd_buff_dout  (sd_buff_dout),

	.ioctl_download(ioctl       ),
	.ioctl_index   (ioctlI      ),
	.ioctl_wr      (ioctlW      ),
	.ioctl_addr    (ioctlA      ),
	.ioctl_dout    (ioctlQ      ),
	.ioctl_ce      (ioctlCe     ),

	.buttons       (buttons     ),
	.status        (status      )

//	.scandoubler_disable(scandoubler_disable)
);

//-------------------------------------------------------------------------------------------------

sd_card sdCard
(
	.clk_sys     (clock         ),

	.sd_conf     (sd_conf       ),
	.sd_sdhc     (sd_sdhc       ),
	.img_mounted (img_mounted[0]),
	.img_size    (img_size      ),

	.sd_lba      (sd_lba        ),
	.sd_rd       (sd_rd[0]      ),
	.sd_wr       (sd_wr[0]      ),
	.sd_ack      (sd_ack        ),
	.sd_ack_conf (sd_ack_conf   ),

	.sd_buff_addr(sd_buff_addr  ),
	.sd_buff_din (sd_buff_din   ),
	.sd_buff_dout(sd_buff_dout  ),

	.allow_sdhc  (1             ),
	.sd_busy     (sd_busy       ),

	.sd_cs       (usdCs         ),
	.sd_sck      (usdCk         ),
	.sd_sdi      (usdMosi       ),
	.sd_sdo      (usdMiso       )
);

//-------------------------------------------------------------------------------------------------

reg[17:0] palette[0:15];
initial $readmemb("palette18.bin", palette, 0);

wire[17:0] irgb = blank ? 1'd0 : model ? { r,r,{4{r&i}}, g,g,{4{g&i}}, b,b,{4{b&i}} } : palette[{ i, r, g, b }];
wire[17:0] oosd;

osd OSD
(
	.clk_sys(clock      ),
	.ce     (ne7M0      ),
	.SPI_SCK(spiCk      ),
	.SPI_SS3(spiS3      ),
	.SPI_DI (spiDi      ),
	.rotate (2'b00      ),
	.HSync  (hsync      ),
	.VSync  (vsync      ),
	.R_in   (irgb[17:12]),
	.G_in   (irgb[11: 6]),
	.B_in   (irgb[ 5: 0]),
	.R_out  (oosd[17:12]),
	.G_out  (oosd[11: 6]),
	.B_out  (oosd[ 5: 0])
);

//-------------------------------------------------------------------------------------------------
/*
reg[17:0] palette[0:15];
initial $readmemb("palette18.bin", palette, 0);

wire       ohsync;
wire       ovsync;
wire[17:0] orgb;

scandoubler #(.RGBW(18)) Scandoubler
(
	.clock  (clock  ),
	.ice    (ne7M0  ),
	.ihs    (hsync  ),
	.ivs    (vsync  ),
	.irgb   (oosd   ),
	.oce    (ne14M  ),
	.ohs    (ohsync ),
	.ovs    (ovsync ),
	.orgb   (orgb   )
);
*/
//-------------------------------------------------------------------------------------------------

assign sync = /*!scandoubler_disable ? { ovsync, ohsync } :*/ { 1'b1, ~(hsync^vsync) };
assign rgb = /*!scandoubler_disable ? orgb :*/ oosd;

assign led = ~sd_busy;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
