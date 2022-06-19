package isa;
  /*
   * Defines
   */

  parameter OPCODELEN = 7;
  parameter FUNCT3LEN = 3;
  parameter FUNCT7LEN = 7;

  typedef enum logic [OPCODELEN-1:0] {
    LUI       = 7'b0110111,
    AUIPC     = 7'b0010111,
    JAL       = 7'b1101111,
    JALR      = 7'b1100111,
    BRANCH    = 7'b1100011,
    LOAD      = 7'b0000011,
    STORE     = 7'b0100011,
    OP_IMM_32 = 7'b0010011,
    OP_32     = 7'b0110011,
    MISC_MEM  = 7'b0001111,
    SYSTEM    = 7'b1110011
  } opcode_t;

  typedef enum logic [FUNCT3LEN-1:0] {
    JALR_BEQ_B_ADD_SUB_FENCE_PRIV = 3'b000,
    BNE_H_SL                      = 3'b001,
    W_SLT                         = 3'b010,
    SLTU                          = 3'b011,
    BLT_BU_XOR                    = 3'b100,
    BGE_HU_SR                     = 3'b101,
    BLTU_OR                       = 3'b110,
    BGEU_AND                      = 3'b111
  } funct3_t;

  typedef enum logic [FUNCT7LEN-1:0] {
    SL_ADD_SLT_XOR_OR_AND = 7'b0000000,
    SA_SUB                = 7'b0100000
  } funct7_t;

  parameter ILEN = 32;
  parameter XLEN = 32;
  parameter RCNT = 32;
  parameter RCNT_LOG = $clog2(RCNT);

  typedef enum logic [2:0] {
    R,
    I,
    S,
    B,
    U,
    J
  } fmt_t;

  typedef struct packed {
    funct7_t funct7;
    logic [RCNT_LOG-1:0] rs2;
    logic [RCNT_LOG-1:0] rs1;
    funct3_t funct3;
    logic [RCNT_LOG-1:0] rd;
    opcode_t opcode;
  } rtype_instr_t;

  typedef struct packed {
    logic [11:0] imm11_0;
    logic [RCNT_LOG-1:0] rs1;
    funct3_t funct3;
    logic [RCNT_LOG-1:0] rd;
    opcode_t opcode;
  } itype_instr_t;

  typedef struct packed {
    logic [6:0] imm11_5;
    logic [RCNT_LOG-1:0] rs2;
    logic [RCNT_LOG-1:0] rs1;
    funct3_t funct3;
    logic [4:0] imm4_0;
    opcode_t opcode;
  } stype_instr_t;

  typedef struct packed {
    logic imm12;
    logic [5:0] imm10_5;
    logic [RCNT_LOG-1:0] rs2;
    logic [RCNT_LOG-1:0] rs1;
    funct3_t funct3;
    logic [3:0] imm4_1;
    logic imm11;
    opcode_t opcode;
  } btype_instr_t;

  typedef struct packed {
    logic [19:0] imm31_12;
    logic [RCNT_LOG-1:0] rd;
    opcode_t opcode;
  } utype_instr_t;

  typedef struct packed {
    logic imm20;
    logic [9:0] imm10_1;
    logic imm11;
    logic [7:0] imm19_12;
    logic [RCNT_LOG-1:0] rd;
    opcode_t opcode;
  } jtype_instr_t;

  /* addi x0, x0, 0 */
  parameter opcode_t NOP_OPCODE = OP_IMM_32;
  parameter funct3_t NOP_FUNCT3 = JALR_BEQ_B_ADD_SUB_FENCE_PRIV;
  parameter funct7_t NOP_FUNCT7 = SL_ADD_SLT_XOR_OR_AND; /* it's irrelevant */
  parameter          NOP = 32'h0000_0013;

  typedef enum logic {
    ADDITION,
    SUBTRACTION
  } arithmetic_op_t;

  typedef enum logic {
    UNSIGNED,
    SIGNED
  } sign_t;

  typedef enum logic [1:0] {
    XOR,
    OR,
    AND
  } logical_op_t;

  typedef enum logic {
    LOGICAL,
    ARITHMETIC
  } sh_op_t;

  typedef enum logic {
    LEFT_SHIFT,
    RIGHT_SHIFT
  } sh_dir_t;

  typedef enum logic [1:0] {
    BYTE,
    HALF_WORD,
    WORD
  } mem_access_t;

  /*
   * Functions
   */

  function logic is_sh_imm(
    input opcode_t opcode,
    input funct3_t funct3,
    input funct7_t funct7
  );
    return opcode == OP_IMM_32 &&
           (funct3 == BNE_H_SL || funct3 == BGE_HU_SR) &&
           (funct7 == SL_ADD_SLT_XOR_OR_AND || funct7 == SA_SUB);
  endfunction

  function fmt_t get_fmt(
    input opcode_t opcode
  );
    fmt_t fmt;

    priority case (opcode)
      LUI, AUIPC:                              fmt = U;
      JAL:                                     fmt = J;
      JALR, LOAD, OP_IMM_32, MISC_MEM, SYSTEM: fmt = I;
      BRANCH:                                  fmt = B;
      STORE:                                   fmt = S;
      OP_32:                                   fmt = R;
    endcase

    return fmt;
  endfunction

  function logic [XLEN-1:0] get_imm(
    input [ILEN-1:0] instr,
    input opcode_t opcode,
    input funct3_t funct3,
    input funct7_t funct7,
    input fmt_t fmt
  );
    logic [XLEN-1:0] imm;

    itype_instr_t i;
    stype_instr_t s;
    btype_instr_t b;
    utype_instr_t u;
    jtype_instr_t j;

    priority case (fmt)
      I:
        begin
          i = instr;
          imm = signed'(i.imm11_0);
        end
      S:
        begin
          s = instr;
          imm = signed'({s.imm11_5, s.imm4_0});
        end
      B:
        begin
          b = instr;
          imm = signed'({b.imm12, b.imm11, b.imm10_5, b.imm4_1, 1'b0});
        end
      U:
        begin
          u = instr;
          imm = {u.imm31_12, {12{1'b0}}};
        end
      J:
        begin
          j = instr;
          imm = signed'({j.imm20, j.imm19_12, j.imm11, j.imm10_1, 1'b0});
        end
    endcase

    return is_sh_imm(opcode, funct3, funct7) ? imm[RCNT_LOG-1:0] : imm;
  endfunction

  function logic uses_rd(
    input fmt_t fmt
  );
    return fmt == R || fmt == I || fmt == U || fmt == J;
  endfunction

  function logic uses_rs1(
    input fmt_t fmt
  );
    return fmt == R || fmt == I || fmt == S || fmt == B;
  endfunction

  function logic uses_rs2(
    input fmt_t fmt
  );
    return fmt == R || fmt == S || fmt == B;
  endfunction

  function logic is_arithmetic_op(
    input opcode_t opcode,
    input funct3_t funct3
  );
    return (opcode == OP_IMM_32 || opcode == OP_32) &&
           (funct3 == JALR_BEQ_B_ADD_SUB_FENCE_PRIV);
  endfunction

  function logic is_logical_op(
    input opcode_t opcode,
    input funct3_t funct3,
    input funct7_t funct7
  );
    return (opcode == OP_IMM_32 || (opcode == OP_32 && funct7 == SL_ADD_SLT_XOR_OR_AND)) &&
           (funct3 == BLT_BU_XOR || funct3 == BLTU_OR || funct3 == BGEU_AND);
  endfunction

  function logic is_comparison_op(
    input opcode_t opcode,
    input funct3_t funct3,
    input funct7_t funct7
  );
    return (opcode == OP_IMM_32 || (opcode == OP_32 && funct7 == SL_ADD_SLT_XOR_OR_AND)) &&
           (funct3 == W_SLT || funct3 == SLTU);
  endfunction

  function logic is_shift_op(
    input opcode_t opcode,
    input funct3_t funct3,
    input funct7_t funct7
  );
    return ((opcode == OP_IMM_32 || (opcode == OP_32 && funct7 == SL_ADD_SLT_XOR_OR_AND)) &&
            (funct3 == BNE_H_SL || funct3 == BGE_HU_SR)) ||
           ((opcode == OP_IMM_32 || (opcode == OP_32 && funct7 == SA_SUB)) &&
            (funct3 == BGE_HU_SR));
  endfunction

  function arithmetic_op_t get_arithmetic_op_type(
    input opcode_t opcode,
    input funct7_t funct7
  );
    return (opcode == OP_32 && funct7 == SA_SUB) ? SUBTRACTION : ADDITION;
  endfunction

  function sign_t get_branch_op_sign(
    input funct3_t funct3
  );
    return funct3[1] ? UNSIGNED : SIGNED;
  endfunction

  function logical_op_t get_logical_op_type(
    input funct3_t funct3
  );
    logical_op_t op;

    priority case (funct3)
      BLT_BU_XOR: op = XOR;
      BLTU_OR:    op = OR;
      BGEU_AND:   op = AND;
    endcase

    return op;
  endfunction

  function sign_t get_comparison_op_sign(
    input funct3_t funct3
  );
    return funct3[0] ? UNSIGNED : SIGNED;
  endfunction

  function sh_op_t get_sh_op_type(
    input funct7_t funct7
  );
    return (funct7 == SL_ADD_SLT_XOR_OR_AND) ? LOGICAL : ARITHMETIC;
  endfunction

  function sh_dir_t get_sh_dir(
    input funct3_t funct3
  );
    return (funct3 == BNE_H_SL) ? LEFT_SHIFT : RIGHT_SHIFT;
  endfunction

  function mem_access_t get_mem_access_type(
    input funct3_t funct3
  );
    return mem_access_t'(funct3 & 3'b011);
  endfunction

  function sign_t get_load_op_sign(
    input funct3_t funct3
  );
    return funct3[2] ? UNSIGNED : SIGNED;
  endfunction

endpackage
