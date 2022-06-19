import isa::*;

module writeback_unit(
  /* Source pipeline register */
  input logic [RCNT_LOG-1:0] src_rd_addr,
  input logic [XLEN-1:0]     src_rd,

  /* Register file */
  output logic [RCNT_LOG-1:0] rfo_rd_addr,
  output logic [XLEN-1:0]     rfo_rd,
  output logic                rfo_wr_enable
);
  assign rfo_wr_enable = (src_rd_addr != 0);
  assign rfo_rd_addr = src_rd_addr;
  assign rfo_rd = src_rd;
endmodule
