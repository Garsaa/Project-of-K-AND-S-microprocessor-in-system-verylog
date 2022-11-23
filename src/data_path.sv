module data_path
import k_and_s_pkg::*;
(
    input  logic                    rst_n,
    input  logic                    clk,
    input  logic                    branch,
    input  logic                    pc_enable,
    input  logic                    ir_enable,
    input  logic                    addr_sel,
    input  logic                    c_sel,
    input  logic              [1:0] operation,
    input  logic                    write_reg_enable,
    input  logic                    flags_reg_enable,
    output decoded_instruction_type decoded_instruction,
    output logic              [4:0] ram_addr,
    output logic             [15:0] data_out,
    input  logic             [15:0] data_in,
    output logic                     reg_zero,
    output logic                     reg_neg,
    output logic                     reg_ov,
    output logic                     reg_sov
    
);
logic [15:0] R0;
logic [15:0] R1;
logic [15:0] R2;
logic [15:0] R3;
logic [4:0] mem_addr;
logic [4:0] program_counter;
logic [15:0] bus_a;
logic [15:0] bus_b;
logic [15:0] bus_c;
logic [15:0] instruction;
logic [1:0] a_addr;
logic [1:0] b_addr;
logic [1:0] c_addr;
logic [15:0] alu_out;
logic zero_f;
logic neg_f;
logic ov_f;
logic sov_f;
logic carry_in_ultimo_bit;
logic [15:0] complemento_bus_b;

always_ff @(posedge clk) begin : ir_ctrl
    if (ir_enable)
        instruction <= data_in;
end

always_ff @(posedge clk or negedge rst_n) begin : pc_ctrl
    if (!rst_n) begin
        program_counter <= 'd0;
    end
    else if (pc_enable) begin
        if (branch)
            program_counter <= mem_addr;
        else
            program_counter <= program_counter + 1;
    end
end

always_ff @(posedge clk) begin : banco_flags
    if (flags_reg_enable) begin
        reg_zero <= zero_f;
        reg_neg <= neg_f;
        reg_ov <= ov_f;
        reg_sov <= sov_f;
    end
end

always_comb begin : ula_ctrl
   assign  complemento_bus_b = (~bus_b) + 1;
    case(operation)
        2'b01: begin // add
            {carry_in_ultimo_bit, alu_out[14:0]} = bus_a[14:0] + bus_b[14:0];
            {ov_f, alu_out[15]} = bus_a[15] + bus_b[15] + carry_in_ultimo_bit;
            sov_f = ov_f ^carry_in_ultimo_bit;
        end
        2'b10: begin // sub
            {carry_in_ultimo_bit, alu_out[14:0]} = bus_a[14:0] + complemento_bus_b[14:0];
            {ov_f, alu_out[15]} = bus_a[15] + complemento_bus_b[15] + carry_in_ultimo_bit;
            sov_f = ov_f ^carry_in_ultimo_bit;        
        end
        2'b11: begin // and
            alu_out = bus_a & bus_b;
            ov_f = 1'b0; // para evitar latches
            sov_f = 1'b0;
            carry_in_ultimo_bit = 1'b0;
        end
        default: begin // or
            alu_out = bus_a | bus_b;
            ov_f = 1'b0; // para evitar latches
            sov_f = 1'b0;
            carry_in_ultimo_bit = 1'b0;
        end
    endcase
    assign zero_f = ~|(alu_out);
    assign neg_f = alu_out[15];
end

always_comb begin : decoder
    a_addr = 'd0;
    b_addr = 'd0;
    c_addr = 'd0;
    mem_addr = 'd0;
    case(instruction[15:8])
        8'b1000_0001 : begin //LOAD
            decoded_instruction = I_LOAD;
            c_addr = instruction[6:5];
            mem_addr = instruction[4:0];       
        end
        8'b1000_0010 : begin //STORE
            decoded_instruction = I_STORE;
            a_addr = instruction[6:5];
            mem_addr = instruction[4:0];        
        end
        8'b1001_0001 : begin //MOVE 
            decoded_instruction = I_MOVE;
            c_addr = instruction[3:2];
            a_addr = instruction[1:0];
            b_addr = instruction[1:0];           
        end
        8'b1010_0001 : begin //ADD
            decoded_instruction = I_ADD;
            a_addr = instruction[1:0];
            b_addr = instruction[3:2];
            c_addr = instruction[5:4];       
        end
        8'b1010_0010 : begin //SUB
            decoded_instruction = I_SUB;
            a_addr = instruction[1:0];
            b_addr = instruction[3:2];
            c_addr = instruction[5:4];        
        end
        8'b1010_0011 : begin //AND
            decoded_instruction = I_AND;
            a_addr = instruction[1:0];
            b_addr = instruction[3:2];
            c_addr = instruction[5:4];        
        end
        8'b1010_0100 : begin //OR
            decoded_instruction = I_OR;
            a_addr = instruction[1:0];
            b_addr = instruction[3:2];
            c_addr = instruction[5:4];                         
        end
        8'b0000_0001 : begin //BRANCH
            decoded_instruction = I_BRANCH;
            mem_addr = instruction[4:0];           
        end
        8'b0000_0010 : begin //BZERO
            decoded_instruction = I_BZERO;
            mem_addr = instruction[4:0];       
        end
        8'b0000_0011 : begin //BNEG
            decoded_instruction = I_BNEG;
            mem_addr = instruction[4:0];       
        end
        8'b0000_0101 : begin //BOV (se o último resultado da ula teve unsigned overflow)
            decoded_instruction = I_BOV;
            mem_addr = instruction[4:0];       
        end
        8'b0000_0110 : begin //BNOV (...sem unsigned overflow)
            decoded_instruction = I_BNOV;
            mem_addr = instruction[4:0];       
        end
        8'b0000_1010 : begin //BNNEG (...não for negativo)
            decoded_instruction = I_BNNEG;
            mem_addr = instruction[4:0];       
        end
        8'b0000_1011 : begin //BNZERO (...não for zero)
            decoded_instruction = I_BNZERO;
            mem_addr = instruction[4:0];       
        end
        8'b1111_1111 : begin //HALT
            decoded_instruction = I_HALT;       
        end
        default: begin //NOP
            decoded_instruction = I_NOP;
        end
    endcase
end


//mux do c_bus
always_comb begin : mux_bus_c
    if(c_sel) bus_c = alu_out;
    else bus_c = data_in;
end



//mux do addr_sel
always_comb begin: mux_addr_sel
  if(addr_sel)
     ram_addr = mem_addr;      
  else
     ram_addr = program_counter;
end



//banco de registradores
always_ff @(posedge clk) begin : register_bank
   
   if(write_reg_enable) begin
       case(c_addr)
         2'b00:
            R0 = bus_c;  
         2'b01:
            R1 = bus_c;  
         2'b10:
            R2 = bus_c;
         2'b11:
            R3 = bus_c;
    endcase
  end
    case(a_addr)
        2'b00:
            bus_a = R0;  
         2'b01:
            bus_a = R1;  
         2'b10:
            bus_a = R2;
         2'b11:
            bus_a = R3;
        endcase
        
    case(b_addr)
         2'b00:
            bus_b = R0;  
         2'b01:
            bus_b = R1;  
         2'b10:
            bus_b = R2;
         2'b11:
            bus_b = R3;  
     endcase
   
  
   
end

  always_comb begin : liga_data_out
     assign data_out = bus_a;
  end


//falta salvar as flags


endmodule : data_path
