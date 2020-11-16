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
wire    [7:0]   s11_l_w, s11_m_w, s11_h_w;
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