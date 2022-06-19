import isa::*;

module fiona_core(
  input logic clk,
  input logic nrst,

  /* External instruction memory */
  input logic             i_exti_miss,
  input logic [ILEN-1:0]  i_exti_data,

  output logic [XLEN-1:0] i_exto_addr,

  /* External data memory */
  input logic             d_exti_miss,
  input logic [XLEN-1:0]  d_exti_rd_data,

  output logic            d_exto_rd_enable,
  output logic            d_exto_wr_enable,
  output logic [XLEN-1:0] d_exto_addr,
  output logic [XLEN-1:0] d_exto_wr_data,
  output mem_access_t     d_exto_wr_access_type
);
  /*
   * Fetch pipeline register.
   */

  logic [XLEN-1:0] pr_fi_pc, pr_fo_pc;
  logic            pr_fi_stall;

 fetch_pr FETCH_PR(
    .clk        (clk),
    .nrst       (nrst),
    .in_pc      (pr_fi_pc),
    .hazi_stall (pr_fi_stall),
    .out_pc     (pr_fo_pc)
  );

  /*
   * Decode pipeline register.
   */

  logic [XLEN-1:0] pr_di_pc, pr_do_pc;
  logic [XLEN-1:0] pr_di_instr, pr_do_instr;
  logic            pr_di_stall;
  logic            pr_di_nop;

 decode_pr DECODE_PR(
    .clk        (clk),
    .nrst       (nrst),
    .in_pc      (pr_di_pc),
    .in_instr   (pr_di_instr),
    .hazi_stall (pr_di_stall),
    .hazi_nop   (pr_di_nop),
    .out_pc     (pr_do_pc),
    .out_instr  (pr_do_instr)
  );

  /*
   * Execute pipeline register.
   */

  logic [XLEN-1:0]     pr_ei_pc, pr_eo_pc;
  opcode_t             pr_ei_opcode, pr_eo_opcode;
  funct3_t             pr_ei_funct3, pr_eo_funct3;
  funct7_t             pr_ei_funct7, pr_eo_funct7;
  logic [RCNT_LOG-1:0] pr_ei_rd_addr, pr_eo_rd_addr;
  logic [XLEN-1:0]     pr_ei_rs1, pr_eo_rs1;
  logic [XLEN-1:0]     pr_ei_rs2, pr_eo_rs2;
  logic [XLEN-1:0]     pr_ei_imm, pr_eo_imm;
  logic                pr_ei_stall;
  logic                pr_ei_nop;

 execute_pr EXECUTE_PR(
    .clk         (clk),
    .nrst        (nrst),
    .in_pc       (pr_ei_pc),
    .in_opcode   (pr_ei_opcode),
    .in_funct3   (pr_ei_funct3),
    .in_funct7   (pr_ei_funct7),
    .in_rd_addr  (pr_ei_rd_addr),
    .in_rs1      (pr_ei_rs1),
    .in_rs2      (pr_ei_rs2),
    .in_imm      (pr_ei_imm),
    .hazi_stall  (pr_ei_stall),
    .hazi_nop    (pr_ei_nop),
    .out_pc      (pr_eo_pc),
    .out_opcode  (pr_eo_opcode),
    .out_funct3  (pr_eo_funct3),
    .out_funct7  (pr_eo_funct7),
    .out_rd_addr (pr_eo_rd_addr),
    .out_rs1     (pr_eo_rs1),
    .out_rs2     (pr_eo_rs2),
    .out_imm     (pr_eo_imm)
  );

  /*
   * Memory pipeline register.
   */

  opcode_t             pr_mi_opcode, pr_mo_opcode;
  funct3_t             pr_mi_funct3, pr_mo_funct3;
  logic [RCNT_LOG-1:0] pr_mi_rd_addr, pr_mo_rd_addr;
  logic [XLEN-1:0]     pr_mi_rd, pr_mo_rd;
  logic [XLEN-1:0]     pr_mi_mem_addr, pr_mo_mem_addr;
  logic [XLEN-1:0]     pr_mi_mem_wr_data, pr_mo_mem_wr_data;
  logic                pr_mi_stall;

  memory_pr MEMORY_PR(
    .clk             (clk),
    .nrst            (nrst),
    .in_opcode       (pr_mi_opcode),
    .in_funct3       (pr_mi_funct3),
    .in_rd_addr      (pr_mi_rd_addr),
    .in_mem_addr     (pr_mi_mem_addr),
    .in_mem_wr_data  (pr_mi_mem_wr_data),
    .hazi_stall      (pr_mi_stall),
    .out_opcode      (pr_mo_opcode),
    .out_funct3      (pr_mo_funct3),
    .out_rd_addr     (pr_mo_rd_addr),
    .out_mem_addr    (pr_mo_mem_addr),
    .out_mem_wr_data (pr_mo_mem_wr_data)
  );

  /*
   * Writeback pipeline register.
   */

  logic [RCNT_LOG-1:0] pr_wi_rd_addr, pr_wo_rd_addr;
  logic [XLEN-1:0]     pr_wi_rd, pr_wo_rd;
  logic                pr_wi_nop;

  writeback_pr WRITEBACK_PR(
    .clk         (clk),
    .nrst        (nrst),
    .in_rd_addr  (pr_wi_rd_addr),
    .in_rd       (pr_wi_rd),
    .hazi_nop    (pr_wi_nop),
    .out_rd_addr (pr_wo_rd_addr),
    .out_rd      (pr_wo_rd)
  );

  /*
   * General-purpose register file.
   */

  logic [RCNT_LOG-1:0] rfi_rs1_addr;
  logic [RCNT_LOG-1:0] rfi_rs2_addr;
  logic [RCNT_LOG-1:0] rfi_rd_addr;
  logic [XLEN-1:0]     rfi_rd;
  logic                rfi_wr_enable;

  logic [XLEN-1:0]     rfo_rs1;
  logic [XLEN-1:0]     rfo_rs2;
 
  gprf GPRF(
    .clk       (clk),
    .nrst      (nrst),
    .rs1_addr  (rfi_rs1_addr),
    .rs2_addr  (rfi_rs2_addr),
    .rd_addr   (rfi_rd_addr),
    .rd        (rfi_rd),
    .wr_enable (rfi_wr_enable),
    .rs1       (rfo_rs1),
    .rs2       (rfo_rs2)
  );

  /*
   * Fetch stage.
   */

  logic [XLEN-1:0] fo_next_pc;
  logic            fo_miss;

  fetch_unit FETCH_UNIT(
    .src_pc      (pr_fo_pc),
    .exti_miss   (i_exti_miss),
    .exti_data   (i_exti_data),
    .exto_addr   (i_exto_addr),
    .fwo_next_pc (fo_next_pc),
    .hazo_miss   (fo_miss),
    .dst_pc      (pr_di_pc),
    .dst_instr   (pr_di_instr)
  );

  /*
   * Decode stage.
   */

  logic [XLEN-1:0]     di_rs1;
  logic                di_rs1_valid;
  logic [XLEN-1:0]     di_rs2;
  logic                di_rs2_valid;

  fmt_t                do_fmt;
  logic [RCNT_LOG-1:0] do_rs1_addr;
  logic [RCNT_LOG-1:0] do_rs2_addr;
  logic                do_mispredicted;
  logic [XLEN-1:0]     do_target_addr;

  decode_unit DECODE_UNIT(
    .src_pc            (pr_do_pc),
    .src_instr         (pr_do_instr),
    .fwi_rs1           (di_rs1),
    .fwi_rs2           (di_rs2),
    .fwo_target_addr   (do_target_addr),
    .hazi_rs1_valid    (di_rs1_valid),
    .hazi_rs2_valid    (di_rs2_valid),
    .hazo_fmt          (do_fmt),
    .hazo_rs1_addr     (do_rs1_addr),
    .hazo_rs2_addr     (do_rs2_addr),
    .hazo_mispredicted (do_mispredicted),
    .rfi_rs1           (rfo_rs1),
    .rfi_rs2           (rfo_rs2),
    .rfo_rs1_addr      (rfi_rs1_addr),
    .rfo_rs2_addr      (rfi_rs2_addr),
    .dst_pc            (pr_ei_pc),
    .dst_opcode        (pr_ei_opcode),
    .dst_funct3        (pr_ei_funct3),
    .dst_funct7        (pr_ei_funct7),
    .dst_rd_addr       (pr_ei_rd_addr),
    .dst_rs1           (pr_ei_rs1),
    .dst_rs2           (pr_ei_rs2),
    .dst_imm           (pr_ei_imm)
  );

  /*
   * Execute stage.
   */

  execute_unit EXECUTE_UNIT(
    .src_pc          (pr_eo_pc),
    .src_opcode      (pr_eo_opcode),
    .src_funct3      (pr_eo_funct3),
    .src_funct7      (pr_eo_funct7),
    .src_rd_addr     (pr_eo_rd_addr),
    .src_rs1         (pr_eo_rs1),
    .src_rs2         (pr_eo_rs2),
    .src_imm         (pr_eo_imm),
    .dst_opcode      (pr_mi_opcode),
    .dst_funct3      (pr_mi_funct3),
    .dst_rd_addr     (pr_mi_rd_addr),
    .dst_rd          (pr_mi_rd),
    .dst_mem_addr    (pr_mi_mem_addr),
    .dst_mem_wr_data (pr_mi_mem_wr_data)
  );

  /*
   * Memory stage.
   */

  logic mo_miss;

  memory_unit MEMORY_UNIT(
    .src_opcode           (pr_mi_opcode),
    .src_funct3           (pr_mi_funct3),
    .src_rd_addr          (pr_mi_rd_addr),
    .src_rd               (pr_mi_rd),
    .src_mem_addr         (pr_mi_mem_addr),
    .src_mem_wr_data      (pr_mi_mem_wr_data),
    .exti_miss            (d_exti_miss),
    .exti_rd_data         (d_exti_rd_data),
    .exto_rd_enable       (d_exto_rd_enable),
    .exto_wr_enable       (d_exto_wr_enable),
    .exto_addr            (d_exto_addr),
    .exto_wr_data         (d_exto_wr_data),
    .exto_wr_access_type  (d_exto_wr_access_type),
    .hazo_miss            (mo_miss),
    .dst_rd_addr          (pr_wi_rd_addr),
    .dst_rd               (pr_wi_rd)
  );

  /*
   * Writeback stage.
   */

  writeback_unit WRITEBACK_UNIT(
    .src_rd_addr   (pr_wo_rd_addr),
    .src_rd        (pr_wo_rd),
    .rfo_rd_addr   (rfi_rd_addr),
    .rfo_rd        (rfi_rd),
    .rfo_wr_enable (rfi_wr_enable)
  );

  /*
   * Hazard control.
   */

  hazard_ctrl_unit HAZARD_CONTROL_UNIT(
    .fi_next_pc      (fo_next_pc),
    .fi_miss         (fo_miss),
    .fo_next_pc      (pr_fi_pc),
    .fo_stall        (pr_fi_stall),
    .di_fmt          (do_fmt),
    .di_rs1_addr     (do_rs1_addr),
    .di_rs2_addr     (do_rs2_addr),
    .di_mispredicted (do_mispredicted),
    .di_target_addr  (do_target_addr),
    .do_rs1_valid    (di_rs1_valid),
    .do_rs1          (di_rs1),
    .do_rs2_valid    (di_rs2_valid),
    .do_rs2          (di_rs2),
    .do_stall        (pr_di_stall),
    .do_nop          (pr_di_nop),
    .ei_opcode       (pr_eo_opcode),
    .ei_rd_addr      (pr_eo_rd_addr),
    .ei_rd           (pr_mi_rd),
    .eo_stall        (pr_ei_stall),
    .eo_nop          (pr_ei_nop),
    .mi_rd_addr      (pr_mo_rd_addr),
    .mi_rd           (pr_wo_rd),
    .mi_miss         (mo_miss),
    .mo_stall        (pr_mi_stall),
    .wi_rd_addr      (pr_wo_rd_addr),
    .wi_rd           (rfi_rd),
    .wo_nop          (pr_wi_nop)
  );
endmodule
