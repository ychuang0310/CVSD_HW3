module median_3(
    input   [7:0] i0, i1, i2,
    output  [7:0] median
);

reg     [7:0] median;

wire    c01 = (i0<i1);
wire    c12 = (i1<i2);
wire    c20 = (i2<i0);

always@(*) begin
    if      (c01 == c20) median = i0;
    else if (c01 == c12) median = i1;
    else if (c12 == c20) median = i2;
end

endmodule



// module median_9(
//     input   [7:0] i0, i1, i2, i3, i4, i5, i6, i7, i8,
//     output  [7:0] median
// );

// reg     [7:0]  median;
// wire    [7:0]  m0, m1, m2;

// median_3 m0(i0, i1, i2, m0);
// median_3 m1(i3, i4, i5, m1);
// median_3 m2(i6, i7, i8, m2);

// median_3 m(m0, m1, m2, median);


// endmodule