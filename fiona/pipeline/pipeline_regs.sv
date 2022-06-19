`include "cfg.svh"

import isa::*;

module fetch_pr(
  input logic clk,
  input logic nrst,

  /* Subsequent values */
  input logic [XLEN-1:0] in_pc,

  /* Hazard control */
  input logic hazi_stall,

  /* Current values */
  output logic [XLEN-1:0] out_pc
);
  logic [XLEN-1:0] pc;

  always_ff @(posedge clk, negedge nrst)
    if (!nrst)
      pc <= `RESETPC;
    else if (!hazi_stall)
      pc <= in_pc;

  assign out_pc = pc;
endmodule

module decode_pr(
  input logic clk,
  input logic nrst,

  /* Subsequent values */
  input logic [XLEN-1:0] in_pc,
  input logic [ILEN-1:0] in_instr,

  /* Hazard control */
  input logic hazi_stall,
  input logic hazi_nop,

  /* Current values */
  output logic [XLEN-1:0] out_pc,
  output logic [ILEN-1:0] out_instr
);
  logic [XLEN-1:0] pc;
  logic [ILEN-1:0] instr;

  always_ff @(posedge clk, negedge nrst)
    if (!nrst)
      begin
        pc <= `RESETPC;
        instr <= NOP;
      end
    else if (hazi_nop)
      instr <= NOP;
    else if (!hazi_stall)
      begin
        pc <= in_pc;
        instr <= in_instr;
      end

  assign out_pc = pc;
  assign out_instr = instr;
endmodule

module execute_pr(
  input logic clk,
  input logic nrst,

  /* Subsequent values */
  input logic [XLEN-1:0]     in_pc,
  input opcode_t             in_opcode,
  input funct3_t             in_funct3,
  input funct7_t             in_funct7,
  input logic [RCNT_LOG-1:0] in_rd_addr,
  input logic [XLEN-1:0]     in_rs1,
  input logic [XLEN-1:0]     in_rs2,
  input logic [XLEN-1:0]     in_imm,

  /* Hazard control */
  input logic hazi_stall,
  input logic hazi_nop,

  /* Current values */
  output logic [XLEN-1:0]     out_pc,
  output opcode_t             out_opcode,
  output funct3_t             out_funct3,
  output funct7_t             out_funct7,
  output logic [RCNT_LOG-1:0] out_rd_addr,
  output logic [XLEN-1:0]     out_rs1,
  output logic [XLEN-1:0]     out_rs2,
  output logic [XLEN-1:0]     out_imm
);
  logic [XLEN-1:0]     pc;
  opcode_t             opcode;
  funct3_t             funct3;
  funct7_t             funct7;
  logic [RCNT_LOG-1:0] rd_addr;
  logic [XLEN-1:0]     rs1;
  logic [XLEN-1:0]     rs2;
  logic [XLEN-1:0]     imm;

  always_ff @(posedge clk, negedge nrst)
    if (!nrst)
      begin
        pc <= `RESETPC;
        opcode <= NOP_OPCODE;
        funct3 <= NOP_FUNCT3;
        funct7 <= NOP_FUNCT7;
        rd_addr <= 0;
        rs1 <= 0;
        rs2 <= 0;
        imm <= 0;
      end
    else if (hazi_nop)
      begin
        opcode <= NOP_OPCODE;
        funct3 <= NOP_FUNCT3;
        funct7 <= NOP_FUNCT7;
        rd_addr <= 0;
      end
    else if (!hazi_stall)
      begin
        pc <= in_pc;
        opcode <= in_opcode;
        funct3 <= in_funct3;
        funct7 <= in_funct7;
        rd_addr <= in_rd_addr;
        rs1 <= in_rs1;
        rs2 <= in_rs2;
        imm <= in_imm;
      end

  assign out_pc = pc;
  assign out_opcode = opcode;
  assign out_funct3 = funct3;
  assign out_funct7 = funct7;
  assign out_rd_addr = rd_addr;
  assign out_rs1 = rs1;
  assign out_rs2 = rs2;
  assign out_imm = imm;
endmodule

module memory_pr(
  input logic clk,
  input logic nrst,

  /* Subsequent values */
  input opcode_t             in_opcode,
  input funct3_t             in_funct3,
  input logic [RCNT_LOG-1:0] in_rd_addr,
  input logic [XLEN-1:0]     in_rd,
  input logic [XLEN-1:0]     in_mem_addr,
  input logic [XLEN-1:0]     in_mem_wr_data,

  /* Hazard control */
  input logic hazi_stall,

  /* Current values */
  output opcode_t             out_opcode,
  output funct3_t             out_funct3,
  output logic [RCNT_LOG-1:0] out_rd_addr,
  output logic [XLEN-1:0]     out_rd,
  output logic [XLEN-1:0]     out_mem_addr,
  output logic [XLEN-1:0]     out_mem_wr_data
);
  opcode_t             opcode;
  funct3_t             funct3;
  logic [RCNT_LOG-1:0] rd_addr;
  logic [XLEN-1:0]     rd;
  logic [XLEN-1:0]     mem_addr;
  logic [XLEN-1:0]     mem_wr_data;

  always_ff @(posedge clk, negedge nrst)
    if (!nrst)
      begin
        opcode <= NOP_OPCODE;
        funct3 <= NOP_FUNCT3;
        rd_addr <= 0;
        rd <= 0;
        mem_addr <= 0;
        mem_wr_data <= 0;
      end
    else if (!hazi_stall)
      begin
        opcode <= in_opcode;
        funct3 <= in_funct3;
        rd_addr <= in_rd_addr;
        rd <= in_rd;
        mem_addr <= in_mem_addr;
        mem_wr_data <= in_mem_wr_data;
      end

  assign out_opcode = opcode;
  assign out_funct3 = funct3;
  assign out_rd_addr = rd_addr;
  assign out_rd = rd;
  assign out_mem_addr = mem_addr;
  assign out_mem_wr_data = mem_wr_data;
endmodule

module writeback_pr(
  input logic clk,
  input logic nrst,

  /* Subsequent values */
  input logic [RCNT_LOG-1:0] in_rd_addr,
  input logic [XLEN-1:0]     in_rd,

  /* Hazard control */
  input logic hazi_nop,

  /* Current values */
  output logic [RCNT_LOG-1:0] out_rd_addr,
  output logic [XLEN-1:0]     out_rd
);
  logic [RCNT_LOG-1:0] rd_addr;
  logic [XLEN-1:0]     rd;

  always_ff @(posedge clk, negedge nrst)
    if (!nrst)
      begin
        rd_addr <= 0;
        rd <= 0;
      end
    else if (hazi_nop)
      rd_addr <= 0;
    else
      begin
        rd_addr <= in_rd_addr;
        rd <= in_rd;
      end

  assign out_rd_addr = rd_addr;
  assign out_rd = rd;
endmodule
