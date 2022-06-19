module comparator #(
  parameter LEN = 32
)(
  input sign_t          sign,
  input logic [LEN-1:0] src1,
  input logic [LEN-1:0] src2,

  output logic          eq,
  output logic          lt,
  output logic          ge
);
  logic src1_msb;
  logic src2_msb;

  assign src1_msb = src1[LEN-1];
  assign src2_msb = src2[LEN-1];

  assign eq = (src1 == src2);
  assign lt = (sign == SIGNED && src1_msb && !src2_msb) ||
              (sign == UNSIGNED && !src1_msb && src2_msb) ||
              ((src1_msb == src2_msb) && (src1[0+:LEN-1] < src2[0+:LEN-1]));
  assign ge = !lt;
endmodule
