// IPDC STATE
`define IPDC_State_Load         4'd0
`define IPDC_State_ShiftRight   4'd1
`define IPDC_State_ShiftDown    4'd2
`define IPDC_State_Default      4'd3
`define IPDC_State_Zoomin       4'd4
`define IPDC_State_Median       4'd5
`define IPDC_State_YCbCr        4'd6
`define IPDC_State_RBG          4'd7
`define IPDC_State_Idle         4'd8
`define IPDC_State_Ready        4'd9
`define IPDC_State_Display      4'd10

// DISPLAY STATE
`define Display_State_Idle      1'b0
`define Display_State_Display   1'b1

// MEDIAN STATE
`define Median_State_Idle       5'b01100
// `define Median_State_Read_0     5'b00011
`define Median_State_Read_1     5'b00000
`define Median_State_Read_2     5'b00001
// `define Median_State_Read_3     5'b00111
`define Median_State_Read_4     5'b00100
`define Median_State_Read_5     5'b00101
// `define Median_State_Read_6     5'b01100
`define Median_State_Read_7     5'b01101
`define Median_State_Read_8     5'b11111
`define Median_State_Write      5'b10000
`define Median_State_Shift      5'b11101
`define Median_State_Median_0   5'b11000
`define Median_State_Median_1   5'b11001
`define Median_State_Median_2   5'b11010

// DISPLAY MODE
`define Display_Mode_RGB        1'b0
`define Display_Mode_YCbCr      1'b1