import isa::*;

module shifter #(
  parameter LEN = 32
)(
  input sh_op_t                 op,
  input sh_dir_t                dir,
  input logic [LEN-1:0]         src,
  input logic [$clog2(LEN)-1:0] amount,

  output logic [LEN-1:0]        res
);
  always_comb
    case (dir)
      LEFT_SHIFT:  res = (src << amount);
      RIGHT_SHIFT: res = (op == LOGICAL) ? (src >> amount) : (src >>> amount);
    endcase
endmodule
