`timescale 1ns/100ps
`define CYCLE       8.0     // CLK period.
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   10000000
`define RST_DELAY   5.0


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
reg         op_valid;
reg  [ 2:0] op_mode;
reg         in_valid;
reg  [23:0] in_data;
wire        in_ready;
wire        out_valid;
wire [23:0] out_data;

reg [23:0] indata_mem [ 63:0];
reg [ 2:0] opmode_mem [ 63:0];
reg [23:0] golden_mem [511:0];


// ==============================================
// TODO: Declare regs and wires you need
// ==============================================
integer i, j, golden_index;


// For gate-level simulation only
`ifdef SDF
    initial $sdf_annotate(`SDFFILE, u_ipdc);
    initial #1 $display("SDF File %s were used for this simulation.", `SDFFILE);
`endif

// Write out waveform file
initial begin
  $fsdbDumpfile("ipdc.fsdb");
  $fsdbDumpvars(0, "+mda");
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

initial begin
    golden_index = 0;
    op_valid = 1'b0;
    op_mode = 3'b0;
    in_valid = 1'b0;
    in_data = 24'b0;
    #(`CYCLE);
    wait (rst_n == 1'b1);
    for (i = 0; i < 64; i = i + 1) begin
        @(negedge clk)
        op_valid = 1'b1;
        op_mode = opmode_mem[i];
        #(`CYCLE);
        op_valid = 1'b0;
        op_mode = 3'd0;
        if (opmode_mem[i] == 3'd0) begin
            for (j = 0; j < 64; j = j + 1) begin
                in_valid = 1'b1;
                in_data = indata_mem[j];
                #(`CYCLE);
            end
            in_data = 24'd0;
            in_valid = 1'b0;
            wait (out_valid == 1'b1);
            #(`CYCLE);
            $display("op(%d) done", opmode_mem[i]);
        end
        if (opmode_mem[i] >= 3'd1 & opmode_mem[i] <= 3'd4) begin
            for (j = golden_index; j < golden_index + 16; j = j + 1) begin
                wait (out_valid == 1'b1);
                @(negedge clk)
                if (golden_mem[j] != out_data) begin
                    $display("Error!, (%d)th golden data: op=(%d), golden=(%h), yours=(%h)",
                            j, opmode_mem[i], golden_mem[j], out_data);
                    $finish;
                end
                #(`CYCLE * 0.5);
            end
            golden_index = golden_index + 16;
            $display("op(%d) correct!", opmode_mem[i]);
        end
        if (opmode_mem[i] >= 3'd5 & opmode_mem[i] <= 3'd7) begin
            wait (out_valid == 1'b1);
            #(`CYCLE);
            $display("op(%d) done!", opmode_mem[i]);
        end
    end
    $display("Simulation Pass!");
    $finish;
end

endmodule
