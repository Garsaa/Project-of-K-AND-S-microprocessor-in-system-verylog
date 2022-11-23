package k_and_s_pkg;
  typedef enum  logic [4:0] {
    I_NOP,//ok
    I_LOAD,//ok
    I_STORE,//ok
    I_MOVE,//ok
    I_ADD,//ok
    I_SUB,//ok
    I_AND,//ok
    I_OR,//ok
    I_BRANCH,//ok
    I_BZERO, //ok
    I_BNZERO,//Ok
    I_BNEG,//ok
    I_BNNEG,//ok
    I_BOV,//ok
    I_BNOV,//ok
    I_HALT//ok
} decoded_instruction_type;  // Decoded instruction in decode

endpackage : k_and_s_pkg
