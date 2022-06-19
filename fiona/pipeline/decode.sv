import isa::*;

module decode_unit(
  /* Source pipeline register */
  input logic [XLEN-1:0] src_pc,
  input logic [ILEN-1:0] src_instr,

  /* Forwarding */
  input logic [XLEN-1:0]  fwi_rs1,
  input logic [XLEN-1:0]  fwi_rs2,

  output logic [XLEN-1:0] fwo_target_addr,

  /* Hazard control */
  input logic                 hazi_rs1_valid,
  input logic                 hazi_rs2_valid,

  output fmt_t                hazo_fmt,
  output logic [RCNT_LOG-1:0] hazo_rs1_addr,
  output logic [RCNT_LOG-1:0] hazo_rs2_addr,
  output logic                hazo_mispredicted,

  /* Register file */
  input logic [XLEN-1:0]      rfi_rs1,
  input logic [XLEN-1:0]      rfi_rs2,

  output logic [RCNT_LOG-1:0] rfo_rs1_addr,
  output logic [RCNT_LOG-1:0] rfo_rs2_addr,

  /* Destination pipeline register */
  output logic [XLEN-1:0]     dst_pc,
  output opcode_t             dst_opcode,
  output funct3_t             dst_funct3,
  output funct7_t             dst_funct7,
  output logic [RCNT_LOG-1:0] dst_rd_addr,
  output logic [XLEN-1:0]     dst_rs1,
  output logic [XLEN-1:0]     dst_rs2,
  output logic [XLEN-1:0]     dst_imm
);
  fmt_t fmt;

  assign dst_pc = src_pc;

  assign dst_opcode = opcode_t'(src_instr[0+:OPCODELEN]);
  assign dst_funct3 = funct3_t'(src_instr[12+:FUNCT3LEN]);
  assign dst_funct7 = funct7_t'(src_instr[25+:FUNCT7LEN]);

  assign fmt = get_fmt(dst_opcode);
  assign hazo_fmt = fmt;

  assign dst_imm = get_imm(src_instr, dst_opcode, dst_funct3, dst_funct7, fmt);

  /*
   * Register processing.
   */

  assign hazo_rs1_addr = src_instr[15+:RCNT_LOG];
  assign hazo_rs2_addr = src_instr[20+:RCNT_LOG];

  assign rfo_rs1_addr = hazo_rs1_addr;
  assign rfo_rs2_addr = hazo_rs2_addr;

  assign dst_rd_addr = uses_rd(fmt) ? src_instr[7+:RCNT_LOG] : 0;
  assign dst_rs1 = hazi_rs1_valid ? fwi_rs1 : rfi_rs1;
  assign dst_rs2 = hazi_rs2_valid ? fwi_rs2 : rfi_rs2;

  /*
   * Branch/jump processing.
   */

  logic is_branch;
  logic is_jal;
  logic is_jalr;

  logic b_eq;
  logic b_lt;
  logic b_ge;
  logic b_taken;

  logic [XLEN-1:0] b_target;
  logic [XLEN-1:0] j_target;
  logic [XLEN-1:0] jr_target;

  assign is_branch = (dst_opcode == BRANCH);
  assign is_jal = (dst_opcode == JAL);
  assign is_jalr = (dst_opcode == JALR);

  comparator #(
    .LEN (XLEN)
  ) BRANCH_COMPARATOR(
    .sign (get_branch_op_sign(dst_funct3)),
    .src1 (dst_rs1),
    .src2 (dst_rs2),
    .eq   (b_eq),
    .lt   (b_lt),
    .ge   (b_ge)
  );

  assign b_taken = is_branch &&
                   (dst_funct3 == JALR_BEQ_B_ADD_SUB_FENCE_PRIV && b_eq) ||
                   (dst_funct3 == BNE_H_SL && !b_eq) ||
                   ((dst_funct3 == BLT_BU_XOR || dst_funct3 == BLTU_OR) && b_lt) ||
                   ((dst_funct3 == BGE_HU_SR || dst_funct3 == BGEU_AND) && b_ge);

  /* XXX: FTTB, we simply align the offset to 4-byte boundary (no exceptions!). */
  assign b_target = src_pc + {dst_imm[2+:XLEN-2], 2'b00};
  assign j_target = b_target;
  assign jr_target = dst_rs1 + dst_imm;

  assign hazo_mispredicted = (b_taken || is_jal || is_jalr);

  always_comb
    begin
      fwo_target_addr = 'bx;
      unique case (1'b1)
        is_branch: fwo_target_addr = b_target;
        is_jal:    fwo_target_addr = j_target;
        is_jalr:   fwo_target_addr = jr_target;
      endcase
    end
endmodule