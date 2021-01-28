module HW3( clk,
            rst_n,
            // for mem_I
            // mem_addr_I,
            mem_rdata_I,
			// for result output
			instruction_type,
			instruction_format,

            state
			);

    input state;
    input         clk, rst_n        ;
    // output [31:2] mem_addr_I        ;
    input  [31:0] mem_rdata_I       ;
	output [22:0] instruction_type  ;
	output [ 4:0] instruction_format;

    // reg [31:2] mem_addr_I, next_mem_addr_I;
    reg [22:0] instruction_type, next_instruction_type;
    reg [ 4:0] instruction_format, next_instruction_format;

// MACRO 
    parameter IDLE = 1'b0;
    parameter BUSY = 1'b1;

// wire/reg declaration
    // reg state, next_state;


// ------------------------------------
//      combinational part
// ------------------------------------

always @ (*) begin
    case(state)
        IDLE: begin
            // next_mem_addr_I = 30'd0;
            next_instruction_type = 23'd0;
            next_instruction_format = 5'd0;
        end
        BUSY: begin
            case (mem_rdata_I[6:0]) // opcode
                7'b1101111: begin // jal
                    next_instruction_format = 5'b00001;
                    next_instruction_type = 23'b10000000000000000000000;
                    // next_mem_addr_I = mem_addr_I + 1'b1;
                end
                7'b1100111: begin // jalr
                    next_instruction_format = 5'b01000;
                    next_instruction_type = 23'b01000000000000000000000;
                    // next_mem_addr_I = mem_addr_I + 1'b1;
                end
                7'b1100011: begin 
                    case (mem_rdata_I[14:12])
                        3'b000: begin // beq
                            next_instruction_format = 5'b00010;
                            next_instruction_type = 23'b00100000000000000000000;
                            // next_mem_addr_I = mem_addr_I + 1'b1;
                        end
                        3'b001: begin // bne
                            next_instruction_format = 5'b00010;
                            next_instruction_type = 23'b00010000000000000000000;
                            // next_mem_addr_I = mem_addr_I + 1'b1;
                        end
                        default: begin
                            // next_mem_addr_I = 30'd0;
                            next_instruction_type = 23'd0;
                            next_instruction_format = 5'd0;
                        end
                    endcase
                end
                7'b0000011: begin // ld
                    next_instruction_format = 5'b01000;
                    next_instruction_type = 23'b00001000000000000000000;
                    // next_mem_addr_I = mem_addr_I + 1'b1;
                end
                7'b0100011: begin // sd
                    next_instruction_format = 5'b00100;
                    next_instruction_type = 23'b00000100000000000000000;
                    // next_mem_addr_I = mem_addr_I + 1'b1;
                end
                7'b0010011: begin
                    case(mem_rdata_I[14:12])
                        3'b000: begin // addi
                            next_instruction_format = 5'b01000;
                            next_instruction_type = 23'b00000010000000000000000;
                            // next_mem_addr_I = mem_addr_I + 1'b1;
                        end
                        3'b001: begin // slli
                            next_instruction_format = 5'b01000;
                            next_instruction_type = 23'b00000000000100000000000;
                            // next_mem_addr_I = mem_addr_I + 1'b1;
                        end
                        3'b010: begin // slti
                            next_instruction_format = 5'b01000;
                            next_instruction_type = 23'b00000001000000000000000;
                            // next_mem_addr_I = mem_addr_I + 1'b1;
                        end
                        3'b100: begin // xori
                            next_instruction_format = 5'b01000;
                            next_instruction_type = 23'b00000000100000000000000;
                            // next_mem_addr_I = mem_addr_I + 1'b1;
                        end
                        3'b101: begin
                            case (mem_rdata_I[31:25])
                                7'b0000000: begin // srli
                                    next_instruction_format = 5'b01000;
                                    next_instruction_type = 23'b00000000000010000000000;
                                    // next_mem_addr_I = mem_addr_I + 1'b1;
                                end
                                7'b0100000: begin // srai
                                    next_instruction_format = 5'b01000;
                                    next_instruction_type = 23'b00000000000001000000000;
                                    // next_mem_addr_I = mem_addr_I + 1'b1;
                                end
                                default: begin
                                    next_instruction_type = 23'd0;
                                    next_instruction_format = 5'd0;
                                    // next_mem_addr_I = 30'd0;
                                end
                            endcase
                        end
                        3'b110: begin // ori
                            next_instruction_format = 5'b01000;
                            next_instruction_type = 23'b00000000010000000000000;
                            // next_mem_addr_I = mem_addr_I + 1'b1;
                        end
                        3'b111: begin // andi
                            next_instruction_format = 5'b01000;
                            next_instruction_type = 23'b00000000001000000000000;
                            // next_mem_addr_I = mem_addr_I + 1'b1;
                        end
                        default: begin
                            next_instruction_type = 23'd0;
                            next_instruction_format = 5'd0;
                            // next_mem_addr_I = 30'd0;
                        end
                    endcase
                end
                7'b0110011: begin 
                    case (mem_rdata_I[14:12])
                        3'b000: begin
                            case (mem_rdata_I[31:25])
                                7'b0000000: begin // add
                                    next_instruction_format = 5'b10000;
                                    next_instruction_type = 23'b00000000000000100000000;
                                    // next_mem_addr_I = mem_addr_I + 1'b1;
                                end
                                7'b0100000: begin // sub
                                    next_instruction_format = 5'b10000;
                                    next_instruction_type = 23'b00000000000000010000000;
                                    // next_mem_addr_I = mem_addr_I + 1'b1;
                                end
                                default: begin
                                    // next_mem_addr_I = 30'd0;
                                    next_instruction_type = 23'd0;
                                    next_instruction_format = 5'd0;
                                end
                            endcase
                        end
                        3'b001: begin // sll
                            next_instruction_format = 5'b10000;
                            next_instruction_type = 23'b00000000000000001000000;
                            // next_mem_addr_I = mem_addr_I + 1'b1;
                        end
                        3'b010: begin // slt
                            next_instruction_format = 5'b10000;
                            next_instruction_type = 23'b00000000000000000100000;
                            // next_mem_addr_I = mem_addr_I + 1'b1;
                        end
                        3'b100: begin // xor
                            next_instruction_format = 5'b10000;
                            next_instruction_type = 23'b00000000000000000010000;
                            // next_mem_addr_I = mem_addr_I + 1'b1;
                        end
                        3'b101: begin
                            case (mem_rdata_I[31:25])
                                7'b0000000: begin // srl
                                    next_instruction_format = 5'b10000;
                                    next_instruction_type = 23'b00000000000000000001000;
                                    // next_mem_addr_I = mem_addr_I + 1'b1;
                                end
                                7'b0100000: begin // sra
                                    next_instruction_format = 5'b10000;
                                    next_instruction_type = 23'b00000000000000000000100;
                                    // next_mem_addr_I = mem_addr_I + 1'b1;
                                end
                                default: begin
                                    // next_mem_addr_I = 30'd0;
                                    next_instruction_type = 23'd0;
                                    next_instruction_format = 5'd0;
                                end
                            endcase
                        end
                        3'b110: begin // or
                            next_instruction_format = 5'b10000;
                            next_instruction_type = 23'b00000000000000000000010;
                            // next_mem_addr_I = mem_addr_I + 1'b1;
                        end
                        3'b111: begin // and
                            next_instruction_format = 5'b10000;
                            next_instruction_type = 23'b00000000000000000000001;
                            // next_mem_addr_I = mem_addr_I + 1'b1;
                        end
                        default: begin
                            // next_mem_addr_I = 30'd0;
                            next_instruction_type = 23'd0;
                            next_instruction_format = 5'd0;
                        end
                    endcase
                end
                default: begin
                    // next_mem_addr_I = 30'd0;
                    next_instruction_type = 23'd0;
                    next_instruction_format = 5'd0;
                end
            endcase
        end
        default: begin
            // next_mem_addr_I = 30'd0;
            next_instruction_type = 23'd0; 
            next_instruction_format = 5'd0;
        end
    endcase
    instruction_type = next_instruction_type;
    instruction_format = next_instruction_format;
    // mem_addr_I = next_mem_addr_I;
end

// ------------------------------------
//      sequential part
// ------------------------------------


// always @ (posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         state <= IDLE;
//         instruction_format <= 5'd0;
//         instruction_type <= 23'd0;
//         mem_addr_I <= 30'd0;
//     end
//     else begin
//         state <= BUSY;
//         instruction_format <= next_instruction_format;
//         instruction_type <= next_instruction_type;
//         mem_addr_I <= next_mem_addr_I;
//     end
// end

endmodule
