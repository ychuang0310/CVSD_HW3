// `include "../sram_256x8/sram_256x8.v"
`include "define.v"
`include "YCbCr.v"
`include "median.v"

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
reg     [ 4: 0] Median_State_r, Median_State_w;

//ITERATOR
reg     [ 2: 0] Iterator_X_r, Iterator_Y_r;
reg     [ 2: 0] Iterator_X_w, Iterator_Y_w;

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
reg             Sram_Wen;

// MEDIAN
reg     [ 7: 0] median_i0_r [0:2], median_i1_r [0:2], median_i2_r [0:2];
reg     [ 7: 0] median_i0_w [0:2], median_i1_w [0:2];
reg     [ 7: 0] median_m0_r [0:2], median_m1_r [0:2], median_m2_r [0:2];
reg     [ 7: 0] median_m0_w [0:2], median_m1_w [0:2], median_m2_w [0:2];
wire    [ 7: 0] median_m [0:2], Median_Final [0:2];
wire            Median_Finish;

// OUTPUT
reg             o_out_valid_r, o_out_valid_w;

// YCbCr mode
wire    [7: 0]  Y, Cb, Cr;


genvar i;
integer k;

// sram address: 00yyyxxx
// xxx: x coordinate {000, 001,..., 111}
// yyy: y coordinate {000, 001,..., 111}
// sram[0:2]: channel 0 ~ 2 (RGB | YCbCr)
generate
    for(i=0; i<3; i=i+1) begin: u_sram
        sram_256x8 sram(Sram_Data_o[i], i_clk, Sram_Cen, Sram_Wen, Sram_Addr, Sram_Data_i[i]);
    end
endgenerate

generate
    for(i=0; i<3; i=i+1) begin: u_median
        median_3 fuck(median_i0_r[i], median_i1_r[i], median_i2_r[i], median_m[i]);
        median_3 hihi(median_m0_r[i], median_m1_r[i], median_m2_r[i], Median_Final[i]);
    end
endgenerate

ycbcr u_ycbcr(Sram_Data_o[0], Sram_Data_o[1], Sram_Data_o[2], Y, Cb, Cr);

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
// SRAM
assign Sram_Cen         = ~i_rst_n;

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

// MIDEAN
assign Median_Finish    = (IPDC_State_r == `IPDC_State_Median) & o_out_valid_w;

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
// DEFAULT
always@(*) begin
    {Iterator_X_w, Iterator_Y_w}    = 6'b0;
    {Origin_Y_w, Origin_X_w}        = {Origin_Y_r, Origin_X_r};
    {Sram_Data_i[2], Sram_Data_i[1], Sram_Data_i[0]} = 24'b0;
    Sram_Addr       = 8'b0;
    Sram_Wen        = 1'b1;

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
            if(Median_Finish)   IPDC_State_w = `IPDC_State_Ready;
        end
        `IPDC_State_YCbCr, `IPDC_State_RBG: begin
            IPDC_State_w = `IPDC_State_Ready;
        end
    endcase
end

