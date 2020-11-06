// `include "../sram_256x8/sram_256x8.v"
`include "define.v"
`include "YCbCr.v"

module ipdc (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 2:0] i_op_mode,
	input         i_in_valid,
	input  [23:0] i_in_data,
	output        o_in_ready,
	output        o_out_valid,
	output [23:0] o_out_data
);

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //

// STATE
reg     [ 3: 0] IPDC_State_r, IPDC_State_w;
reg             Display_State_r, Display_State_w;

// LOAD
wire            Load_Finish;

// DISPLAY
wire    [ 2: 0] Display_X, Display_Y;
wire            Display_Finish;

// DISPLAY MODE
reg             Display_Mode_r, Display_Mode_w;

// PIXEL COORDINATE
reg     [ 2: 0] Origin_X_r, Origin_Y_r;
reg     [ 2: 0] Origin_X_w, Origin_Y_w;

reg     [ 1: 0] Display_X_Offset_r, Display_Y_Offset_r;
reg     [ 1: 0] Display_X_Offset_w, Display_Y_Offset_w;

// SRAM
wire    [ 7: 0] Sram_Data_o [0:2];
reg     [ 7: 0] Sram_Data_i [0:2];
reg     [ 7: 0] Sram_Addr;
wire            Sram_Cen;
wire            Sram_Wen;

// OUTPUT
reg             o_out_valid_r, o_out_valid_w;

// YCbCr mode
wire    [7: 0]  Y, Cb, Cr;

// sram address: 00xxxyyy
// xxx: x coordinate {000, 001,..., 111}
// yyy: y coordinate {000, 001,..., 111}
// sram[0:2]: channel 0 ~ 2 (RGB | YCbCr)
generate
    genvar i;
    for(i=0; i<3; i=i+1) begin: u_sram
        sram_256x8 sram(Sram_Data_o[i], i_clk, Sram_Cen, Sram_Wen, Sram_Addr, Sram_Data_i[i]);
    end
endgenerate

ycbcr u_ycbcr(Sram_Data_o[0], Sram_Data_o[1], Sram_Data_o[2], Y, Cb, Cr);

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
// SRAM
assign Sram_Cen         = ~i_rst_n;
assign Sram_Wen         = (IPDC_State_r != `IPDC_State_Load);

// LOAD
assign Load_Finish      = (IPDC_State_r == `IPDC_State_Load) & o_out_valid_w;

