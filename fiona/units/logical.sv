import isa::*;

module logical_unit #(
  parameter LEN = 32
)(
  input logical_op_t     op,
  input logic [LEN-1:0]  src1,
  input logic [LEN-1:0]  src2,

  output logic [LEN-1:0] res
);
  always_comb
    priority case (op)
      XOR: res = src1 ^ src2;
      OR:  res = src1 | src2;
      AND: res = src1 & src2;
    endcase
endmodule