// LOAD
always@(*) begin
    if(IPDC_State_r == `IPDC_State_Load) begin
        Sram_Addr = {2'b0, Iterator_Y_r, Iterator_X_r};
        {Sram_Data_i[2], Sram_Data_i[1], Sram_Data_i[0]} = i_in_data;
        Sram_Wen = 1'b0;

        if(i_in_valid) {Iterator_Y_w, Iterator_X_w} = {Iterator_Y_r, Iterator_X_r} + 6'b1;
        o_out_valid_w = &{Iterator_Y_r ,Iterator_X_r};
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

// MEDIAN
always@(*) begin
    Median_State_w = `Median_State_Idle;
    for(k=0; k<3; k=k+1) median_i0_w[k] = median_i0_r[k];
    for(k=0; k<3; k=k+1) median_i1_w[k] = median_i1_r[k];
    for(k=0; k<3; k=k+1) median_i2_r[k] = 8'b0;
    for(k=0; k<3; k=k+1) median_m0_w[k] = median_m0_r[k];
    for(k=0; k<3; k=k+1) median_m1_w[k] = median_m1_r[k];
    for(k=0; k<3; k=k+1) median_m2_w[k] = median_m2_r[k];
    
    if(IPDC_State_r == `IPDC_State_Median) begin
        case(Median_State_r)
            `Median_State_Idle: begin
                Median_State_w = `Median_State_Read_0;
            end
            `Median_State_Read_0: begin
                Median_State_w = `Median_State_Read_1;
                for(k=0; k<3; k=k+1) median_i0_w[k] = Sram_Data_o[k];
            end
            `Median_State_Read_1: begin
                Median_State_w = `Median_State_Read_2;
                for(k=0; k<3; k=k+1) median_i1_w[k] = Sram_Data_o[k];
            end
            `Median_State_Read_2: begin
                Median_State_w = `Median_State_Read_3;
                for(k=0; k<3; k=k+1) median_i2_r[k] = Sram_Data_o[k];
                for(k=0; k<3; k=k+1) median_m0_w[k] = median_m[k];
            end
            `Median_State_Read_3: begin
                Median_State_w = `Median_State_Read_4;
                for(k=0; k<3; k=k+1) median_i0_w[k] = Sram_Data_o[k];
            end
            `Median_State_Read_4: begin
                Median_State_w = `Median_State_Read_5;
                for(k=0; k<3; k=k+1) median_i1_w[k] = Sram_Data_o[k];
            end
            `Median_State_Read_5: begin
                Median_State_w = `Median_State_Read_6;
                for(k=0; k<3; k=k+1) median_i2_r[k] = Sram_Data_o[k];
                for(k=0; k<3; k=k+1) median_m1_w[k] = median_m[k];
            end
            `Median_State_Read_6: begin
                Median_State_w = `Median_State_Read_7;
                for(k=0; k<3; k=k+1) median_i0_w[k] = Sram_Data_o[k];
            end
            `Median_State_Read_7: begin
                Median_State_w = `Median_State_Read_8;
                for(k=0; k<3; k=k+1) median_i1_w[k] = Sram_Data_o[k];
            end
            `Median_State_Read_8: begin
                Median_State_w = `Median_State_Write;
                for(k=0; k<3; k=k+1) median_i2_r[k] = Sram_Data_o[k];
                for(k=0; k<3; k=k+1) median_m2_w[k] = median_m[k];
            end
            `Median_State_Write: begin
                Median_State_w = `Median_State_Idle;
                for(k=0; k<3; k=k+1) Sram_Data_i[k] = Median_Final[k];
                Sram_Wen = 1'b0;
                {Iterator_Y_w, Iterator_X_w} = {Iterator_Y_r, Iterator_X_r} + 6'b1;
            end
        endcase
    end

    Sram_Addr = {2'b0, Iterator_Y_r + {Median_State_r[3], Median_State_r[3:2]}, Iterator_X_r + {Median_State_r[1], Median_State_r[1:0]}};
    
    o_out_valid_w = (Median_State_r == `Median_State_Write) & (&{Iterator_Y_r, Iterator_X_r});
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
        IPDC_State_r                                <= `IPDC_State_Idle;
        Display_State_r                             <= `Display_State_Idle;
        Median_State_r                              <= `Median_State_Idle;
        {Iterator_Y_r, Iterator_X_r}                <= 6'b0;
        {Origin_Y_r, Origin_X_r}                    <= 6'b0;
        {Display_Y_Offset_r, Display_X_Offset_r}    <= 4'b0;
        Display_Mode_r                              <= `Display_Mode_RGB;

        for(k=0; k<3; k=k+1) median_i0_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_i1_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_m0_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_m1_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_m2_r[k]         <= 8'b0;

        o_out_valid_r                               <= 1'b0;
    end
    else begin
        IPDC_State_r                                <= IPDC_State_w;
        Display_State_r                             <= Display_State_w;
        Median_State_r                              <= Median_State_w;
        {Iterator_Y_r, Iterator_X_r}                <= {Iterator_Y_w, Iterator_X_w};
        {Origin_Y_r, Origin_X_r}                    <= {Origin_Y_w, Origin_X_w};
        {Display_Y_Offset_r, Display_X_Offset_r}    <= {Display_Y_Offset_w, Display_X_Offset_w};
        Display_Mode_r                              <= Display_Mode_w;

        for(k=0; k<3; k=k+1) median_i0_r[k]         <= median_i0_w[k];
        for(k=0; k<3; k=k+1) median_i1_r[k]         <= median_i1_w[k];
        for(k=0; k<3; k=k+1) median_m0_r[k]         <= median_m0_w[k];
        for(k=0; k<3; k=k+1) median_m1_r[k]         <= median_m1_w[k];
        for(k=0; k<3; k=k+1) median_m2_r[k]         <= median_m2_w[k];

        o_out_valid_r                               <=  o_out_valid_w;
    end
end


endmodule
