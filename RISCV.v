// Your code

module RISCV(
  clk,          // I  posedge
  rst_n,        // I  active low asynchronous
  // for mem_D
  mem_wen_D,    // O  write-enable, set high to write data into memory
  mem_addr_D,   // O  output address of data memory
  mem_wdata_D,  // O  data store to data memory
  mem_rdata_D,  // I  data read from data memory
  // for mem_I
  mem_addr_I,   // O  output address of instruction memory
  mem_rdata_I   // I  instruction read from instruction memory
);
input         clk, rst_n;

// for data memory
output        mem_wen_D;
output [29:0] mem_addr_D;
output [63:0] mem_wdata_D;
input  [63:0] mem_rdata_D;

// for instruction memory
output [29:0] mem_addr_I;
input  [31:0] mem_rdata_I;

// ------------------------------------
//               MACRO
// ------------------------------------
parameter REG_AMOUNT = 32;

// ------------------------------------
//             reg & wire
// ------------------------------------
reg [31:0] PC, next_PC;
reg [63:0] register      [0:REG_AMOUNT-1];
reg [63:0] next_register [0:REG_AMOUNT-1];
reg [63:0] mem_write_data;
reg [31:0] mem_rw_addr;
reg [ 3:0] ALU_control;
reg        ALU_src_control, reg_write, branch_control, branch_ALU_control;

reg mem_write;

wire [63:0] ALU_in;
wire [31:0] instruction;
wire [63:0] input_data;
wire [ 4:0] rs1, rs2, rd;
wire [11:0] I_imm;
wire [63:0] ALU_out;
assign I_imm = instruction[31:20];

initial begin
  PC = 32'd0;
  next_PC = 32'd0;
end

// Conversion of Little / Big Endian
assign instruction[31:24] = mem_rdata_I[ 7: 0];
assign instruction[23:16] = mem_rdata_I[15: 8];
assign instruction[15: 8] = mem_rdata_I[23:16];
assign instruction[ 7: 0] = mem_rdata_I[31:24];

assign input_data[63:56] = mem_rdata_D[ 7: 0];
assign input_data[55:48] = mem_rdata_D[15: 8];
assign input_data[47:40] = mem_rdata_D[23:16];
assign input_data[39:32] = mem_rdata_D[31:24];
assign input_data[31:24] = mem_rdata_D[39:32];
assign input_data[23:16] = mem_rdata_D[47:40];
assign input_data[15: 8] = mem_rdata_D[55:48];
assign input_data[ 7: 0] = mem_rdata_D[63:56];

assign mem_wdata_D[63:56] = mem_write_data[ 7: 0];
assign mem_wdata_D[55:48] = mem_write_data[15: 8];
assign mem_wdata_D[47:40] = mem_write_data[23:16];
assign mem_wdata_D[39:32] = mem_write_data[31:24];
assign mem_wdata_D[31:24] = mem_write_data[39:32];
assign mem_wdata_D[23:16] = mem_write_data[47:40];
assign mem_wdata_D[15: 8] = mem_write_data[55:48];
assign mem_wdata_D[ 7: 0] = mem_write_data[63:56];

// output connection
assign mem_wen_D  = mem_write;
assign mem_addr_D = mem_rw_addr[31:2];
assign mem_addr_I = PC[31:2];

// decode rs & rd from instruction
assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign rd  = instruction[11: 7];

// ------------------------------------
//         submodule part
// ------------------------------------
ALU alu(ALU_out, register[rs1], ALU_in, ALU_control);
ALU_src_MUX alu_src_mux(ALU_in, register[rs2], { {52{I_imm[11]}}, I_imm }, ALU_src_control);

// ------------------------------------
//      combinational part
// ------------------------------------

// decode instruction
always@ (*)
begin
  ALU_control = { instruction[30], instruction[14:12] };
  reg_write = instruction[4] | instruction[2] | ~instruction[5];
  ALU_src_control = instruction[5];
  branch_control = instruction[6] & ~instruction[2];
  mem_write = ~instruction[6] & instruction[5] & ~instruction[4];
  branch_ALU_control = instruction[12];
end

// handle register writing
integer i;
always@ (*) 
begin
  for(i = 0; i < REG_AMOUNT; i = i+1) begin
    next_register[i] = register[i];
  end
  if (reg_write) begin
    next_register[rd] = ALU_out;
    if (instruction[2]) begin // JAL or JALR
      next_register[rd] = PC + 64'd4;
    end
    else if (~instruction[4] & ~instruction[5]) begin // LD
      next_register[rd] = input_data;
    end
  end
end

// handle memery access
always@ (*) 
begin
  mem_rw_addr = register[rs1][31:0] + { 20'd0, instruction[31:20] };
  mem_write_data = register[rs2];
  if (mem_write) begin
    mem_rw_addr = register[rs1][31:0] + { 20'd0, instruction[31:25], instruction[11:7] }; // imm for S
  end
end

// handle PC
always@ (*)
begin
  next_PC = PC + 32'd4;
  if (branch_control) begin
    if (register[rs1] == register[rs2]) begin  // BEQ
      next_PC = PC + { 19'd0, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0 }; // imm for SB
    end
    if (branch_ALU_control && register[rs1] != register[rs2]) begin // BNE
      next_PC = PC + { 19'd0, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0 }; // imm for SB
    end
  end
  if (instruction[2]) begin // JAL or JALR
    next_PC = register[rs1] + { 18'd0, instruction[31:20] }; // JALR
    if (instruction[3]) begin // JAL
      next_PC = PC + { 11'b0, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0 }; // imm for UJ
    end
  end
end


// ------------------------------------
//      sequential part
// ------------------------------------
integer j;
always@ (posedge clk or negedge rst_n)
begin
  if (!rst_n) begin
    PC <= 32'd0;
    for (j = 0; j < REG_AMOUNT; j = j+1) begin
      register[j] <= 64'd0;
    end
  end
  else begin
    PC <= next_PC;
    register[0] <= 64'd0;
    for (j = 1; j < REG_AMOUNT; j = j+1) begin
      register[j] <= next_register[j];
    end
  end
end


endmodule



module ALU (
  out, in0, in1, control
);
input  [63:0] in0, in1;
output reg [63:0] out;
input  [ 3:0] control;

always@(*) begin
  case (control[2:0])
    3'b000: begin
      if(control[3]) begin
        out = in0 - in1;
      end
      else begin
        out = in0 + in1;
      end
    end
    3'b001: begin
      out = in0 << in1;
    end
    3'b010: begin
      out = (in0 < in1) ? 64'd1 : 64'd0;
    end
    3'b100: begin
      out = in0 ^ in1;
    end
    3'b101: begin
      if (control[3]) begin
        out = in0 >>> in1[5:0];
      end
      else out = in0 >> in1[5:0];
    end
    3'b110: begin
      out = in0 | in1;
    end
    3'b111: begin
      out = in0 & in1;
    end
    default: begin
      out = 64'd0;
    end
  endcase
end

endmodule

module ALU_src_MUX (
  out, in1, in0, ctrl
);
input      [63:0] in0, in1;
output reg [63:0] out;
input         ctrl;

always@ (*) begin
  out = ctrl ? in1 : in0;
end

endmodule
