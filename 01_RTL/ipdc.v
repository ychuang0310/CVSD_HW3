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
reg             Load_State_r, Load_State_w;
reg             Display_State_r, Display_State_w;
reg     [ 4: 0] Median_State_r, Median_State_w;

//ITERATOR
reg     [ 2: 0] Iterator_X_r, Iterator_Y_r;
reg     [ 2: 0] Iterator_X_w, Iterator_Y_w;
wire    [ 2: 0] Iterator_X_Add_1;

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
reg     [ 1: 0] Sram_Addr_Prefix_r;
reg     [ 1: 0] Sram_Addr_Prefix_w;
wire            Sram_Cen;
reg             Sram_Wen;

// MEDIAN
reg     [ 7: 0] median_i0_r [0:2], median_i1_r [0:2], median_i2_r [0:2];
reg     [ 7: 0] median_i3_r [0:2], median_i4_r [0:2], median_i5_r [0:2];
reg     [ 7: 0] median_i6_r [0:2], median_i7_r [0:2], median_i8_r [0:2];
reg     [ 7: 0] median_i0_w [0:2], median_i1_w [0:2], median_i2_w [0:2];
reg     [ 7: 0] median_i3_w [0:2], median_i4_w [0:2], median_i5_w [0:2];
reg     [ 7: 0] median_i6_w [0:2], median_i7_w [0:2], median_i8_w [0:2];
wire    [ 7: 0] Median[0:2];

reg     [ 7: 0] median_m0_r [0:2], median_m1_r [0: 2], median_m2_r [0: 2], median_m3_r [0: 2];
reg     [ 7: 0] median_m4_r [0:2], median_m5_r [0: 2], median_m6_r [0: 2], median_m7_r [0: 2];
reg     [ 7: 0] median_m0_w [0:2], median_m1_w [0: 2], median_m2_w [0: 2], median_m3_w [0: 2];
reg     [ 7: 0] median_m4_w [0:2], median_m5_w [0: 2], median_m6_w [0: 2], median_m7_w [0: 2];

wire            iter_t_edge, iter_b_edge;
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
        sram_256x8 sram(.Q(Sram_Data_o[i]), .CLK(i_clk), .CEN(Sram_Cen), .WEN(Sram_Wen), .A(Sram_Addr), .D(Sram_Data_i[i]));
    end
endgenerate

generate
    for(i=0; i<3; i=i+1) begin: u_median
        median_9 fuck(i_clk, i_rst_n, median_i0_r[i], median_i1_r[i], median_i2_r[i], median_i3_r[i], median_i4_r[i],
                                      median_i5_r[i], median_i6_r[i], median_i7_r[i], median_i8_r[i], Median[i]);
    end
endgenerate

ycbcr u_ycbcr(Sram_Data_o[0], Sram_Data_o[1], Sram_Data_o[2], Y, Cb, Cr);

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
// ITERATOR
assign Iterator_X_Add_1 = Iterator_X_r + 3'b1;

// SRAM
assign Sram_Cen         = ~i_rst_n;

