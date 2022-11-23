//control unit
module control_unit
import k_and_s_pkg::*;
(
    input  logic                    rst_n,
    input  logic                    clk,
    output logic                    branch,
    output logic                    pc_enable,
    output logic                    ir_enable,
    output logic                    write_reg_enable,
    output logic                    addr_sel,
    output logic                    c_sel,
    output logic              [1:0] operation,
    output logic                    flags_reg_enable,
    input  decoded_instruction_type decoded_instruction,
    input  logic                    zero_op,
    input  logic                    neg_op,
    input  logic                    unsigned_overflow,
    input  logic                    signed_overflow,
    output logic                    ram_write_enable,
    output logic                    halt
);

typedef enum{
    BUSCA_INSTR,
    REG_INSTR,
    DECODIFICAR,
    LOAD_BUSCA_RAM,
    STORE_ESCREVE_RAM,
    FIM_PROGRAMA
} state_t;

state_t state;
state_t next_state;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= BUSCA_INSTR;
    else
        state = next_state;
end

always_comb begin : calc_next_state 
    branch = 1'b0; // valores default
    pc_enable = 1'b0;
    ir_enable = 1'b0;
    write_reg_enable = 1'b0;
    addr_sel = 1'b0;
    c_sel = 1'b0;
    operation = 2'b0;
    flags_reg_enable = 1'b0;
    ram_write_enable = 1'b0;
    halt  = 1'b0;
    case(state)
        BUSCA_INSTR : begin
            next_state = REG_INSTR;
        end
        REG_INSTR: begin
            ir_enable = 1'b1;
            pc_enable = 1'b1;
            
           next_state = DECODIFICAR;
        end
        LOAD_BUSCA_RAM : begin
            ir_enable = 1'b0;
            c_sel = 'b0;
            write_reg_enable = 1'b1;
           next_state = BUSCA_INSTR;
        end
        
        STORE_ESCREVE_RAM : begin
            addr_sel = 1'b1;
            ram_write_enable = 1'b1;
            ir_enable = 1'b0;
            next_state = BUSCA_INSTR;                  
        end
        
        DECODIFICAR: begin
            next_state = BUSCA_INSTR;
            case(decoded_instruction)        
                I_HALT : begin          
                    next_state = FIM_PROGRAMA;
                end
                I_LOAD: begin              
                    addr_sel = 1'b1;
                    next_state = LOAD_BUSCA_RAM;
                 end
                I_STORE: begin
                    addr_sel = 1'b1;
                    next_state = STORE_ESCREVE_RAM;
                end
             endcase
        end
        
        FIM_PROGRAMA : begin
            halt = 1'b1;
        end
        
        
        
    endcase
end

endmodule : control_unit
