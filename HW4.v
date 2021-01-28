module HW4(clk,
            rst_n,
            // for mem_I
            mem_addr_I,
            mem_rdata_I,
			// for result output
			ctrl_signal,
			immediate,
			);

    input         clk, rst_n        ;
    output [31:2] mem_addr_I        ;
    input  [31:0] mem_rdata_I       ;
	output [11:0] ctrl_signal  ;
	output [31:0] immediate;

	// MACRO 
	// state
	parameter IDLE = 1'b0;
	parameter BUSY = 1'b1;

	// instruction type
	parameter R_TYPE = 5'b10000;
	parameter I_TYPE = 5'b01000;
	parameter S_TYPE = 5'b00100;
	parameter B_TYPE = 5'b00010;
	parameter UJ_TYPE = 5'b00001;

	// instruction format
	// R_TYPE
	parameter ADD_FORMAT  = 23'b00000000000000100000000;
	parameter SUB_FORMAT  = 23'b00000000000000010000000;
	parameter SLL_FORMAT  = 23'b00000000000000001000000;
	parameter SLT_FORMAT  = 23'b00000000000000000100000;
	parameter XOR_FORMAT  = 23'b00000000000000000010000;
	parameter SRL_FORMAT  = 23'b00000000000000000001000;
	parameter SRA_FORMAT  = 23'b00000000000000000000100;
	parameter OR_FORMAT   = 23'b00000000000000000000010;
	parameter AND_FORMAT  = 23'b00000000000000000000001;

	// I_TYPE
	parameter JALR_FORMAT = 23'b01000000000000000000000;
	parameter LD_FORMAT   = 23'b00001000000000000000000;
	parameter ADDI_FORMAT = 23'b00000010000000000000000;
	parameter SLLI_FORMAT = 23'b00000000000100000000000;
	parameter SLTI_FORMAT = 23'b00000001000000000000000;
	parameter XORI_FORMAT = 23'b00000000100000000000000;
	parameter SRLI_FORMAT = 23'b00000000000010000000000;
	parameter SRAI_FORMAT = 23'b00000000000001000000000;
	parameter ORI_FORMAT  = 23'b00000000010000000000000;
	parameter ANDI_FORMAT = 23'b00000000001000000000000;

	// S_TYPE
	parameter SD_FORMAT   = 23'b00000100000000000000000;

	// B_TYPE
	parameter BEQ_FORMAT  = 23'b00100000000000000000000;
	parameter BNE_FORMAT  = 23'b00010000000000000000000;

	// UJ_TYPE
	parameter JAL_FORMAT  = 23'b10000000000000000000000;


	// wire/reg declaration
	wire [22:0] next_instruction_type;
	wire [ 4:0] next_instruction_format;
	reg  state, next_state;
	reg  [31:2] mem_addr_I, next_mem_addr_I;
	reg  [11:0] ctrl_signal, next_ctrl_signal;
	reg  [31:0] immediate, next_immediate;
	reg  [22:0] instruction_type;
	reg  [ 4:0] instruction_format;


	// Connect to your HW3 module
	HW3 hw3_submodule(
		clk,
		rst_n, 
		// mem_addr_I,
		mem_rdata_I,
		next_instruction_type,
		next_instruction_format,
		state
	);

// ------------------------------------
//      combinational part
// ------------------------------------