// LOAD
assign Load_Finish      = o_out_valid_w;

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
assign iter_t_edge      = ~|Iterator_Y_r;
assign iter_b_edge      =  &Iterator_Y_r;

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
always@(*) begin
    // COORDINATE
    {Iterator_Y_w, Iterator_X_w}    = 6'b0;
    {Origin_Y_w, Origin_X_w}        = {Origin_Y_r, Origin_X_r};

    // SRAM
    {Sram_Data_i[2], Sram_Data_i[1], Sram_Data_i[0]} = 24'b0;
    Sram_Addr           = {Sram_Addr_Prefix_r, 6'b0};
    Sram_Addr_Prefix_w  = Sram_Addr_Prefix_r;
    Sram_Wen            = 1'b1;

    // OUTPUT
    o_out_valid_w       = 1'b0;

    // STATE
    IPDC_State_w        = IPDC_State_r;

    // LOAD
    Load_State_w        = `Load_State_Load;

    // DISPLAY
    Display_State_w = `Display_State_Idle;
    {Display_Y_Offset_w, Display_X_Offset_w} = 4'b0;

    // MEDIAN
    Median_State_w = `Median_State_Idle;
    for(k=0; k<3; k=k+1) median_i0_w[k] = median_i0_r[k];
    for(k=0; k<3; k=k+1) median_i1_w[k] = median_i1_r[k];
    for(k=0; k<3; k=k+1) median_i2_w[k] = median_i2_r[k];
    for(k=0; k<3; k=k+1) median_i3_w[k] = median_i3_r[k];
    for(k=0; k<3; k=k+1) median_i4_w[k] = median_i4_r[k];
    for(k=0; k<3; k=k+1) median_i5_w[k] = median_i5_r[k];
    for(k=0; k<3; k=k+1) median_i6_w[k] = median_i6_r[k];
    for(k=0; k<3; k=k+1) median_i7_w[k] = median_i7_r[k];
    for(k=0; k<3; k=k+1) median_i8_w[k] = median_i8_r[k];

    for(k=0; k<3; k=k+1) median_m0_w[k] = median_m0_r[k];
    for(k=0; k<3; k=k+1) median_m1_w[k] = median_m1_r[k];
    for(k=0; k<3; k=k+1) median_m2_w[k] = median_m2_r[k];
    for(k=0; k<3; k=k+1) median_m3_w[k] = median_m3_r[k];
    for(k=0; k<3; k=k+1) median_m4_w[k] = median_m4_r[k];
    for(k=0; k<3; k=k+1) median_m5_w[k] = median_m5_r[k];
    for(k=0; k<3; k=k+1) median_m6_w[k] = median_m6_r[k];
    for(k=0; k<3; k=k+1) median_m7_w[k] = median_m7_r[k];

    // DISPLAYMODE
    Display_Mode_w = Display_Mode_r;


    case(IPDC_State_r)
        `IPDC_State_Idle: begin
            IPDC_State_w = `IPDC_State_Ready;
        end

        `IPDC_State_Ready: begin
            if(i_op_valid)      IPDC_State_w = {1'b0, i_op_mode};
        end
        `IPDC_State_Load: begin
            if(Load_Finish)     IPDC_State_w = `IPDC_State_Ready;

            Sram_Addr = {Sram_Addr_Prefix_r, Iterator_Y_r, Iterator_X_r};
            {Sram_Data_i[2], Sram_Data_i[1], Sram_Data_i[0]} = i_in_data;
            Sram_Wen = ~i_in_valid;

            if(i_in_valid) {Iterator_Y_w, Iterator_X_w} = {Iterator_Y_r, Iterator_X_r} + 6'b1;
            if(&{Iterator_Y_r ,Iterator_X_r}) Load_State_w = `Load_State_Stall;
            o_out_valid_w = (Load_State_r == `Load_State_Stall);
        end

        `IPDC_State_Display: begin
            if(Display_Finish)  IPDC_State_w = `IPDC_State_Ready;

            Display_State_w = `Display_State_Display;
            Sram_Addr = {Sram_Addr_Prefix_r, Display_Y, Display_X};
            {Display_Y_Offset_w, Display_X_Offset_w}  = {Display_Y_Offset_r, Display_X_Offset_r} + 4'b1;
            o_out_valid_w = (Display_State_r == `Display_State_Idle) | (|{Display_Y_Offset_r, Display_X_Offset_r});
        end

        `IPDC_State_ShiftRight: begin
            IPDC_State_w = `IPDC_State_Display;

            if(~Origin_X_r[2]) Origin_X_w = Origin_X_r + 3'b1;
        end

        `IPDC_State_ShiftDown: begin
            IPDC_State_w = `IPDC_State_Display;

            if((~Origin_Y_r[2])) Origin_Y_w = Origin_Y_r + 3'b1;
        end

        `IPDC_State_Default: begin
            IPDC_State_w = `IPDC_State_Display;

            Origin_X_w = 3'b0;
            Origin_Y_w = 3'b0;
        end

        `IPDC_State_Zoomin: begin
            IPDC_State_w = `IPDC_State_Display;

            Origin_X_w = 3'd2;
            Origin_Y_w = 3'd2;
        end

        `IPDC_State_Median: begin
            if(Median_Finish)   IPDC_State_w = `IPDC_State_Ready;

            {Iterator_Y_w, Iterator_X_w} = {Iterator_Y_r, Iterator_X_r};
            case(Median_State_r)
                `Median_State_Idle: begin
                    Median_State_w = `Median_State_Read_1;
                    for(k=0; k<3; k=k+1) median_i0_w[k] = 8'b0;
                    for(k=0; k<3; k=k+1) median_i3_w[k] = 8'b0;
                    for(k=0; k<3; k=k+1) median_i6_w[k] = 8'b0;
                end
                `Median_State_Read_1: begin
                    Median_State_w = `Median_State_Read_4;
                    for(k=0; k<3; k=k+1) median_i1_w[k] = (iter_t_edge) ? 8'b0 : Sram_Data_o[k];
                end
                `Median_State_Read_2: begin
                    Median_State_w = `Median_State_Read_5;
                    for(k=0; k<3; k=k+1) median_i2_w[k] = (iter_t_edge) ? 8'b0 : Sram_Data_o[k];
                    
                    if(Iterator_X_r != 2'b01) begin
                        for(k=0; k<3; k=k+1) median_i0_w[k] = median_i1_r[k];
                        for(k=0; k<3; k=k+1) median_i3_w[k] = median_i4_r[k];
                        for(k=0; k<3; k=k+1) median_i6_w[k] = median_i7_r[k];
                        for(k=0; k<3; k=k+1) median_i1_w[k] = median_i2_r[k];
                        for(k=0; k<3; k=k+1) median_i4_w[k] = median_i5_r[k];
                        for(k=0; k<3; k=k+1) median_i7_w[k] = median_i8_r[k];
                    end
                end
                `Median_State_Read_4: begin
                    Median_State_w = `Median_State_Read_7;
                    for(k=0; k<3; k=k+1) median_i4_w[k] = Sram_Data_o[k];

                    Iterator_X_w = Iterator_X_Add_1;
                end
                `Median_State_Read_5: begin
                    Median_State_w = `Median_State_Read_8;
                    for(k=0; k<3; k=k+1) median_i5_w[k] = Sram_Data_o[k];

                    Iterator_X_w = Iterator_X_Add_1;
                end
                `Median_State_Read_7: begin
                    Median_State_w = `Median_State_Read_2;
                    for(k=0; k<3; k=k+1) median_i7_w[k] = (iter_b_edge) ? 8'b0 : Sram_Data_o[k];
                end
                `Median_State_Read_8: begin
                    Median_State_w = `Median_State_Read_2;
                    if(~|Iterator_X_r) Median_State_w = `Median_State_Write_0;
                    for(k=0; k<3; k=k+1) median_i8_w[k] = (iter_b_edge) ? 8'b0 : Sram_Data_o[k];

                    case(Iterator_X_r)
                        3'd3: for(k=0; k<3; k=k+1) median_m0_w[k] = Median[k];
                        3'd4: for(k=0; k<3; k=k+1) median_m1_w[k] = Median[k];
                        3'd5: for(k=0; k<3; k=k+1) median_m2_w[k] = Median[k];
                        3'd6: for(k=0; k<3; k=k+1) median_m3_w[k] = Median[k];
                        3'd7: for(k=0; k<3; k=k+1) median_m4_w[k] = Median[k];
                        3'd0: for(k=0; k<3; k=k+1) median_m5_w[k] = Median[k];
                    endcase
                end
                `Median_State_Write_0: begin
                    Median_State_w = `Median_State_Write_1;
                    for(k=0; k<3; k=k+1) Sram_Data_i[k] = median_m0_r[k];

                    for(k=0; k<3; k=k+1) median_i0_w[k] = median_i1_r[k];
                    for(k=0; k<3; k=k+1) median_i3_w[k] = median_i4_r[k];
                    for(k=0; k<3; k=k+1) median_i6_w[k] = median_i7_r[k];
                    for(k=0; k<3; k=k+1) median_i1_w[k] = median_i2_r[k];
                    for(k=0; k<3; k=k+1) median_i4_w[k] = median_i5_r[k];
                    for(k=0; k<3; k=k+1) median_i7_w[k] = median_i8_r[k];
                    for(k=0; k<3; k=k+1) median_i2_w[k] = 8'b0;
                    for(k=0; k<3; k=k+1) median_i5_w[k] = 8'b0;
                    for(k=0; k<3; k=k+1) median_i8_w[k] = 8'b0;

                    Iterator_X_w = Iterator_X_Add_1;
                end
                `Median_State_Write_1: begin
                    Median_State_w = `Median_State_Write_2;
                    for(k=0; k<3; k=k+1) Sram_Data_i[k] = median_m1_r[k];

                    Iterator_X_w = Iterator_X_Add_1;
                end
                `Median_State_Write_2: begin
                    Median_State_w = `Median_State_Write_3;
                    for(k=0; k<3; k=k+1) Sram_Data_i[k] = median_m2_r[k];

                    for(k=0; k<3; k=k+1) median_m6_w[k] = Median[k];

                    Iterator_X_w = Iterator_X_Add_1;
                end
                `Median_State_Write_3: begin
                    Median_State_w = `Median_State_Write_4;
                    for(k=0; k<3; k=k+1) Sram_Data_i[k] = median_m3_r[k];

                    Iterator_X_w = Iterator_X_Add_1;
                    
                    for(k=0; k<3; k=k+1) median_m7_w[k] = Median[k];
                end
                `Median_State_Write_4: begin
                    Median_State_w = `Median_State_Write_5;
                    for(k=0; k<3; k=k+1) Sram_Data_i[k] = median_m4_r[k];

                    Iterator_X_w = Iterator_X_Add_1;
                end
                `Median_State_Write_5: begin
                    Median_State_w = `Median_State_Write_6;
                    for(k=0; k<3; k=k+1) Sram_Data_i[k] = median_m5_r[k];

                    Iterator_X_w = Iterator_X_Add_1;
                end
                `Median_State_Write_6: begin
                    Median_State_w = `Median_State_Write_7;
                    for(k=0; k<3; k=k+1) Sram_Data_i[k] = median_m6_r[k];

                    Iterator_X_w = Iterator_X_Add_1;
                end
                `Median_State_Write_7: begin
                    Median_State_w = `Median_State_Idle;
                    for(k=0; k<3; k=k+1) Sram_Data_i[k] = median_m7_r[k];
                    
                    Iterator_X_w = Iterator_X_Add_1;
                    Iterator_Y_w = Iterator_Y_r + 3'b1;
                end
            endcase

            Sram_Addr[7:6] = Sram_Addr_Prefix_r;
            Sram_Addr[5:3] = Iterator_Y_r + {Median_State_r[3], Median_State_r[3:2]};
            Sram_Addr[2:0] = Iterator_X_r;
            if(Median_State_r[4:3] == 2'b10) begin
                Sram_Addr[7:6] = Sram_Addr_Prefix_r ^ 2'b1;
                Sram_Addr[5:3] = Iterator_Y_r;
                Sram_Wen = 1'b0;
            end
            o_out_valid_w = (Median_State_r == `Median_State_Write_7) & (&Iterator_Y_r);
            if(o_out_valid_w) Sram_Addr_Prefix_w = Sram_Addr_Prefix_r ^ 2'b1;
        end

        `IPDC_State_RBG: begin
            IPDC_State_w = `IPDC_State_Ready;

            Display_Mode_w = `Display_Mode_RGB;
            o_out_valid_w = 1'b1;
        end

        `IPDC_State_YCbCr: begin
            IPDC_State_w = `IPDC_State_Ready;

            Display_Mode_w = `Display_Mode_YCbCr;
            o_out_valid_w = 1'b1;
        end

    endcase

