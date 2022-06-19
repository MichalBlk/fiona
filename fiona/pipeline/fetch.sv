import isa::*;

/*
 * XXX: FTTB, the external memory interface is brazenly simple.
 * It should be replaced by an outright interface to an L1 I$ (e.g. wishbone).
 */

module fetch_unit(
  /* Source pipeline register */
  input logic [XLEN-1:0] src_pc,

  /* External instruction memory */
  input logic             exti_miss,
  input logic [ILEN-1:0]  exti_data,

  output logic [XLEN-1:0] exto_addr,

  /* Forwarding */
  output logic [XLEN-1:0] fwo_next_pc,

  /* Hazard control */
  output logic hazo_miss,

  /* Destination pipeline register */
  output logic [XLEN-1:0] dst_pc,
  output logic [ILEN-1:0] dst_instr
);
  assign exto_addr = src_pc;

  assign fwo_next_pc = src_pc + 4;

  assign hazo_miss = exti_miss;

  assign dst_pc = src_pc;
  assign dst_instr = exti_data;
endmodule
