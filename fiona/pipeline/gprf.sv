import isa::*;

module gprf(
  input logic clk,
  input logic nrst,

  input logic [RCNT_LOG-1:0] rs1_addr,
  input logic [RCNT_LOG-1:0] rs2_addr,
  input logic [RCNT_LOG-1:0] rd_addr,
  input logic [XLEN-1:0]     rd,
  input logic                wr_enable,

  output logic [XLEN-1:0]    rs1,
  output logic [XLEN-1:0]    rs2
);
  logic [RCNT-1:1][XLEN-1:0] gprs;

  always_ff @(posedge clk, negedge nrst)
    if (!nrst)
      begin
        for (integer i = 1; i < RCNT; i++)
          gprs[i] <= 0;
      end
    else if (wr_enable && rd_addr)
      gprs[rd_addr] <= rd;

  assign rs1 = rs1_addr ? gprs[rs1_addr] : 0;
  assign rs2 = rs2_addr ? gprs[rs2_addr] : 0;
endmodule
