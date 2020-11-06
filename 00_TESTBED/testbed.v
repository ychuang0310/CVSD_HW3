`timescale 1ns/100ps
`define CYCLE       10.0     // CLK period.
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   10000000
`define RST_DELAY   5


`ifdef tb1
    `define INFILE "./PATTERN/indata1.dat"
    `define OPFILE "./PATTERN/opmode1.dat"
    `define GOLDEN "./PATTERN/golden1.dat"
`elsif tb2
    `define INFILE "./PATTERN/indata2.dat"
    `define OPFILE "./PATTERN/opmode2.dat"
    `define GOLDEN "./PATTERN/golden2.dat"
`else
    `define INFILE "./PATTERN/indata0.dat"
    `define OPFILE "./PATTERN/opmode0.dat"
    `define GOLDEN "./PATTERN/golden0.dat"
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
	.i_clk(),
	.i_rst_n(),
	.i_op_valid(),
	.i_op_mode(),
	.i_in_valid(),
	.i_in_data(),
	.o_in_ready(),
	.o_out_valid(),
	.o_out_data()
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


endmodule
