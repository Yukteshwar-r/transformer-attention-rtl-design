//---------------------------------------------------------------------------
// DUT - 564/464 Project
//---------------------------------------------------------------------------
`include "common.vh"

module MyDesign(
//---------------------------------------------------------------------------
//System signals
  input wire reset_n                      ,  
  input wire clk                          ,

//---------------------------------------------------------------------------
//Control signals
  input wire dut_valid                    , 
  output wire dut_ready                   ,

//---------------------------------------------------------------------------
//input SRAM interface
  output wire                           dut__tb__sram_input_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_input_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_input_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_input_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_input_read_data     ,     

//weight SRAM interface
  output wire                           dut__tb__sram_weight_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_weight_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_weight_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_weight_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_weight_read_data     ,     

//result SRAM interface
  output wire                           dut__tb__sram_result_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_result_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_result_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_result_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_result_read_data     ,         

//scratchpad SRAM interface
  output wire                           dut__tb__sram_scratchpad_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_scratchpad_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_scratchpad_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_scratchpad_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_scratchpad_read_data  

);

typedef logic [15:0] matrix_dimentions;
typedef logic [11:0] data_address;
typedef logic [31:0] matrix_data;

matrix_dimentions x_val, y_val, z_val, x_temp, y_temp, z_temp;
data_address I_addr, W_addr, C_addr, SP_addr;
matrix_data I_data, W_data, C_data;
reg x_val_sel, IW_read_enable, C_write_enable, dut_ready_temp, SP_write_enable;
reg [1:0] y_val_sel, z_val_sel, x_temp_sel, y_temp_sel, z_temp_sel, C_addr_sel, C_data_sel, mul_sel;
reg [2:0] mul_count, I_addr_sel, W_addr_sel, SP_addr_sel;

assign dut__tb__sram_input_read_address = I_addr; // A read address
assign dut__tb__sram_weight_read_address = W_addr; // B read address
assign dut__tb__sram_scratchpad_read_address = W_addr; // result read address
assign dut__tb__sram_result_read_address = I_addr; // scratch pad read address
assign dut__tb__sram_result_write_address =  C_addr; //result write address
assign dut__tb__sram_scratchpad_write_address = SP_addr; // scratch pad write address
assign dut__tb__sram_result_write_data = C_data; // result write data
assign dut__tb__sram_scratchpad_write_data = C_data; // scratch pad write data
assign dut__tb__sram_input_write_enable = 1'b0; // A in read-only mode
assign dut__tb__sram_weight_write_enable = 1'b0; //B in read-only mode
assign dut__tb__sram_result_write_enable = C_write_enable; 
assign dut__tb__sram_scratchpad_write_enable = SP_write_enable;
assign dut_ready = dut_ready_temp;


typedef enum bit[4:0] { // Defining states
  S0 = 5'b0,
  S1 = 5'b1,
  S2 = 5'b10,
  S3 = 5'b11,
  S4 = 5'b100,
  S5 = 5'b101,
  S6 = 5'b110,
  S7 = 5'b111,
  S8 = 5'b1000,
  S9 = 5'b1001,
  S10 = 5'b1010,
  S11 = 5'b1011,
  S12 = 5'b1100,
  S13 = 5'b1101,
  S14 = 5'b1110,
  S15 = 5'b1111,
  S16 = 5'b10000,
  S17 = 5'b10001,
  S18 = 5'b10010,
  S19 = 5'b10011,
  S20 = 5'b10100,
  S21 = 5'b10101
} states;
  

states current_state, next_state;

/*------- Sequential Logic ----*/
always@(posedge clk or negedge reset_n) // Reset
  if (!reset_n) current_state <= S0;
  else current_state <= next_state;

always@(posedge clk)
  begin 

    case (mul_sel) // select line for matrix multiplication
      2'b0: mul_count <= 3'b0;
      2'b1: mul_count <= mul_count+3'b1;
      2'b10: mul_count <= mul_count;
      default: mul_count <= mul_count;
    endcase
    
    case (x_val_sel) // A-rows
      1'b0: x_val <= tb__dut__sram_input_read_data[31:16];
      1'b1: x_val <= x_val;
    endcase

    case (y_val_sel) // A-columns/B-rows
      2'b0: y_val <= tb__dut__sram_weight_read_data[31:16];
      2'b1: y_val <= y_val;
      2'b10: y_val <= z_val;
      2'b11: y_val <= x_val;
    endcase

    case (z_val_sel) // B-columns
      2'b0: z_val <= tb__dut__sram_weight_read_data[15:0];
      2'b1: z_val <= z_val;
      2'b10: z_val <= x_val;
      2'b11: z_val <= y_val;
    endcase

    case (x_temp_sel) // select line for A-rows counter
      2'b0: x_temp <= 16'b0;
      2'b1: x_temp <= x_temp+16'b1;
      2'b10: x_temp <= x_temp;
      default: x_temp <= x_temp;
    endcase

    case (y_temp_sel) // select line for A-columns/B-rows counter
      2'b0: y_temp <= 16'b1;
      2'b1: y_temp <= y_temp+16'b1;
      2'b10: y_temp <= y_temp;
      default: y_temp <= y_temp;
    endcase

    case (z_temp_sel) // select line for B-columns counter
      2'b0: z_temp <= 16'b0;
      2'b1: z_temp <= z_temp+16'b1;
      2'b10: z_temp <= z_temp;
      default: z_temp <= z_temp;
    endcase

    case (I_addr_sel) // I read address select line
      3'b0: I_addr <= 12'b0;
      3'b1: I_addr <= I_addr+12'b1;
      3'b10: I_addr <= I_addr;
      3'b11: I_addr <= x_temp*y_val + y_temp;
      3'b100: I_addr <= x_temp*y_val + y_temp - 12'b1;
      3'b101: I_addr <= 12'b11*x_val*z_val;
      3'b110: I_addr <= 12'b11*x_val*z_val+ x_temp*y_val + y_temp - 12'b1;
      default: I_addr <= I_addr;
    endcase

    case (W_addr_sel) // W read address select line
      3'b0: W_addr <= 12'b0;
      3'b1: W_addr <= W_addr+12'b1;
      3'b10: W_addr <= W_addr;
      3'b11: W_addr <= mul_count*y_val*z_val + z_temp*y_val + y_temp;
      3'b100: W_addr <= 12'b1;
      3'b101: W_addr <= z_temp*y_val + y_temp;
      3'b110: W_addr <= x_val*z_val + 12'b1;
      3'b111: W_addr <= x_val*z_val + z_temp*y_val + y_temp;
      default: W_addr <= W_addr;
    endcase

    case (C_addr_sel) // C write address select line
      2'b0: C_addr <= 12'b0;
      2'b1: C_addr <= C_addr+12'b1;
      2'b10: C_addr <= C_addr;
      default: C_addr <= C_addr;
    endcase

    case (SP_addr_sel) // Scratch pad write address select line
      3'b0: SP_addr <= 12'b1;
      3'b1: SP_addr <= SP_addr + 12'b1;
      3'b10: SP_addr <= x_val*z_val + x_temp + 12'b1;
      3'b11: SP_addr <= SP_addr + x_val;
      3'b100: SP_addr <= SP_addr;
      default: SP_addr <= SP_addr;
    endcase

    case (IW_read_enable) // read enable line for I_data and W_data
      1'b1: begin
              if (mul_count <= 3'b10) //for first 3 multiplications
              begin
                I_data <= tb__dut__sram_input_read_data; //read I data
                W_data <= tb__dut__sram_weight_read_data; //read W data
              end
              else //for the rest of the multiplications
              begin
                I_data <= tb__dut__sram_result_read_data; //read result data
                W_data <= tb__dut__sram_scratchpad_read_data; //read sratchpad data 
              end
            end
      default: begin
              I_data <= I_data;
              W_data <= W_data;
            end
    endcase

    case (C_data_sel) // C write data select line
      2'b0: C_data <= 32'b0;
      2'b1: C_data <= I_data*W_data + C_data;
      2'b10: C_data <= C_data;
      default: C_data <= C_data;
    endcase
  end

always@(*)
  begin 
    case (current_state) // finite state machine
      S0: begin 
            mul_sel = 2'b0;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b0;
            y_temp_sel = 2'b0;
            z_temp_sel = 2'b0;
            I_addr_sel = 3'b0;
            W_addr_sel = 3'b0;
            C_addr_sel = 2'b0;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b0;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b1;
            SP_addr_sel = 3'b0;
            SP_write_enable = 1'b0;

            if (dut_valid) next_state = S1;
            else next_state = S0;                
          end

      S1: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b10;
            I_addr_sel = 3'b1;
            W_addr_sel = 3'b1;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b10;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0;  

            if (mul_count == 0) next_state = S2;
            else next_state = S3;
          end

      S2: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b0;
            y_val_sel = 2'b0;
            z_val_sel = 2'b0;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b10;
            I_addr_sel = 3'b1;
            W_addr_sel = 3'b1;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b10;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;  
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0;         
            next_state = S3;
          end

      S3: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b10;
            I_addr_sel = 3'b1;
            W_addr_sel = 3'b1;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b1;
            C_data_sel = 2'b10;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0; 
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0;  
            next_state = S4;
          end

      S4: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b1;
            z_temp_sel = 2'b10;
            I_addr_sel = 3'b1;
            W_addr_sel = 3'b1;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b1;
            C_data_sel = 2'b1;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0; 
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0; 

            if (y_val != 16'b1) begin
              if (y_temp == y_val-16'b01) next_state = S5;
              else next_state = S4;
            end
            else next_state  = S5;
          end

      S5: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b0;
            z_temp_sel = 2'b1;
            I_addr_sel = 3'b10;
            W_addr_sel = 3'b10;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;

            if (y_val != 16'b1) C_data_sel = 2'b1;
            else C_data_sel = 2'b10;

            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0; 
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0;   
            next_state = S6;
          end

      S6: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b10;
            I_addr_sel = 3'b10;
            W_addr_sel = 3'b10;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b10;
            C_write_enable = 1'b1;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0; 

            if (mul_count == 3'b1 || mul_count == 3'b10) next_state = S14;
            else begin
              if (z_temp != z_val) next_state = S7; // checks if W-columns counter has overflown or not 
              else next_state = S9;
            end
          end

      S7: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b10;

            if (mul_count == 3'b11) begin
              I_addr_sel = 3'b100;
              W_addr_sel = 3'b101;
              C_addr_sel = 2'b1;
            end
            else if (mul_count == 3'b100) begin
              I_addr_sel = 3'b110;
              W_addr_sel = 3'b111;
              C_addr_sel = 2'b1;
            end
            else begin
              I_addr_sel = 3'b11;
              W_addr_sel = 3'b11;
              C_addr_sel = 2'b1;
            end

            IW_read_enable = 1'b0;
            C_data_sel = 2'b10;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;

            if (mul_count == 3'b1) SP_addr_sel = 3'b1;
            else if (mul_count == 3'b10) SP_addr_sel = 3'b11;
            else SP_addr_sel = 3'b100;

            SP_write_enable = 1'b0;   
            next_state = S8;
          end

      S8: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b10;
            I_addr_sel = 3'b1;
            W_addr_sel = 3'b1;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b0;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0;   
            next_state = S3; 
          end

      S9: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b1;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b0;
            I_addr_sel = 3'b10;
            W_addr_sel = 3'b10;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b10;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0;  

            if (mul_count == 3'b10) next_state = S18;
            else if (mul_count == 3'b100) next_state = S21;
            else next_state = S10;
          end

      S10: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b10;

            if (mul_count == 3'b11) begin
              I_addr_sel = 3'b100;
              W_addr_sel = 3'b101;
              C_addr_sel = 2'b1;
            end
            else begin
              I_addr_sel = 3'b11;
              W_addr_sel = 3'b11;
              C_addr_sel = 2'b1;
            end
            
            IW_read_enable = 1'b0;
            C_data_sel = 2'b10;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0;  

            if (x_temp != x_val) next_state = S11; // checks if I-rows counter has overflown or not
            else begin
              if (mul_count < 3'b10) next_state = S12;
              else if (mul_count == 3'b10) next_state = S16; 
              else if (mul_count == 3'b11) next_state = S19;
              else next_state = S0;
            end
          end

      S11: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b10;
            I_addr_sel = 3'b1;
            W_addr_sel = 3'b1;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b0;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0;   
            next_state = S3;
          end

      S12: begin
            mul_sel = 2'b1;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b0;
            y_temp_sel = 2'b0;
            z_temp_sel = 2'b0;
            I_addr_sel = 3'b10;
            W_addr_sel = 3'b10;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b0;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0;
            next_state = S13;
          end

      S13: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b10;
            I_addr_sel = 3'b11;
            W_addr_sel = 3'b11;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b10;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            
            if (mul_count == 3'b10) SP_addr_sel = 3'b10;
            else SP_addr_sel = 3'b100;

            SP_write_enable = 1'b0;   
            next_state = S1;
          end

      S14: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b10;
            I_addr_sel = 3'b10;
            W_addr_sel = 3'b10;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b10;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b1; // scratchpad write enable high while computing K and V

            if (z_temp != z_val) next_state = S7; // checks if W-columns counter has overflown or not 
            else begin
              if (mul_count == 3'b1) next_state = S15;
              else if (mul_count == 3'b10) next_state = S9;
            end
          end

      S15: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b1;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b0;
            I_addr_sel = 3'b10;
            W_addr_sel = 3'b10;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b10;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b1;
            SP_write_enable = 1'b0;   
            next_state = S10;
          end

      S16: begin
            mul_sel = 2'b1;
            x_val_sel = 1'b1;
            y_val_sel = 2'b10;
            z_val_sel = 2'b10;
            x_temp_sel = 2'b0;
            y_temp_sel = 2'b0;
            z_temp_sel = 2'b0;
            I_addr_sel = 3'b10;
            W_addr_sel = 3'b10;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b10;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0;
            next_state = S17;
          end

      S17: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b10;
            I_addr_sel = 3'b0;
            W_addr_sel = 3'b100;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b0;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0; 
            next_state = S1;
          end

      S18: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b10;
            I_addr_sel = 3'b10;
            W_addr_sel = 3'b10;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b10;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b10;
            SP_write_enable = 1'b0;   
            next_state = S10;
          end

      S19: begin
            mul_sel = 2'b1;
            x_val_sel = 1'b1;
            y_val_sel = 2'b11;
            z_val_sel = 2'b11;
            x_temp_sel = 2'b0;
            y_temp_sel = 2'b0;
            z_temp_sel = 2'b0;
            I_addr_sel = 3'b10;
            W_addr_sel = 3'b10;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b10;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0;
            next_state = S20;
          end

      S20: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b10;
            I_addr_sel = 3'b101;
            W_addr_sel = 3'b110;
            C_addr_sel = 2'b10;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b0;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0; 
            next_state = S1;
          end

      S21: begin
            mul_sel = 2'b10;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b10;
            y_temp_sel = 2'b10;
            z_temp_sel = 2'b10;
            I_addr_sel = 3'b110;
            W_addr_sel = 3'b111;
            C_addr_sel = 2'b1;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b10;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b0;
            SP_addr_sel = 3'b100;
            SP_write_enable = 1'b0;   

            if (x_temp != x_val) next_state = S11; // checks if I-rows counter has overflown or not
            else next_state = S0;
          end

      default: begin 
            mul_sel = 2'b0;
            x_val_sel = 1'b1;
            y_val_sel = 2'b1;
            z_val_sel = 2'b1;
            x_temp_sel = 2'b0;
            y_temp_sel = 2'b0;
            z_temp_sel = 2'b0;
            I_addr_sel = 3'b0;
            W_addr_sel = 3'b0;
            C_addr_sel = 2'b0;
            IW_read_enable = 1'b0;
            C_data_sel = 2'b0;
            C_write_enable = 1'b0;
            dut_ready_temp = 1'b1;
            SP_addr_sel = 3'b0;
            SP_write_enable = 1'b0;   
            next_state = S0;
          end
    endcase
  end

endmodule