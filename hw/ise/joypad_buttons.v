`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jon Thomasson
// 
// Create Date:    06:37:25 12/08/2016 
// Design Name: 
// Module Name:    joypad_buttons 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: This module handles the debouncing of the joypad button array. It will
//						send the output array back in a format that can be directly input into
//						the NES.
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//						Incoming joypad array has following format:
//									0: BTN_A / 1: BTN_B / 2: BTN_SELECT / 3: BTN_START /
//									4: BTN_UP / 5: BTN_DOWN / 6: BTN_LEFT / 7: BTN_RIGHT
//////////////////////////////////////////////////////////////////////////////////
module joypad_buttons(
	input clk, reset,
	input  wire        wr,        // write enable signal
	input [7:0] joypad, //joypad buttons
	input  wire [15:0] addr,      // 16-bit memory address
	input  wire        din,       // data input bus
	output [7:0] joypad_deb, //debounced button array
	output [7:0] joypad_level,
	output reg btn_strobe, //strobe to tell the nes when to read the button values
	output reg  [ 7:0] dout       // data output bus
    );
	 
	wire btn_a, btn_b, btn_select, btn_start, 
		  btn_up, btn_down, btn_left, btn_right;
	wire btn_a_level, btn_b_level, btn_select_level, btn_start_level,
		  btn_up_level, btn_down_level, btn_left_level, btn_right_level;
	wire[7:0] joypad_deb_level;
	reg [7:0] joypad_reg, joypad_next;
	
	
	localparam [15:0] JOYPAD1_MMR_ADDR = 16'h4016;
	localparam [15:0] JOYPAD2_MMR_ADDR = 16'h4017;

	localparam S_STROBE_WROTE_0 = 1'b0,
				  S_STROBE_WROTE_1 = 1'b1;

	
		  
	// instantiate debounce circuit for the buttons
   debounce #(.N(21)) deb_unit1
      (.clk(clk), .reset(), .sw(joypad[0]),
       .db_level(btn_a_level), .db_tick(btn_a));
		 
   debounce #(.N(21)) deb_unit2
      (.clk(clk), .reset(), .sw(joypad[1]),
       .db_level(btn_b_level), .db_tick(btn_b));
		 
	debounce #(.N(21)) deb_unit3
      (.clk(clk), .reset(), .sw(joypad[2]),
       .db_level(btn_select_level), .db_tick(btn_select));
		 
	debounce #(.N(21)) deb_unit4
      (.clk(clk), .reset(), .sw(joypad[3]),
       .db_level(btn_start_level), .db_tick(btn_start));
		 
	debounce #(.N(21)) deb_unit5
      (.clk(clk), .reset(), .sw(joypad[4]),
       .db_level(btn_up_level), .db_tick(btn_up));
		 
	debounce #(.N(21)) deb_unit6
      (.clk(clk), .reset(), .sw(joypad[5]),
       .db_level(btn_down_level), .db_tick(btn_down));
		 
	debounce #(.N(21)) deb_unit7
      (.clk(clk), .reset(), .sw(joypad[6]),
       .db_level(btn_left_level), .db_tick(btn_left));
		 
	debounce #(.N(21)) deb_unit8
      (.clk(clk), .reset(), .sw(joypad[7]),
       .db_level(btn_right_level), .db_tick(btn_right));
		 
	assign joypad_deb = { btn_right,btn_left,btn_down,btn_up,btn_start,btn_select,btn_b,btn_a };
	assign joypad_deb_level = { btn_right_level,btn_left_level,btn_down_level,btn_up_level,btn_start_level,btn_select_level,btn_b_level,btn_a_level };
	assign joypad_level = joypad_deb_level;
	
	always @(posedge clk, posedge reset)
	begin
		if(reset)
		begin
			joypad_reg <= 8'h00;
		end
		else
		begin
			joypad_reg <= joypad_next;
		end
	end
	
	always @*
	begin
	   //d_jp1_state = q_jp1_state;
		joypad_next = joypad_deb_level;
		btn_strobe = 1'b0;
		
		if(joypad_next != joypad_reg)
			btn_strobe = 1'b1;
	end
	
	always @(posedge clk) begin
		if (btn_strobe) begin
			d_jp1_state <= joypad_level;
		end
	end
	
	//always @*
	//begin
	//    dout = 8'h00;
		 
	//	if (addr[15:1] == JOYPAD1_MMR_ADDR[15:1])
   //   begin
   //     dout = joypad_level;
//		end
		
//	end

reg [7:0] q_jp1_state, d_jp1_state;
always @(posedge clk)
  begin
    if (reset)
      begin
        q_jp1_state <= 8'h00;
      end
    else
      begin
        q_jp1_state <= d_jp1_state;
      end
  end
	
	//
	// FFs for managing MMR interface for reading joypad state.
	//
	reg [15:0] q_addr;
	reg [ 8:0] q_jp1_read_state, d_jp1_read_state;
	reg [ 8:0] q_jp2_read_state, d_jp2_read_state;
	reg        q_strobe_state,   d_strobe_state;

	always @(posedge clk)
	begin
    if (reset)
      begin
        q_addr           <= 16'h0000;
        q_jp1_read_state <= 9'h000;
        q_jp2_read_state <= 9'h000;
        q_strobe_state   <= S_STROBE_WROTE_0;
      end
    else
      begin
        q_addr           <= addr;
        q_jp1_read_state <= d_jp1_read_state;
        q_jp2_read_state <= d_jp2_read_state;
        q_strobe_state   <= d_strobe_state;
      end
  end
  always @*
  begin
    dout = 8'h00;

    // Default FFs to current state.
    d_jp1_read_state = q_jp1_read_state;
    d_jp2_read_state = q_jp2_read_state;
    d_strobe_state   = q_strobe_state;

    if (addr[15:1] == JOYPAD1_MMR_ADDR[15:1])
      begin
        dout = { 7'h00, ((addr[0]) ? q_jp2_read_state[0] : q_jp1_read_state[0]) };

        // Only update internal state one time per read/write.
        if (addr != q_addr)
          begin
            // App must write 0x4016 to 1 then to 0 in order to reset and begin reading the joypad
            // state.
            if (wr && !addr[0])
              begin
                if ((q_strobe_state == S_STROBE_WROTE_0) && (din == 1'b1))
                  begin
                    d_strobe_state = S_STROBE_WROTE_1;
                  end
                else if ((q_strobe_state == S_STROBE_WROTE_1) && (din == 1'b0))
                  begin
                    d_strobe_state = S_STROBE_WROTE_0;
                    d_jp1_read_state = { q_jp1_state, 1'b0 };
                    //d_jp2_read_state = { q_jp2_state, 1'b0 };
                  end
              end

            // Shift appropriate jp read state on every read.  After 8 reads, all subsequent reads
            // should be 1.
            else if (!wr && !addr[0])
              d_jp1_read_state = { 1'b1, q_jp1_read_state[8:1] };
            //else if (!wr && addr[0])
              //d_jp2_read_state = { 1'b1, q_jp2_read_state[8:1] };
          end
      end
  end
endmodule