// DISPLAY
assign Display_X        = Origin_X_r + {1'b0, Display_X_Offset_r};
assign Display_Y        = Origin_Y_r + {1'b0, Display_Y_Offset_r};
assign Display_Finish   = ~o_out_valid_w;

// OUTPUT
assign o_in_ready       = (IPDC_State_r == `IPDC_State_Load);
assign o_out_valid      = o_out_valid_r;
assign o_out_data       = (Display_State_r != `Display_State_Display) ? 24'b0 :
                          (Display_Mode_r == `Display_Mode_RGB) ? {Sram_Data_o[2], Sram_Data_o[1], Sram_Data_o[0]} : {Cr, Cb, Y};

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
// DEFAULT
always@(*) begin
    Origin_X_w      = Origin_X_r;
    Origin_Y_w      = Origin_Y_r;
    {Sram_Data_i[2], Sram_Data_i[1], Sram_Data_i[0]} = 24'b0;
    Sram_Addr       = 8'b0;

    o_out_valid_w   = 1'b0;
end

// STATE
always@(*) begin
    IPDC_State_w = IPDC_State_r;

    case(IPDC_State_r)
        `IPDC_State_Idle:       IPDC_State_w = `IPDC_State_Ready;

        `IPDC_State_Ready: begin
            if(i_op_valid)      IPDC_State_w = {1'b0, i_op_mode};
        end

        `IPDC_State_Load: begin
            if(Load_Finish)     IPDC_State_w = `IPDC_State_Ready;
        end

        `IPDC_State_Display: begin
            if(Display_Finish)  IPDC_State_w = `IPDC_State_Ready;
        end

        `IPDC_State_ShiftRight, `IPDC_State_ShiftDown, `IPDC_State_Default, `IPDC_State_Zoomin: begin
            IPDC_State_w = `IPDC_State_Display;
        end
        `IPDC_State_Median: begin
            
        end
        `IPDC_State_YCbCr, `IPDC_State_RBG: begin
            IPDC_State_w = `IPDC_State_Ready;
        end
    endcase
end

// LOAD
always@(*) begin
    if((IPDC_State_r == `IPDC_State_Ready) & IPDC_State_w == `IPDC_State_Load) {Origin_Y_w, Origin_X_w} = 6'b0;
    if(IPDC_State_r == `IPDC_State_Load) begin
        Sram_Addr = {2'b0, Origin_Y_r, Origin_X_r};
        {Sram_Data_i[2], Sram_Data_i[1], Sram_Data_i[0]} = i_in_data;

        if(i_in_valid) {Origin_Y_w, Origin_X_w} = {Origin_Y_r, Origin_X_r} + 6'b1;
        o_out_valid_w = &{Origin_Y_r ,Origin_X_r};
    end
end

// DISPLAY
always@(*) begin
    Display_State_w = `Display_State_Idle;
    {Display_Y_Offset_w, Display_X_Offset_w} = 4'b0;
    if(IPDC_State_r == `IPDC_State_Display) begin
        Display_State_w = `Display_State_Display;
        Sram_Addr = {2'b0, Display_Y, Display_X};
        {Display_Y_Offset_w, Display_X_Offset_w}  = {Display_Y_Offset_r, Display_X_Offset_r} + 4'b1;
        o_out_valid_w = (Display_State_r == `Display_State_Idle) | (|{Display_Y_Offset_r, Display_X_Offset_r});
    end
end

// SHIFTRIGHT
always@(*) begin
    if(IPDC_State_r == `IPDC_State_ShiftRight) begin
        if(~Origin_X_r[2]) Origin_X_w = Origin_X_r + 3'b1;
    end
end

// SHIFTDOWN
always@(*) begin
    if(IPDC_State_r == `IPDC_State_ShiftDown) begin
        if((~Origin_Y_r[2])) Origin_Y_w = Origin_Y_r + 3'b1;
    end
end

// DEFAULT
always@(*) begin
    if(IPDC_State_r == `IPDC_State_Default) begin
        Origin_X_w = 3'b0;
        Origin_Y_w = 3'b0;
    end
end

// ZOOMIN
always@(*) begin
    if(IPDC_State_r == `IPDC_State_Zoomin) begin
        Origin_X_w = 3'd2;
        Origin_Y_w = 3'd2;
    end
end

// DISPLAYMODE
always@(*) begin
    Display_Mode_w = Display_Mode_r;
    if(IPDC_State_r == `IPDC_State_RBG)         Display_Mode_w = `Display_Mode_RGB;
    else if(IPDC_State_r == `IPDC_State_YCbCr)  Display_Mode_w = `Display_Mode_YCbCr;
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always@(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
        IPDC_State_r        <= `IPDC_State_Idle;
        Display_State_r     <= `Display_State_Idle;
        Origin_X_r          <= 3'b0;
        Origin_Y_r          <= 3'b0;
        Display_X_Offset_r  <= 2'b0;
        Display_Y_Offset_r  <= 2'b0;
        Display_Mode_r      <= `Display_Mode_RGB;

        o_out_valid_r       <= 1'b0;
    end
    else begin
        IPDC_State_r        <= IPDC_State_w;
        Display_State_r     <= Display_State_w;
        Origin_X_r          <= Origin_X_w;
        Origin_Y_r          <= Origin_Y_w;
        Display_X_Offset_r  <= Display_X_Offset_w;
        Display_Y_Offset_r  <= Display_Y_Offset_w;
        Display_Mode_r      <= Display_Mode_w;

        o_out_valid_r       <=  o_out_valid_w;
    end
end


endmodule
