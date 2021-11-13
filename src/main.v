//-------------------------------------------------------------------------------------------------
module main
//-------------------------------------------------------------------------------------------------
(
	input  wire       model,  // 0 = 48K, 1 = 128K
	input  wire       mapper, // 0 = off, 1 = on

	input  wire       reset,  // signals
	input  wire       nmi,

	input  wire       clock,  // clock 56 MHz
	input  wire       pe7M0,
	input  wire       ne7M0,
	input  wire       pe3M5,
	input  wire       ne3M5,

	output wire       blank,  // video
	output wire       hsync,
	output wire       vsync,
	output wire       r,
	output wire       g,
	output wire       b,
	output wire       i,

	input  wire       ear,    // audio
	output wire[10:0] laudio,
	output wire[10:0] raudio,
	output wire       midi,

	input  wire       strb,   // keyboard
	input  wire       make,
	input  wire[ 7:0] code,

	input  wire[ 7:0] joy1,   // joystick
	input  wire[ 7:0] joy2,

	output wire       cs,     // uSD
	output wire       ck,
	input  wire       miso,
	output wire       mosi,

	output wire       vmmCe,  // video memory
	output wire[13:0] vmmA1,
	output wire[13:0] vmmA2,
	input  wire[ 7:0] vmmD,

	output wire       memCe,  // cpu memory
	output wire       memRf,
	output wire       memRd,
	output wire       memWr,
	output wire[18:0] memA,
	input  wire[ 7:0] memD,
	output wire[ 7:0] memQ
);
//-------------------------------------------------------------------------------------------------

reg mreqt23iorqtw3;
always @(posedge clock) if(pc3M5) mreqt23iorqtw3 <= mreq & ioFE;

reg cpuck;
always @(posedge clock) if(ne7M0) cpuck <= !(cpuck && contend);

wire contend = !(vduC && cpuck && mreqt23iorqtw3 && (memC || !ioFE));

wire pc3M5 = pe3M5 & contend;
wire nc3M5 = ne3M5 & contend;

//-------------------------------------------------------------------------------------------------

reg irq = 1'b1;
always @(posedge clock) if(pc3M5) irq <= vduI;

wire rfsh;
wire mreq;
wire iorq;
wire m1;
wire rd;
wire wr;

wire[15:0] a;
wire[ 7:0] d;
wire[ 7:0] q;

cpu Cpu
(
	.clock  (clock  ),
	.pe     (pc3M5  ),
	.ne     (nc3M5  ),
	.reset  (reset  ),
	.rfsh   (rfsh   ),
	.mreq   (mreq   ),
	.iorq   (iorq   ),
	.nmi    (nmi    ),
	.irq    (irq    ),
	.m1     (m1     ),
	.rd     (rd     ),
	.wr     (wr     ),
	.a      (a      ),
	.d      (d      ),
	.q      (q      )
);

//-------------------------------------------------------------------------------------------------

reg mic;
reg speaker;
reg[2:0] border;

always @(posedge clock) if(pe7M0) if(!ioFE && !wr) { speaker, mic, border } <= q[4:0];

//-------------------------------------------------------------------------------------------------

wire       vduI;
wire       vduC;
wire[12:0] vduA;
wire[ 7:0] vduD = vmmD;
wire[ 7:0] vduQ;

video Video
(
	.model  (model  ),
	.clock  (clock  ),
	.ce     (ne7M0  ),
	.border (border ),
	.irq    (vduI   ),
	.cn     (vduC   ),
	.a      (vduA   ),
	.d      (vduD   ),
	.q      (vduQ   ),
	.blank  (blank  ),
	.hsync  (hsync  ),
	.vsync  (vsync  ),
	.r      (r      ),
	.g      (g      ),
	.b      (b      ),
	.i      (i      )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] psgA1;
wire[7:0] psgB1;
wire[7:0] psgC1;

wire[7:0] psgA2;
wire[7:0] psgB2;
wire[7:0] psgC2;

wire[ 7: 0] psgQ;
wire[15:14] psgAh = a[15:14];
wire[ 1: 1] psgAl = a[1];

