module ycbcr(
    input   [ 7: 0] R,
    input   [ 7: 0] G,
    input   [ 7: 0] B,
    output  [ 7: 0] Y,
    output  [ 7: 0] Cb,
    output  [ 7: 0] Cr
);

wire    [10: 0] Y_;
wire    [10: 0] Cb_;
wire    [10: 0] Cr_;

assign Y_   = {2'b0, R, 1'b0} + {1'b0, G, 2'b0} + {3'b0, G};
assign Y    = Y_[10: 3] + {7'b0, Y_[2]};

assign Cb_  = {1'b1, 10'b0} - {3'b0, R} - {2'b0, G, 1'b0} + {1'b0, B, 2'b0};
assign Cb   = Cb_[10: 3] + {7'b0, Cb_[2]};

assign Cr_  = {1'b1, 10'b0} + {1'b0, R, 2'b0} - {2'b0, G, 1'b0} - {3'b0, G} - {3'b0, B};
assign Cr   = Cr_[10: 3] + {7'b0, Cr_[2]};


endmodule