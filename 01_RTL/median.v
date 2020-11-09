// module median_9(
//     input   [7:0] i0, i1, i2, i3, i4, i5, i6, i7, i8,
//     output  [7:0] median
// );

// reg [7:0] m;

// wire    c01 = (i0<i1);
// wire    c02 = (i0<i2);
// wire    c03 = (i0<i3);
// wire    c04 = (i0<i4);
// wire    c05 = (i0<i5);
// wire    c06 = (i0<i6);
// wire    c07 = (i0<i7);
// wire    c08 = (i0<i8);
// wire    c10 = ~c01;
// wire    c12 = (i1<i2);
// wire    c13 = (i1<i3);
// wire    c14 = (i1<i4);
// wire    c15 = (i1<i5);
// wire    c16 = (i1<i6);
// wire    c17 = (i1<i7);
// wire    c18 = (i1<i8);
// wire    c20 = ~c02;
// wire    c21 = ~c12;
// wire    c23 = (i2<i3);
// wire    c24 = (i2<i4);
// wire    c25 = (i2<i5);
// wire    c26 = (i2<i6);
// wire    c27 = (i2<i7);
// wire    c28 = (i2<i8);
// wire    c30 = ~c03;
// wire    c31 = ~c13;
// wire    c32 = ~c23;
// wire    c34 = (i3<i4);
// wire    c35 = (i3<i5);
// wire    c36 = (i3<i6);
// wire    c37 = (i3<i7);
// wire    c38 = (i3<i8);
// wire    c40 = ~c04;
// wire    c41 = ~c14;
// wire    c42 = ~c24;
// wire    c43 = ~c34;
// wire    c45 = (i4<i5);
// wire    c46 = (i4<i6);
// wire    c47 = (i4<i7);
// wire    c48 = (i4<i8);
// wire    c50 = ~c05;
// wire    c51 = ~c15;
// wire    c52 = ~c25;
// wire    c53 = ~c35;
// wire    c54 = ~c45;
// wire    c56 = (i5<i6);
// wire    c57 = (i5<i7);
// wire    c58 = (i5<i8);
// wire    c60 = ~c06;
// wire    c61 = ~c16;
// wire    c62 = ~c26;
// wire    c63 = ~c36;
// wire    c64 = ~c46;
// wire    c65 = ~c56;
// wire    c67 = (i6<i7);
// wire    c68 = (i6<i8);
// wire    c70 = ~c07;
// wire    c71 = ~c17;
// wire    c72 = ~c27;
// wire    c73 = ~c37;
// wire    c74 = ~c47;
// wire    c75 = ~c57;
// wire    c76 = ~c67;
// wire    c78 = (i7<i8);
// wire    c80 = ~c08;
// wire    c81 = ~c18;
// wire    c82 = ~c28;
// wire    c83 = ~c38;
// wire    c84 = ~c48;
// wire    c85 = ~c58;
// wire    c86 = ~c68;
// wire    c87 = ~c78;

// assign median = m;

// always@(*) begin
//     m = 8'b0;
//     if     (({2'b0, c01} + {2'b0, c02} + {2'b0, c03} + {2'b0, c04} + {2'b0, c05} + {2'b0, c06} + {2'b0, c07} + {2'b0, c08}) == 3'd4) m = i0;
//     else if(({2'b0, c10} + {2'b0, c12} + {2'b0, c13} + {2'b0, c14} + {2'b0, c15} + {2'b0, c16} + {2'b0, c17} + {2'b0, c18}) == 3'd4) m = i1;
//     else if(({2'b0, c20} + {2'b0, c21} + {2'b0, c23} + {2'b0, c24} + {2'b0, c25} + {2'b0, c26} + {2'b0, c27} + {2'b0, c28}) == 3'd4) m = i2;
//     else if(({2'b0, c30} + {2'b0, c31} + {2'b0, c32} + {2'b0, c34} + {2'b0, c35} + {2'b0, c36} + {2'b0, c37} + {2'b0, c38}) == 3'd4) m = i3;
//     else if(({2'b0, c40} + {2'b0, c41} + {2'b0, c42} + {2'b0, c43} + {2'b0, c45} + {2'b0, c46} + {2'b0, c47} + {2'b0, c48}) == 3'd4) m = i4;
//     else if(({2'b0, c50} + {2'b0, c51} + {2'b0, c52} + {2'b0, c53} + {2'b0, c54} + {2'b0, c56} + {2'b0, c57} + {2'b0, c58}) == 3'd4) m = i5;
//     else if(({2'b0, c60} + {2'b0, c61} + {2'b0, c62} + {2'b0, c63} + {2'b0, c64} + {2'b0, c65} + {2'b0, c67} + {2'b0, c68}) == 3'd4) m = i6;
//     else if(({2'b0, c70} + {2'b0, c71} + {2'b0, c72} + {2'b0, c73} + {2'b0, c74} + {2'b0, c75} + {2'b0, c76} + {2'b0, c78}) == 3'd4) m = i7;
//     else if(({2'b0, c80} + {2'b0, c81} + {2'b0, c82} + {2'b0, c83} + {2'b0, c84} + {2'b0, c85} + {2'b0, c86} + {2'b0, c87}) == 3'd4) m = i8;
// end

