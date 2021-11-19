//-------------------------------------------------------------------------------------------------
// sdram commands
//-------------------------------------------------------------------------------------------------

task INHIBIT;
begin
	dramCs  <= 1'b1;
	dramRas <= 1'b1;
	dramCas <= 1'b1;
	dramWe  <= 1'b1;
	dramDQM <= 2'b11;
	dramBA  <= 2'b00;
	dramA   <= 12'h000;
end
endtask

task NOP;
begin
	dramCs  <= 1'b0;
	dramRas <= 1'b1;
	dramCas <= 1'b1;
	dramWe  <= 1'b1;
	dramDQM <= 2'b11;
	dramBA  <= 2'b00;
	dramA   <= 12'h000;
end
endtask

task REFRESH;
begin
	dramCs  <= 1'b0;
	dramRas <= 1'b0;
	dramCas <= 1'b0;
	dramWe  <= 1'b1;
	dramDQM <= 2'b11;
	dramBA  <= 2'b00;
	dramA   <= 12'h000;
end
endtask

task PRECHARGE;
input[ 1:0] ba;
input pca;
begin
	dramCs  <= 1'b0;
	dramRas <= 1'b0;
	dramCas <= 1'b1;
	dramWe  <= 1'b0;
	dramDQM <= 2'b11;
	dramBA  <= ba;
	dramA   <= { 1'b0, pca, 9'b000000000 };
end
endtask

task LMR;
input[13:0] mode;
begin
	dramCs  <= 1'b0;
	dramRas <= 1'b0;
	dramCas <= 1'b0;
	dramWe  <= 1'b0;
	dramDQM <= 2'b11;
	dramBA  <= mode[13:12];
	dramA   <= mode[11: 0];
end
endtask

task ACTIVE;
input[ 1:0] ba;
input[11:0] a;
begin
	dramCs  <= 1'b0;
	dramRas <= 1'b0;
	dramCas <= 1'b1;
	dramWe  <= 1'b1;
	dramDQM <= 2'b11;
	dramBA  <= ba;
	dramA   <= a;
end
endtask

task WRITE;
input[ 1:0] dqm;
input[ 1:0] ba;
input[ 7:0] a;
input pca;
begin
	dramCs  <= 1'b0;
	dramRas <= 1'b1;
	dramCas <= 1'b0;
	dramWe  <= 1'b0;
	dramDQM <= dqm;
	dramBA  <= ba;
	dramA   <= { 1'b0, pca, 2'b00, a };
end
endtask

task READ;
input[ 1:0] dqm;
input[ 1:0] ba;
input[ 7:0] a;
input pca;
begin
	dramCs  <= 1'b0;
	dramRas <= 1'b1;
	dramCas <= 1'b0;
	dramWe  <= 1'b1;
	dramDQM <= dqm;
	dramBA  <= ba;
	dramA   <= { 1'b0, pca, 2'b00, a };
end
endtask

//-------------------------------------------------------------------------------------------------
