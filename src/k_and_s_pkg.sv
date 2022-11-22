package k_and_s_pkg;
  typedef enum  logic [4:0] {
    I_NOP,
    I_LOAD,
    I_STORE,
    I_MOVE,
    I_ADD,
    I_SUB,
    I_AND,
    I_OR,
    I_BRANCH,
    I_BZERO,
    I_BNZERO,
    I_BNEG,
    I_BNNEG,
    I_BOV,
    I_BNOV,
    I_HALT
} decoded_instruction_type;  // Decoded instruction in decode

endpackage : k_and_s_pkg