end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always@(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
        IPDC_State_r                                <= `IPDC_State_Idle;
        Load_State_r                                <= `Load_State_Load;
        Display_State_r                             <= `Display_State_Idle;
        Median_State_r                              <= `Median_State_Idle;
        {Iterator_Y_r, Iterator_X_r}                <= 6'b0;
        {Origin_Y_r, Origin_X_r}                    <= 6'b0;
        {Display_Y_Offset_r, Display_X_Offset_r}    <= 4'b0;
        Sram_Addr_Prefix_r                          <= 2'b0;
        Display_Mode_r                              <= `Display_Mode_RGB;

        for(k=0; k<3; k=k+1) median_i0_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_i1_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_i2_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_i3_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_i4_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_i5_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_i6_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_i7_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_i8_r[k]         <= 8'b0;

        for(k=0; k<3; k=k+1) median_m0_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_m1_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_m2_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_m3_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_m4_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_m5_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_m6_r[k]         <= 8'b0;
        for(k=0; k<3; k=k+1) median_m7_r[k]         <= 8'b0;

        o_out_valid_r                               <= 1'b0;
    end
    else begin
        IPDC_State_r                                <= IPDC_State_w;
        Load_State_r                                <= Load_State_w;
        Display_State_r                             <= Display_State_w;
        Median_State_r                              <= Median_State_w;
        {Iterator_Y_r, Iterator_X_r}                <= {Iterator_Y_w, Iterator_X_w};
        {Origin_Y_r, Origin_X_r}                    <= {Origin_Y_w, Origin_X_w};
        {Display_Y_Offset_r, Display_X_Offset_r}    <= {Display_Y_Offset_w, Display_X_Offset_w};
        Sram_Addr_Prefix_r                          <= Sram_Addr_Prefix_w;
        Display_Mode_r                              <= Display_Mode_w;

        for(k=0; k<3; k=k+1) median_i0_r[k]         <= median_i0_w[k];
        for(k=0; k<3; k=k+1) median_i1_r[k]         <= median_i1_w[k];
        for(k=0; k<3; k=k+1) median_i2_r[k]         <= median_i2_w[k];
        for(k=0; k<3; k=k+1) median_i3_r[k]         <= median_i3_w[k];
        for(k=0; k<3; k=k+1) median_i4_r[k]         <= median_i4_w[k];
        for(k=0; k<3; k=k+1) median_i5_r[k]         <= median_i5_w[k];
        for(k=0; k<3; k=k+1) median_i6_r[k]         <= median_i6_w[k];
        for(k=0; k<3; k=k+1) median_i7_r[k]         <= median_i7_w[k];
        for(k=0; k<3; k=k+1) median_i8_r[k]         <= median_i8_w[k];

        for(k=0; k<3; k=k+1) median_m0_r[k]         <= median_m0_w[k];
        for(k=0; k<3; k=k+1) median_m1_r[k]         <= median_m1_w[k];
        for(k=0; k<3; k=k+1) median_m2_r[k]         <= median_m2_w[k];
        for(k=0; k<3; k=k+1) median_m3_r[k]         <= median_m3_w[k];
        for(k=0; k<3; k=k+1) median_m4_r[k]         <= median_m4_w[k];
        for(k=0; k<3; k=k+1) median_m5_r[k]         <= median_m5_w[k];
        for(k=0; k<3; k=k+1) median_m6_r[k]         <= median_m6_w[k];
        for(k=0; k<3; k=k+1) median_m7_r[k]         <= median_m7_w[k];

        o_out_valid_r                               <=  o_out_valid_w;
    end
end


endmodule
