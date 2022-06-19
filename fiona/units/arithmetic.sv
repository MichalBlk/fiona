import isa::*;

module arithmetic_unit #(
  parameter LEN = 32
)(
  input arithmetic_op_t  op,
  input logic [LEN-1:0]  src1,
  input logic [LEN-1:0]  src2,

  output logic [LEN-1:0] res
);
  assign res = (op == ADDITION) ? (src1 + src2) : (src1 - src2);
endmodule