turbosound Turbosound
(
	.clock  (clock  ),
	.ce     (pe3M5  ),
	.reset  (reset  ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.rd     (rd     ),
	.d      (q      ),
	.ah     (psgAh  ),
	.al     (psgAl  ),
	.q      (psgQ   ),
	.a1     (psgA1  ),
	.b1     (psgB1  ),
	.c1     (psgC1  ),
	.a2     (psgA2  ),
	.b2     (psgB2  ),
	.c2     (psgC2  ),
	.midi   (midi   )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] spdQ;
wire[7:4] spdA = a[7:4];

specdrum Specdrum
(
	.clock  (clock  ),
	.ce     (pc3M5  ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.d      (q      ),
	.q      (spdQ   ),
	.a      (spdA   )
);

//-------------------------------------------------------------------------------------------------

reg[3:0] ce8;
wire ce8M0 = !ce8;
always @(negedge clock) if(ce8 == 6) ce8 <= 1'd0; else ce8 <= ce8+1'd1;

wire saaCs = !(!iorq && !wr && a[7:0] == 8'hFF);
wire saaA0 = a[8];

wire[7:0] saaD = q;
wire[7:0] saaL;
wire[7:0] saaR;

saa1099 SAA
(
	.clk_sys(clock  ),
	.ce     (ce8M0  ),
	.rst_n  (reset  ),
	.cs_n   (saaCs  ),
	.wr_n   (saaCs  ),
	.a0     (saaA0  ),
	.din    (saaD   ),
	.out_l  (saaL   ),
	.out_r  (saaR   )
);

//-------------------------------------------------------------------------------------------------

audio Audio
(
	.ear    (ear    ),
	.mic    (mic    ),
	.speaker(speaker),
	.a1     (psgA1  ),
	.b1     (psgB1  ),
	.c1     (psgC1  ),
	.a2     (psgA2  ),
	.b2     (psgB2  ),
	.c2     (psgC2  ),
	.spd    (spdQ   ),
	.saaL   (saaL   ),
	.saaR   (saaR   ),
	.laudio (laudio ),
	.raudio (raudio )
);

//-------------------------------------------------------------------------------------------------

wire memC;

memory Memory
(
	.model  (model  ),
	.mapper (mapper ),
	.clock  (clock  ),
	.ce     (pc3M5  ),
	.reset  (reset  ),
	.rfsh   (rfsh   ),
	.mreq   (mreq   ),
	.iorq   (iorq   ),
	.rd     (rd     ),
	.wr     (wr     ),
	.m1     (m1     ),
	.a      (a      ),
	.d      (q      ),
	.cn     (memC   ),
	.va     (vduA   ),
	.vmmA1  (vmmA1  ),
	.vmmA2  (vmmA2  ),
	.memRf  (memRf  ),
	.memRd  (memRd  ),
	.memWr  (memWr  ),
	.memA   (memA   )
);
//-------------------------------------------------------------------------------------------------

wire[7:0] keyA = a[15:8];
wire[4:0] keyQ;

keyboard Keyboard
(
	.clock  (clock  ),
	.ce     (pe7M0  ),
	.strb   (strb   ),
	.make   (make   ),
	.code   (code   ),
	.a      (keyA   ),
	.q      (keyQ   )
);

//-------------------------------------------------------------------------------------------------

wire[7:0] usdQ;
wire[7:0] usdA = a[7:0];

usd uSD
(
	.clock  (clock  ),
	.cep    (pe7M0  ),
	.cen    (ne7M0  ),
	.iorq   (iorq   ),
	.wr     (wr     ),
	.rd     (rd     ),
	.d      (q      ),
	.q      (usdQ   ),
	.a      (usdA   ),
	.cs     (cs     ),
	.ck     (ck     ),
	.miso   (miso   ),
	.mosi   (mosi   )
);

//-------------------------------------------------------------------------------------------------

wire ioDF   = !(!iorq && !a[5]);                   // kempston
wire ioEB   = !(!iorq && a[7:0] == 8'hEB);         // usd
wire ioFE   = !(!iorq && !a[0]);                   // ula
wire ioFFFD = !(!iorq && a[15] && a[14] && !a[1]); // psg

assign d
	= !mreq ? memD
	: !ioDF ? joy1|joy2
	: !ioEB ? usdQ
	: !ioFE ? { 1'b1, ear|speaker, 1'b1, keyQ }
	: !ioFFFD ? psgQ
	: vduQ;

//-------------------------------------------------------------------------------------------------

assign vmmCe = pe7M0;
assign memCe = pc3M5;
assign memQ = q;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
