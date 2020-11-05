// OP
// `define OP_Load             3'd0
// `define OP_ShiftRight       3'd1
// `define OP_ShiftDown        3'd2
// `define OP_Default          3'd3
// `define OP_Zoomin           3'd4
// `define OP_Median           3'd5
// `define OP_YCbCr            3'd6
// `define OP_RGB              3'd7

// IPDC STATE
`define IPDC_State_Idle         4'd8
`define IPDC_State_Ready        4'd9
`define IPDC_State_Load         4'd0
`define IPDC_State_ShiftRight   4'd1
`define IPDC_State_ShiftDown    4'd2
`define IPDC_State_Default      4'd3
`define IPDC_State_Zoomin       4'd4
`define IPDC_State_Median       4'd5
`define IPDC_State_YCbCr        4'd6
`define IPDC_State_RBG          4'd7

// LOAD STATE
// Channel (0, 1, 2) = (R/Y, G/Cb, B/Cr)
`define Load_State_Idle     2'd3
`define Load_State_C0       2'd0
`define Load_State_C1       2'd1
`define Load_State_C2       2'd2


// DISPLAY STATE
`define Display_State_Idle  2'd3
`define Display_State_C0    2'd0
`define Display_State_C1    2'd1
`define Display_State_C2    2'd2


// DISPLAY MODE
`define Display_RGB         1'b0
`define Display_YCbCr       1'b1