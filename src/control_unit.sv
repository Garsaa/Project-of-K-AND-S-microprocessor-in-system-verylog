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
    output logic                    ram_write_enable,
    output logic                    halt,
    input logic                     reg_zero,
    input logic                     reg_neg,
    input logic                     reg_ov,
    input logic                     reg_sov
);

typedef enum{
    BUSCA_INSTR,
    REG_INSTR,
    DECODIFICAR,
    LOAD_BUSCA_RAM,
    STORE_ESCREVE_RAM,
    ESCREVE_REGISTER,
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
        
        ESCREVE_REGISTER : begin
            flags_reg_enable = 1'b1;
            case(decoded_instruction)
                I_ADD:  operation = 2'b01;
                I_SUB:  operation = 2'b10;
                I_AND:  operation = 2'b11;
                default: operation = 2'b00;
            endcase
            
            write_reg_enable = 1'b1;
            c_sel = 1'b1;
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
                 I_ADD: begin
                    operation = 2'b01;
                    c_sel = 1'b1;
                    next_state = ESCREVE_REGISTER;
                 end
                I_SUB: begin
                    operation = 2'b10;
                    c_sel = 1'b1;
                    next_state = ESCREVE_REGISTER;
                 end
                  I_AND: begin
                    operation = 2'b11;
                    c_sel = 1'b1;
                    next_state = ESCREVE_REGISTER;
                 end
                   I_OR: begin
                    operation = 2'b00;
                    c_sel = 1'b1;
                    next_state = ESCREVE_REGISTER;
                 end
                   I_MOVE: begin //verificar
                    operation = 2'b00;
                    c_sel = 1'b1;
                    next_state = ESCREVE_REGISTER;
                 end
                   I_BRANCH: begin
                        branch = 1'b1;
                        pc_enable = 1'b1;
                        next_state = BUSCA_INSTR;
                        
                 end
                    I_BZERO: begin
                       if(reg_zero) begin
                            branch = 1'b1;
                            pc_enable = 1'b1;
                        end
                        next_state = BUSCA_INSTR;
                   end
                   
                   I_BNEG: begin
                       if(reg_neg) begin
                            branch = 1'b1;
                            pc_enable = 1'b1;
                        end
                        next_state = BUSCA_INSTR;
                   end
                   
                   I_BOV: begin
                       if(reg_ov) begin
                            branch = 1'b1;
                            pc_enable = 1'b1;
                        end
                        next_state = BUSCA_INSTR;
                   end
                   I_BNZERO: begin
                       if(!reg_zero) begin
                            branch = 1'b1;
                            pc_enable = 1'b1;
                        end
                        next_state = BUSCA_INSTR;
                   end
                   
                   I_BNNEG: begin
                       if(!reg_neg) begin
                            branch = 1'b1;
                            pc_enable = 1'b1;
                        end
                        next_state = BUSCA_INSTR;
                   end
                   
                   I_BNOV: begin
                       if(!reg_ov) begin
                            branch = 1'b1;
                            pc_enable = 1'b1;
                        end
                        next_state = BUSCA_INSTR;
                   end
                   
                   
                
             endcase
        end
        
        FIM_PROGRAMA : begin
            halt = 1'b1;
        end
    endcase
end

endmodule : control_unit