// endmodule


module sort_3(
    input   [7:0]   i0, i1, i2,
    output  [7:0]   L, M, H
);

reg     [7:0]   c0_l, c0_h;
reg     [7:0]   c1_l, c1_h;
reg     [7:0]   c2_l, c2_h;

assign L = c2_l;
assign M = c2_h;
assign H = c1_h;

always@(*) begin
    c0_l = i0;
    c0_h = i1;
    if(i1 < i0) begin
        c0_l = i1;
        c0_h = i0;
    end

    c1_l = c0_h;
    c1_h = i2;
    if(i2 < c0_h) begin
        c1_l = i2;
        c1_h = c0_h;
    end

    c2_l = c0_l;
    c2_h = c1_l;
    if(c1_l < c0_l) begin
        c2_l = c1_l;
        c2_h = c0_l;
    end
end

endmodule


module median_9(
    input   clk,
    input   rst_n,
    input   [7:0]   i0, i1, i2, i3, i4, i5, i6, i7, i8,
    output  [7:0]   median
);

reg     [7:0]   s00_l_r, s00_m_r, s00_h_r;
wire    [7:0]   s00_l_w, s00_m_w, s00_h_w;
reg     [7:0]   s01_l_r, s01_m_r, s01_h_r;
wire    [7:0]   s01_l_w, s01_m_w, s01_h_w;
reg     [7:0]   s02_l_r, s02_m_r, s02_h_r;
wire    [7:0]   s02_l_w, s02_m_w, s02_h_w;

reg     [7:0]   s10_h_r;
wire    [7:0]   s10_l_w, s10_m_w, s10_h_w;
reg     [7:0]   s11_m_r;
wire    [7:0]   s11_l_w, s11_m_w, s10_1_w;
reg     [7:0]   s12_l_r;
wire    [7:0]   s12_l_w, s12_m_w, s12_h_w;

wire    [7:0]   s20_l_w, s20_m_w, s20_h_w;

sort_3  s00(i0, i1, i2, s00_l_w, s00_m_w, s00_h_w);
sort_3  s01(i3, i4, i5, s01_l_w, s01_m_w, s01_h_w);
sort_3  s02(i6, i7, i8, s02_l_w, s02_m_w, s02_h_w);

sort_3  s10(s00_l_r, s01_l_r, s02_l_r, s10_l_w, s10_m_w, s10_h_w);
sort_3  s11(s00_m_r, s01_m_r, s02_m_r, s11_l_w, s11_m_w, s11_h_w);
sort_3  s12(s00_h_r, s01_h_r, s02_h_r, s12_l_w, s12_m_w, s12_h_w);

sort_3  s20(s10_h_r, s11_m_r, s12_l_r, s20_l_w, s20_m_w, s20_h_w);

assign  median = s20_m_w;

always@(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        s00_l_r <= 8'b0;
        s00_m_r <= 8'b0;
        s00_h_r <= 8'b0;
        s01_l_r <= 8'b0;
        s01_m_r <= 8'b0;
        s01_h_r <= 8'b0;
        s02_l_r <= 8'b0;
        s02_m_r <= 8'b0;
        s02_h_r <= 8'b0;

        s10_h_r <= 8'b0;
        s11_m_r <= 8'b0;
        s12_l_r <= 8'b0;
    end
    else begin
        s00_l_r <= s00_l_w;
        s00_m_r <= s00_m_w;
        s00_h_r <= s00_h_w;
        s01_l_r <= s01_l_w;
        s01_m_r <= s01_m_w;
        s01_h_r <= s01_h_w;
        s02_l_r <= s02_l_w;
        s02_m_r <= s02_m_w;
        s02_h_r <= s02_h_w;
        
        s10_h_r <= s10_h_w;
        s11_m_r <= s11_m_w;
        s12_l_r <= s12_l_w;
    end
end

endmodule