always @ (*) begin
	case(state)
		IDLE: begin
			next_state = 1'd0;
			next_immediate = 32'd0;
			next_ctrl_signal = 12'd0;
			next_mem_addr_I = 30'd0;
		end
		BUSY: begin
			next_mem_addr_I = mem_addr_I + 1'b1;
			case(next_instruction_format)
				R_TYPE: begin
					next_immediate = 32'd0;
					case(next_instruction_type)
						ADD_FORMAT: begin
							next_ctrl_signal = 12'b000000100000;
						end
						SUB_FORMAT:begin
							next_ctrl_signal = 12'b000000101000;
						end
						SLL_FORMAT:begin
							next_ctrl_signal = 12'b000000100001;
						end
						SLT_FORMAT:begin
							next_ctrl_signal = 12'b000000100010;
						end
						XOR_FORMAT:begin
							next_ctrl_signal = 12'b000000100100;
						end
						SRL_FORMAT:begin
							next_ctrl_signal = 12'b000000100101;
						end
						SRA_FORMAT:begin
							next_ctrl_signal = 12'b000000101101;
						end
						OR_FORMAT:begin
							next_ctrl_signal = 12'b000000100110;
						end
						AND_FORMAT:begin
							next_ctrl_signal = 12'b000000100111;
						end
						default: begin
							next_ctrl_signal = 12'b000000000000;
						end
					endcase
				end
				I_TYPE: begin
					next_immediate = { {20{mem_rdata_I[31]}}, mem_rdata_I[31:20] };
					case (next_instruction_type)
						JALR_FORMAT: begin
							next_ctrl_signal = 12'b010000100000;
						end
						LD_FORMAT: begin
							next_ctrl_signal = 12'b000101110000;
						end
						ADDI_FORMAT: begin
							next_ctrl_signal = 12'b000000110000;
						end
						SLLI_FORMAT: begin
							next_ctrl_signal = 12'b000000110001;
						end
						SLTI_FORMAT: begin
							next_ctrl_signal = 12'b000000110010;
						end
						XORI_FORMAT: begin
							next_ctrl_signal = 12'b000000110100;
						end
						SRLI_FORMAT: begin
							next_ctrl_signal = 12'b000000110101;
						end
						SRAI_FORMAT: begin
							next_ctrl_signal = 12'b000000111101;
						end
						ORI_FORMAT: begin
							next_ctrl_signal = 12'b000000110110;
						end
						ANDI_FORMAT: begin
							next_ctrl_signal = 12'b000000110111;
						end

						default:  begin
							next_ctrl_signal = 12'b000000000000;
						end
					endcase
				end
				S_TYPE: begin
					next_immediate = { {20{mem_rdata_I[31]}}, mem_rdata_I[31:25], mem_rdata_I[11:7] };
					// SD_FORMAT
					next_ctrl_signal = 12'b000010010000;
				end
				B_TYPE: begin
					next_immediate = { {19{mem_rdata_I[31]}}, mem_rdata_I[31], mem_rdata_I[7], mem_rdata_I[30:25], mem_rdata_I[11:8], 1'b0 };
					case (next_instruction_type)
						BEQ_FORMAT: begin
							next_ctrl_signal = 12'b001000000000;
						end
						BNE_FORMAT: begin
							next_ctrl_signal = 12'b001000000000;
						end
						default:  begin
							next_ctrl_signal = 12'b000000000000;
						end
					endcase
				end
				UJ_TYPE: begin
					next_immediate = { 12'd0, mem_rdata_I[31], mem_rdata_I[19:12], mem_rdata_I[20], mem_rdata_I[30:21], 1'b0 };
					// JAL_FORMAT
					next_ctrl_signal = 12'b100000100000;
				end
				default: begin
					next_immediate = 32'd0;
					next_ctrl_signal = 12'b000000000000;
				end
			endcase
		end
		default: begin
			next_state = IDLE;
			next_immediate = 32'd0;
			next_ctrl_signal = 12'd0;
		end
	endcase
end

always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state <= IDLE;
		ctrl_signal <= 12'd0;
		immediate <= 32'd0;
		mem_addr_I <= 30'd0;
		instruction_type <= 23'd0;
		instruction_format <= 5'd0;
	end
	else begin
		state <= BUSY;
		ctrl_signal <= next_ctrl_signal;
		immediate <= next_immediate;
		mem_addr_I <= next_mem_addr_I;
		instruction_format <= next_instruction_format;
		instruction_type <= next_instruction_type;
	end
end

endmodule