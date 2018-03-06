// Listing 14.4
module text_screen_gen
   (
    input wire clk, btn_select, move_up_tick, move_down_tick,
    input wire video_on, text_rx_done, data_en,
    input wire [7:0] data,
    input wire [9:0] pixel_x, pixel_y,
    output reg [2:0] text_rgb,
	 output wire [4:0] cursor_y
   );

   // signal declaration
   // font ROM
   wire [10:0] rom_addr;
   wire [6:0] char_addr;
   wire [3:0] row_addr;
   wire [2:0] bit_addr;
   wire [7:0] font_word;
   wire font_bit;
   // tile RAM
   wire we;
   wire [11:0] addr_r, addr_w;
   wire [6:0] din, dout;
   // 80-by-30 tile map
   localparam MAX_X = 80;
   localparam MAX_Y = 30;
   // cursor
   reg [6:0] cur_x_reg;
   wire [6:0] cur_x_next;
   reg [4:0] cur_y_reg;
   wire [4:0]cur_y_next;
   wire cursor_on;
	// underline
	wire underline_on;
   // delayed pixel count
   reg [9:0] pix_x1_reg, pix_y1_reg;
   reg [9:0] pix_x2_reg, pix_y2_reg;
   // object output signals
   wire [2:0] font_rgb, font_rev_rgb, underline_rgb;
	reg show_cursor;

   // body
		 
   // instantiate font ROM
   font_rom font_unit
      (.clk(clk), .addr(rom_addr), .data(font_word));
   // instantiate dual-port video RAM (2^12-by-7)
   xilinx_dual_port_ram_sync
      #(.ADDR_WIDTH(12), .DATA_WIDTH(7)) video_ram
      (.clk(clk), .we(we), .addr_a(addr_w), .addr_b(addr_r),
       .din_a(din), .dout_a(), .dout_b(dout));

   // registers
   always @(posedge clk)
      begin
         cur_x_reg <= cur_x_next;
         cur_y_reg <= cur_y_next;
         pix_x1_reg <= pixel_x;
         pix_x2_reg <= pix_x1_reg;
         pix_y1_reg <= pixel_y;
         pix_y2_reg <= pix_y1_reg;
      end
   // tile RAM write
   assign addr_w = {cur_y_reg, cur_x_reg};
   assign we = (data[7] == 1'b1) || (data_en == 1'b0) ? 1'b0 : text_rx_done; //added some checking here. If the data sent back starts with an 8, it's a special commmand and doesn't need to be displayed.
   assign din = data[6:0]; 
   // tile RAM read
   // use nondelayed coordinates to form tile RAM address
   assign addr_r = {pixel_y[8:4], pixel_x[9:3]};
   assign char_addr = dout;
   // font ROM
   assign row_addr = pixel_y[3:0];
   assign rom_addr = {char_addr, row_addr};
   // use delayed coordinate to select a bit
   assign bit_addr = pix_x2_reg[2:0];
   assign font_bit = font_word[~bit_addr];
  
   // new cursor position
   assign cur_x_next = (text_rx_done && (cur_x_reg==MAX_X-1)) ? 0 :
		(text_rx_done && data[6:0] == 7'b0001101) ? 0 : //if received newline advance cursor one line down
		(text_rx_done) ? cur_x_reg + 1 : 
		cur_x_reg;
     
   assign cur_y_next = (text_rx_done && (cur_x_reg==MAX_X-1)) ? cur_y_reg + 1 : 
		(data[6:0] == 7'b0001101 && text_rx_done && (cur_y_reg==MAX_Y-1)) ? 0 : //if received newline advance cursor one line down
		(data[6:0] == 7'b0001101 && text_rx_done && (cur_y_reg<MAX_Y-1)) ? cur_y_reg + 1 : //if received newline advance cursor one line down
		(move_down_tick && (cur_y_reg==MAX_Y-1)) ? 1 :
		(move_down_tick) ? cur_y_reg + 1 :
		(move_up_tick) && cur_y_reg == 1 ? MAX_Y - 1 :
		(move_up_tick) ? cur_y_reg - 1 : 
		(data[7:0] == 8'b10000000 && text_rx_done) ? 0 : //if received x80 then move cursor to top position
		(data[7:0] == 8'b10000001 && text_rx_done) ? 1 : //if received x81 then move cursor to 2nd to top position
		cur_y_reg;
		
						 
   // object signals
   // green over black and reversed video for cursor
   assign font_rgb = (font_bit) ? 3'b010 : 3'b000;
   assign font_rev_rgb = (font_bit) ? 3'b000 : 3'b010;
	assign underline_rgb = 3'b010; //green underline 
   // use delayed coordinates for comparison
   assign cursor_on = (pix_y2_reg[8:4]==cur_y_reg) && show_cursor; //&&
                      //(pix_x2_reg[9:3]==cur_x_reg);
	assign cursor_y = cur_y_reg;
	
	assign underline_on = show_cursor && (pixel_y == 14); //create underline on 18th pixel down from top
   // rgb multiplexing circuit
   always @*
	begin
      if (~video_on)
         text_rgb = 3'b000; // blank
      else
		begin
         if (cursor_on) 
            text_rgb = font_rev_rgb;
          else
            text_rgb = font_rgb;
				
			if (underline_on)
				text_rgb = underline_rgb;
		end
	end	
	
	always @*
	begin
		if(data[7:0] == 8'h82)
			show_cursor = 1'b1;
			
		if(data[7:0] == 8'h83)
			show_cursor = 1'b0;
	end
		
endmodule

