import isa::*;

module execute_unit(
  /* Source pipeline register */
  input logic [XLEN-1:0]     src_pc,
  input opcode_t             src_opcode,
  input funct3_t             src_funct3,
  input funct7_t             src_funct7,
  input logic [RCNT_LOG-1:0] src_rd_addr,
  input logic [XLEN-1:0]     src_rs1,
  input logic [XLEN-1:0]     src_rs2,
  input logic [XLEN-1:0]     src_imm,

  /* Destination pipeline register */
  output opcode_t             dst_opcode,
  output funct3_t             dst_funct3,
  output logic [RCNT_LOG-1:0] dst_rd_addr,
  output logic [XLEN-1:0]     dst_rd,
  output logic [XLEN-1:0]     dst_mem_addr,
  output logic [XLEN-1:0]     dst_mem_wr_data
);
  assign dst_opcode = src_opcode;
  assign dst_funct3 = src_funct3;
  assign dst_rd_addr = src_rd_addr;

  logic [XLEN-1:0] src1;
  logic [XLEN-1:0] src2;

  /*
   * Arithmetic unit.
   */

  arithmetic_op_t  arith_op;
  logic [XLEN-1:0] arith_res;

  arithmetic_unit #(
    .LEN (XLEN)
  ) ARITHMETIC_UNIT(
    .op   (arith_op),
    .src1 (src1),
    .src2 (src2),
    .res  (arith_res)
  );

  /*
   * Logical unit.
   */

  logical_op_t     logical_op;
  logic [XLEN-1:0] logical_res;

  logical_unit #(
    .LEN (XLEN)
  ) LOGICAL_UNIT(
    .op   (logical_op),
    .src1 (src1),
    .src2 (src2),
    .res  (logical_res)
  );

  /*
   * Comparison unit.
   */

  sign_t cmp_sign;
  logic  cmp_lt;

  comparator #(
    .LEN (XLEN)
  ) COMPARATOR_UNIT(
    .sign (cmp_sign),
    .src1 (src1),
    .src2 (src2),
    .lt   (cmp_lt)
  );

  /*
   * Shift unit.
   */

  sh_op_t          sh_op;
  sh_dir_t         sh_dir;
  logic [XLEN-1:0] sh_res;

  shifter #(
    .LEN (XLEN)
  ) SHIFTER_UNIT(
    .op     (sh_op),
    .dir    (sh_dir),
    .src    (src1),
    .amount (src2[0+:$clog2(XLEN)]),
    .res    (sh_res)
  );

  /*
   * Operation processing.
   */

  always_comb
    begin
      src1 = 'bx;
      src2 = 'bx;
      arith_op = ADDITION;
      logical_op = logical_op_t'('bx);
      cmp_sign = sign_t'('bx);
      sh_op = sh_op_t'('bx);
      sh_dir = sh_dir_t'('bx);

      dst_rd = arith_res;
      dst_mem_addr = arith_res;
      dst_mem_wr_data = (src_opcode == STORE) ? src_rs2 : 'bx;

      unique case (1'b1)

        (src_opcode == LUI):
          begin
            dst_rd = src_imm;
          end

        /*
         * Arithmetic operations.
         */

        (src_opcode == AUIPC):
          begin
            src1 = src_pc;
            src2 = src_imm;
          end

        (src_opcode == JAL), (src_opcode == JALR):
          begin
            src1 = src_pc;
            src2 = 4;
          end

        (src_opcode == LOAD), (src_opcode == STORE):
          begin
            src1 = src_rs1;
            src2 = src_imm;
          end

        is_arithmetic_op(src_opcode, src_funct3):
          begin
            arith_op = get_arithmetic_op_type(src_opcode, src_funct7);
            src1 = src_rs1;
            src2 = (src_opcode == OP_IMM_32) ? src_imm : src_rs1;
          end

        /*
         * Logical operations.
         */

        is_logical_op(src_opcode, src_funct3, src_funct7):
          begin
            logical_op = get_logical_op_type(src_funct3);
            src1 = src_rs1;
            src2 = (src_opcode == OP_IMM_32) ? src_imm : src_rs2;
            dst_rd = logical_res;
          end

        /*
         * Comparison operations.
         */

        is_comparison_op(src_opcode, src_funct3, src_funct7):
          begin
            cmp_sign = get_comparison_op_sign(src_funct3);
            src1 = src_rs1;
            src2 = (src_opcode == OP_IMM_32) ? src_imm : src_rs2;
            dst_rd = XLEN'(cmp_lt);
          end

        /*
         * Shift operations.
         */

        is_shift_op(src_opcode, src_funct3, src_funct7):
          begin
            sh_op = get_sh_op_type(src_funct7);
            sh_dir = get_sh_dir(src_funct3);
            src1 = src_rs1;
            src2 = (src_opcode == OP_IMM_32) ? src_imm : src_rs2;
            dst_rd = sh_res;
          end
      endcase
    end
endmodule
