import isa::*;

module hazard_ctrl_unit(
  /* Fetch stage */
  input logic [XLEN-1:0]  fi_next_pc,
  input logic             fi_miss,

  output logic [XLEN-1:0] fo_next_pc,

  output logic            fo_stall,

  /* Decode stage */
  input fmt_t                di_fmt,
  input logic [RCNT_LOG-1:0] di_rs1_addr,
  input logic [RCNT_LOG-1:0] di_rs2_addr,
  input logic                di_mispredicted,
  input logic [XLEN-1:0]     di_target_addr,

  output logic               do_rs1_valid,
  output logic [XLEN-1:0]    do_rs1,
  output logic               do_rs2_valid,
  output logic [XLEN-1:0]    do_rs2,

  output logic               do_stall,
  output logic               do_nop,

  /* Execute stage */
  input opcode_t             ei_opcode,
  input logic [RCNT_LOG-1:0] ei_rd_addr,
  input logic [XLEN-1:0]     ei_rd,

  output logic               eo_stall,
  output logic               eo_nop,

  /* Memory stage */
  input logic [RCNT_LOG-1:0] mi_rd_addr,
  input logic [XLEN-1:0]     mi_rd,
  input logic                mi_miss,

  output logic               mo_stall,

  /* Writeback stage */
  input logic [RCNT_LOG-1:0] wi_rd_addr,
  input logic [XLEN-1:0]     wi_rd,

  output logic               wo_nop
);
  /*
   * Fetch stage.
   */

  assign fo_next_pc = di_mispredicted ? di_target_addr : fi_next_pc;
  assign fo_stall = fi_miss || do_stall;

  /*
   * Decode stage.
   */

  logic d_rs1_load_conflict;
  logic d_rs2_load_conflict;
  logic d_uses_rs1;
  logic d_uses_rs2;
  
  assign d_uses_rs1 = uses_rs1(di_fmt);
  assign d_uses_rs2 = uses_rs2(di_fmt);

  always_comb
    begin
      d_rs1_load_conflict = 0;
      d_rs2_load_conflict = 0;

      do_rs1_valid = 0;
      do_rs2_valid = 0;
      do_rs1 = 'bx;
      do_rs2 = 'bx;

      if (d_uses_rs1 && di_rs1_addr)
        begin
          if (ei_rd_addr == di_rs1_addr)
            begin
              d_rs1_load_conflict = (ei_opcode == LOAD);
              do_rs1_valid = 1;
              do_rs1 = ei_rd;
            end
          else if (mi_rd_addr == di_rs1_addr)
            begin
              do_rs1_valid = 1;
              do_rs1 = mi_rd;
            end
          else if (wi_rd_addr == di_rs1_addr)
            begin
              do_rs1_valid = 1;
              do_rs1 = wi_rd;
            end
        end

      if (d_uses_rs2 && di_rs2_addr)
        begin
          if (ei_rd_addr == di_rs2_addr)
            begin
              d_rs1_load_conflict = (ei_opcode == LOAD);
              do_rs2_valid = 1;
              do_rs2 = ei_rd;
            end
          else if (mi_rd_addr == di_rs2_addr)
            begin
              do_rs2_valid = 1;
              do_rs2 = mi_rd;
            end
          else if (wi_rd_addr == di_rs2_addr)
            begin
              do_rs2_valid = 1;
              do_rs2 = wi_rd;
            end
        end
    end

  assign do_stall = d_rs1_load_conflict || d_rs2_load_conflict || mi_miss;
  assign do_nop = fi_miss || di_mispredicted;

  /*
   * Execute stage.
   */

  assign eo_stall = mi_miss;
  assign eo_nop = d_rs1_load_conflict || d_rs2_load_conflict;

  /*
   * Memory stage.
   */

  assign mo_stall = mi_miss;

  /*
   * Writeback stage.
   */

  assign wo_nop = mi_miss;
endmodule
