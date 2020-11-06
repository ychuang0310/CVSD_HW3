`timescale 1ns/100ps
`define CYCLE       5	     // CLK period.
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   1000
`define RST_DELAY   5


`ifdef tb1
    `define INFILE "../00_TESTBED/PATTERN/indata1.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode1.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden1.dat"
`elsif tb2
    `define INFILE "../00_TESTBED/PATTERN/indata2.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode2.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden2.dat"
`else
    `define INFILE "../00_TESTBED/PATTERN/indata0.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode0.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden0.dat"
`endif

`define SDFFILE "ipdc_syn.sdf"  // Modify your sdf file name


module testbed;

reg clk, rst_n;
wire        op_valid;
wire [ 2:0] op_mode;
wire        in_valid;
wire [23:0] in_data;
wire        in_ready;
wire        out_valid;
wire [23:0] out_data;

reg [23:0] indata_mem [ 63:0];
reg [ 2:0] opmode_mem [ 63:0];
reg [23:0] golden_mem [511:0];


// ==============================================
// TODO: Declare regs and wires you need
// ==============================================
reg        op_valid_r;
reg [ 2:0] op_mode_r;
reg        in_valid_r;
reg [23:0] in_data_r;
reg        in_ready_r;
reg        out_valid_r;
reg [23:0] out_data_r;
reg [2:0]topcode;

assign op_valid = op_valid_r;
assign op_mode = op_mode_r;
assign in_data = in_data_r;
assign in_valid = in_valid_r;



// For gate-level simulation only
`ifdef SDF
    initial $sdf_annotate(`SDFFILE, u_ipdc);
    initial #1 $display("SDF File %s were used for this simulation.", `SDFFILE);
`endif

// Write out waveform file
initial begin
  $fsdbDumpfile("ipdc.fsdb");
  $fsdbDumpvars(3, "+mda");
end


ipdc u_ipdc (
	.i_clk(clk),
	.i_rst_n(rst_n),
	.i_op_valid(op_valid),
	.i_op_mode(op_mode),
	.i_in_valid(in_valid),
	.i_in_data(in_data),
	.o_in_ready(in_ready),
	.o_out_valid(out_valid),
	.o_out_data(out_data)
);

// Read in test pattern and golden pattern
initial $readmemb(`INFILE, indata_mem);
initial $readmemb(`OPFILE, opmode_mem);
initial $readmemb(`GOLDEN, golden_mem);

// Clock generation
initial clk = 1'b0;
always begin #(`CYCLE/2) clk = ~clk; end

// Reset generation
initial begin
    rst_n = 1; # (               0.25 * `CYCLE);
    rst_n = 0; # ((`RST_DELAY - 0.25) * `CYCLE);
    rst_n = 1; # (         `MAX_CYCLE * `CYCLE);
    $display("Error! Runtime exceeded!");
    $finish;
end




// ==============================================
// TODO: Check pattern after process finish
// ==============================================

integer ti,j,k;
reg set;
reg startdata;
reg fuckload;

always@( negedge clk or negedge rst_n)begin
	if(!rst_n)begin
		op_valid_r <= 0;
		op_mode_r <= 0;
		in_data_r <=0;
		in_valid_r <=0;
		ti <= 0;
		j <=0;
		k<=0;
		set <=1;
	end else if(out_valid==1) begin
		set <= 1;
		//if(topcode==1 || topcode==2 || topcode==3 || topcode==4)begin
			
		//end else
		//	ti=ti+1;
	end else if(out_valid==0 &&set==1)begin
		op_valid_r <= 1;
		op_mode_r <= opmode_mem[ti];
		topcode <= opmode_mem[ti];
		set <= 0;
		if(opmode_mem[ti]==0)
			startdata <=1;
		else
			startdata <=0;
		ti=ti+1;
	end else if(out_valid==0 &&set==0)begin
		//ti=ti+1;
		op_valid_r <= 0;
		op_mode_r <= 0;
	end
end

always@(negedge clk)begin 
	if(startdata==1&&in_ready==1)begin
		if(j<64)begin
			in_data_r <= indata_mem[j];
			in_valid_r <= 1;
		end
		j=j+1;
	end

	if(j==64)begin
		startdata <=0;
		in_valid_r <=0;
		// in_data_r <=24'b001101000101000000101010; //tb0
		in_data_r <=24'b100000101100000001010010; //tb1
		// in_data_r <=24'b111000011010111001100011; //tb2
		
		//in_data_r <=0;	
	end
	
end

always@(negedge clk)begin
	if(out_valid==1)begin
		if(topcode==1 || topcode==2 || topcode==3 || topcode==4)begin
			if(out_data=== golden_mem[k])
				k=k+1;
			else begin
				$display("fuck this homework:/");
				$display("your num :%b,golden data:%b,address:%d",out_data,golden_mem[k],k);
				//k=k+1;
				$finish;
			end
		end
	end
//	if(k%16==0)begin
//		$display("%d,op:%d",k,topcode);		
//		$finish;
//	end
	// if(out_data===golden_mem[223] && (k==224))begin //tb0=223, tb1=191, tb2=319
	if(out_data===golden_mem[191] && (k==192))begin //tb0=223, tb1=191, tb2=319
	// if(out_data===golden_mem[319] && (k==320))begin //tb0=223, tb1=191, tb2=319
		$display("PASS!");
		$finish;
	end
end

endmodule
