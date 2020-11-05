// `include "../sram_256x8/sram_256x8.v"

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
reg     [ ?: 0] IPDC_State_r, IPDC_State_w;
reg     [ 1: 0] Load_State_r, Load_State_w;

wire            Load_Finish;
wire            Display_Finish;

// PIXEL COORDINATE
reg     [ 2: 0] Origin_X_r, Origin_Y_r;
reg     [ 2: 0] Origin_X_w, Origin_Y_w;

reg     [ 1: 0] Display_X_Offset_r, Display_Y_Offset_r;
reg     [ 1: 0] Display_X_Offset_w, Display_Y_Offset_w;

// SRAM
wire    [ 7: 0] Sram_Data_o;
reg     [ 7: 0] Sram_Data_i;
reg     [ 7: 0] Sram_Addr;
wire            Sram_Cen;
reg             Sram_Wen;


// addr: ccxxxyyy
// cc:  channel {00, 01, 10}
// xxx: x coordinate {000, 001,..., 111}
// yyy: y coordinate {000, 001,..., 111}
sram_256x8 u_sram(Sram_Data_o, i_clk, Sram_Cen, Sram_Wen, Sram_Addr, Sram_Data_i);

integer k;

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
assign Sram_Cen     = i_rst_n;

// Load
assign o_in_ready   = (Load_State_r == `Load_State_Idle) | (Load_State_r == `Load_State_C2);
assign Load_Finish  = &({Origin_X_r ,Origin_Y_r}) & (Load_State_r == `Load_State_C2);

//Display


// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //
// Default
always@(*) begin
    Origin_X_w  = Origin_X_r;
    Origin_Y_w  = Origin_Y_r;
    Sram_Data_i = 8'b0;
    Sram_Addr   = 8'b0;
    Sram_Wen    = 1'b0;
end

// STATE
always@(*) begin
    IPDC_State_w = IPDC_State_r;
    Load_State_w = Load_State_r;

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
    endcase
end

// Load
always@(*) begin
    Load_State_w = `Load_State_Idle;
    if(IPDC_State_r == `IPDC_State_Load) begin
        Sram_Addr = {Load_State_r, Origin_X_r, Origin_Y_r};

        if(~i_in_valid) Load_State_w = Load_State_r;
        else begin
            case(Load_State_r)
                `Load_State_Idle: begin
                    Load_State_w    = `Load_State_C0;
                    Origin_X_w      = 3'b0;
                    Origin_Y_w      = 3'b0;
                end
                `Load_State_C0: begin
                    Load_State_w    = `Load_State_C1;
                    Sram_Data_i     = i_in_data[ 7: 0];
                end
                `Load_State_C1: begin
                    Load_State_w    = `Load_State_C2;
                    Sram_Data_i     = i_in_data[15: 8];
                end
                `Load_State_C2: begin
                    Load_State_w    = `Load_State_C0;
                    Sram_Data_i     = i_in_data[23:16];
                    {Origin_Y_w, Origin_X_w} = {Origin_Y_r, Origin_X_r} + 6'b1;
                end
            endcase
        end
    end
end

// Display
always@(*) begin
    
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always@(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
        IPDC_State_r        <= `IPDC_State_Idle;
        Load_State_r        <= `Load_State_Idle;
        Origin_X_r          <= 3'b0;
        Origin_Y_r          <= 3'b0;
        Display_X_Offset_r  <= 2'b0;
        Display_Y_Offset_r  <= 2'b0;
    end
    else begin
        IPDC_State_r    <= IPDC_State_w;
        Load_State_r    <= Load_State_w;
    end
end


endmodule
