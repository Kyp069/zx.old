//-------------------------------------------------------------------------------------------------
module video
//-------------------------------------------------------------------------------------------------
(
	input  wire       model,

	input  wire       clock,
	input  wire       ce,

	input  wire[ 2:0] border,
	output wire       irq,
	output wire       cn,
	output reg [12:0] a,
	input  wire[ 7:0] d,
	output reg [ 7:0] q,

	output wire       blank,
	output wire       hsync,
	output wire       vsync,
	output wire       r,
	output wire       g,
	output wire       b,
	output wire       i
);
//-------------------------------------------------------------------------------------------------

wire[8:0] hCountEnd = model ? 9'd456 : 9'd448;
wire[8:0] vCountEnd = model ? 9'd311 : 9'd312;

wire[8:0] irqBeg = model? 9'd6  : 9'd2 ;
wire[8:0] irqEnd = model? 9'd78 : 9'd66;

//-------------------------------------------------------------------------------------------------

reg[8:0] hc, hCount;
wire hCountReset = hc >= (hCountEnd-1);
always @(posedge clock) if(hCountReset) hCount <= 1'd0; else hCount <= hc+1'd1;
always @(posedge clock) if(ce) hc <= hCount;

reg[8:0] vc, vCount;
wire vCountReset = vc >= (vCountEnd-1);
always @(posedge clock) begin vCount <= vc; if(hCountReset) if(vCountReset) vCount <= 1'd0; else vCount <= vc+1'd1; end
always @(posedge clock) if(ce) vc <= vCount;

reg[4:0] fc, fCount;
always @(posedge clock) begin fCount <= fc; if(hCountReset) if(vCountReset) fCount <= fc+1'd1; end
always @(posedge clock) if(ce) fc <= fCount;

//-------------------------------------------------------------------------------------------------

reg dataEnable;
wire de = hCount <= 255 && vCount <= 191;
always @(posedge clock) if(ce) dataEnable <= de;

reg videoEnable;
wire videoEnableLoad = hCount[3];
always @(posedge clock) if(ce) if(videoEnableLoad) videoEnable <= dataEnable;

//-------------------------------------------------------------------------------------------------

reg[7:0] dataInput;
wire dataInputLoad = (hCount[3:0] ==  9 || hCount[3:0] == 13) && dataEnable;
always @(posedge clock) if(ce) if(dataInputLoad) dataInput <= d;

reg[7:0] attrInput;
wire attrInputLoad = (hCount[3:0] == 11 || hCount[3:0] == 15) && dataEnable;
always @(posedge clock) if(ce) if(attrInputLoad) attrInput <= d;

reg[7:0] dataOutput;
wire dataOutputLoad = hCount[2:0] == 4 && videoEnable;
always @(posedge clock) if(ce) if(dataOutputLoad) dataOutput <= dataInput; else dataOutput <= { dataOutput[6:0], 1'b0 };

reg[7:0] attrOutput;
wire attrOutputLoad = hCount[2:0] == 4;
always @(posedge clock) if(ce) if(attrOutputLoad) attrOutput <= { videoEnable ? attrInput[7:3] : { 2'b00, border }, attrInput[2:0] };

wire addrLoad = dataEnable && hCount[3] && !hCount[0];
always @(posedge clock) if(ce) if(addrLoad) a <= { !hCount[1] ? { vCount[7:6], vCount[2:0] } : { 3'b110, vCount[7:6] }, vCount[5:3], hCount[7:4], hCount[2] };

wire fbLoad = dataEnable && hCount[3] && hCount[0];
wire fbReset = hCount[3:0] == 1;
always @(posedge clock) if(ce) if(fbLoad) q <= d; else if(fbReset) q <= 8'hFF;

//-------------------------------------------------------------------------------------------------

wire hBlank = hCount >= 320 && hCount < 416;
wire vBlank = vCount >= 248 && vCount < 256;

wire dataSelect = dataOutput[7] ^ (fCount[4] & attrOutput[7]);

//-------------------------------------------------------------------------------------------------

assign irq = !(vCount == 248 && hCount >= irqBeg && hCount < irqEnd);
assign cn = dataEnable && (hCount[3] || hCount[2]);

assign blank = hBlank | vBlank;
assign hsync = hCount >= 344 && hCount < 376;
assign vsync = vCount >= 248 && vCount < 252;

assign r = dataSelect ? attrOutput[1] : attrOutput[4];
assign g = dataSelect ? attrOutput[2] : attrOutput[5];
assign b = dataSelect ? attrOutput[0] : attrOutput[3];
assign i = attrOutput[6];

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
