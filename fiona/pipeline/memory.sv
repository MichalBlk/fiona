import isa::*;

/*
 * XXX: FTTB, the external memory interface is brazenly simple.
 * It should be replaced by an outright interface to an L1 D$ (e.g. wishbone).
 */

module memory_unit(
  /* Source pipeline register */
  input opcode_t             src_opcode,
  input funct3_t             src_funct3,
  input logic [RCNT_LOG-1:0] src_rd_addr,
  input logic [XLEN-1:0]     src_rd,
  input logic [XLEN-1:0]     src_mem_addr,
  input logic [XLEN-1:0]     src_mem_wr_data,

  /* External data memory */
  input logic             exti_miss,
  input logic [XLEN-1:0]  exti_rd_data,

  output logic            exto_rd_enable,
  output logic            exto_wr_enable,
  output logic [XLEN-1:0] exto_addr,
  output logic [XLEN-1:0] exto_wr_data,
  output mem_access_t     exto_wr_access_type,

  /* Hazard control */
  output logic hazo_miss,

  /* Destination pipeline register */
  output logic [RCNT_LOG-1:0] dst_rd_addr,
  output logic [XLEN-1:0]     dst_rd
);
  mem_access_t access_type;

  assign access_type = get_mem_access_type(src_funct3);

  assign exto_rd_enable = (src_opcode == LOAD);
  assign exto_wr_enable = (src_opcode == STORE);
  assign exto_addr = src_mem_addr;
  assign exto_wr_data = src_mem_wr_data;
  assign exto_wr_access_type = access_type;

  assign hazo_miss = exti_miss;

  assign dst_rd_addr = src_rd_addr;

  /*
   * Loaded data processing.
   */

  sign_t           ld_sign;
  logic [XLEN-1:0] ld_data;
  
  assign ld_sign = get_load_op_sign(src_funct3);

  always_comb
    priority case (access_type)
      BYTE:      ld_data = (ld_sign == SIGNED) ? signed'(exti_rd_data[0+:8]) : exti_rd_data[0+:8];
      HALF_WORD: ld_data = (ld_sign == SIGNED) ? signed'(exti_rd_data[0+:16]) : exti_rd_data[0+:16];
      WORD:      ld_data = exti_rd_data;
    endcase

  assign dst_rd = (src_opcode == LOAD) ? ld_data : src_rd;
endmodule
