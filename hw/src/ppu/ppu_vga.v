/***************************************************************************************************
** fpga_nes/hw/src/ppu/ppu_vga.v
*
*  Copyright (c) 2012, Brian Bennett
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without modification, are permitted
*  provided that the following conditions are met:
*
*  1. Redistributions of source code must retain the above copyright notice, this list of conditions
*     and the following disclaimer.
*  2. Redistributions in binary form must reproduce the above copyright notice, this list of
*     conditions and the following disclaimer in the documentation and/or other materials provided
*     with the distribution.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
*  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
*  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
*  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
*  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
*  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
*  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
*  VGA output PPU sub-block.
***************************************************************************************************/

module ppu_vga
(
  input  wire       clk_in,              // 100MHz system clock signal
  input menu_toggle,
  input [7:0] joypad,
  input uart_Tx, 
  output uart_Rx,
  input  wire       rst_in,              // reset signal
  input  wire [5:0] sys_palette_idx_in,  // system palette index (selects output color)
  output wire       hsync_out,           // vga hsync signal
  output wire       vsync_out,           // vga vsync signal
  output wire       pix_en,              // pixel clock enable
  output wire       vde,                 // display enable
  output wire [2:0] r_out,               // vga red signal
  output wire [2:0] g_out,               // vga green signal
  output wire [1:0] b_out,               // vga blue signal
  output wire [9:0] nes_x_out,           // nes x coordinate
  output wire [9:0] nes_y_out,           // nes y coordinate
  output wire [9:0] nes_y_next_out,      // next line's nes y coordinate
  output wire       pix_pulse_out,       // 1 clk pulse prior to nes_x update
  output wire       vblank_out           // indicates a vblank is occuring (no PPU vram access)
);

// Display dimensions (640x480).
localparam [9:0] DISPLAY_W    = 10'h280,
                 DISPLAY_H    = 10'h1E0;

// NES screen dimensions (256x240).
localparam [9:0] NES_W        = 10'h100,
                 NES_H        = 10'h0F0;

// Border color (surrounding NES screen).
localparam [7:0] BORDER_COLOR = 8'h49;

//
// VGA_SYNC: VGA synchronization control block.
//
wire       sync_en;      // vga enable signal
wire [9:0] sync_x;       // current vga x coordinate
wire [9:0] sync_y;       // current vga y coordinate
wire [9:0] sync_x_next;  // vga x coordinate for next clock
wire [9:0] sync_y_next;  // vga y coordinate for next line
wire hsync, vsync;
wire sync_pix_en;
reg  hsync_reg, vsync_reg;
reg  [2:0] r_out_reg, g_out_reg;
reg  [1:0] b_out_reg;
reg  vde_reg, pclk_reg;

vga_sync vga_sync_blk(
  .clk(clk_in),
  .hsync(hsync),
  .vsync(vsync),
  .pix_en(sync_pix_en),
  .en(sync_en),
  .x(sync_x),
  .y(sync_y),
  .x_next(sync_x_next),
  .y_next(sync_y_next)
);

//
// Registers.
//
reg  [7:0] q_rgb;     // output color latch (1 clk delay required by vga_sync)
reg  [7:0] d_rgb;
reg        q_vblank;  // current vblank state
wire       d_vblank;

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
        q_rgb    <= 8'h00;
        q_vblank <= 1'h0;
      end
    else
      begin
        q_rgb    <= d_rgb;
        q_vblank <= d_vblank;
      end
  end
  
  
//assign vde = sync_en;

//
// Coord and timing signals.
//
wire [9:0] nes_x_next;  // nes x coordinate for next clock
wire       border;      // indicates we are displaying a vga pixel outside the nes extents

assign nes_x_out      = (sync_x - 10'h040) >> 1;
assign nes_y_out      = sync_y >> 1;
assign nes_x_next     = (sync_x_next - 10'h040) >> 1;
assign nes_y_next_out = sync_y_next >> 1;
assign border         = (nes_x_out >= NES_W) || (nes_y_out < 8) || (nes_y_out >= (NES_H - 8));

//
// Lookup RGB values based on sys_palette_idx.
//
always @*
  begin
    if(!menu_toggle)
	 begin
    if (!sync_en  )
      begin
        d_rgb = 8'h00;
      end
    else if (border)
      begin
        d_rgb = BORDER_COLOR;
      end
    else
      begin
        // Lookup RGB values based on sys_palette_idx.  Table is an approximation of the NES
        // system palette.  Taken from http://nesdev.parodius.com/NESTechFAQ.htm#nessnescompat.
        case (sys_palette_idx_in)
          6'h00:  d_rgb = { 3'h3, 3'h3, 2'h1 };
          6'h01:  d_rgb = { 3'h1, 3'h0, 2'h2 };
          6'h02:  d_rgb = { 3'h0, 3'h0, 2'h2 };
          6'h03:  d_rgb = { 3'h2, 3'h0, 2'h2 };
          6'h04:  d_rgb = { 3'h4, 3'h0, 2'h1 };
          6'h05:  d_rgb = { 3'h5, 3'h0, 2'h0 };
          6'h06:  d_rgb = { 3'h5, 3'h0, 2'h0 };
          6'h07:  d_rgb = { 3'h3, 3'h0, 2'h0 };
          6'h08:  d_rgb = { 3'h2, 3'h1, 2'h0 };
          6'h09:  d_rgb = { 3'h0, 3'h2, 2'h0 };
          6'h0a:  d_rgb = { 3'h0, 3'h2, 2'h0 };
          6'h0b:  d_rgb = { 3'h0, 3'h1, 2'h0 };
          6'h0c:  d_rgb = { 3'h0, 3'h1, 2'h1 };
          6'h0d:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h0e:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h0f:  d_rgb = { 3'h0, 3'h0, 2'h0 };

          6'h10:  d_rgb = { 3'h5, 3'h5, 2'h2 };
          6'h11:  d_rgb = { 3'h0, 3'h3, 2'h3 };
          6'h12:  d_rgb = { 3'h1, 3'h1, 2'h3 };
          6'h13:  d_rgb = { 3'h4, 3'h0, 2'h3 };
          6'h14:  d_rgb = { 3'h5, 3'h0, 2'h2 };
          6'h15:  d_rgb = { 3'h7, 3'h0, 2'h1 };
          6'h16:  d_rgb = { 3'h6, 3'h1, 2'h0 };
          6'h17:  d_rgb = { 3'h6, 3'h2, 2'h0 };
          6'h18:  d_rgb = { 3'h4, 3'h3, 2'h0 };
          6'h19:  d_rgb = { 3'h0, 3'h4, 2'h0 };
          6'h1a:  d_rgb = { 3'h0, 3'h5, 2'h0 };
          6'h1b:  d_rgb = { 3'h0, 3'h4, 2'h0 };
          6'h1c:  d_rgb = { 3'h0, 3'h4, 2'h2 };
          6'h1d:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h1e:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h1f:  d_rgb = { 3'h0, 3'h0, 2'h0 };

          6'h20:  d_rgb = { 3'h7, 3'h7, 2'h3 };
          6'h21:  d_rgb = { 3'h1, 3'h5, 2'h3 };
          6'h22:  d_rgb = { 3'h2, 3'h4, 2'h3 };
          6'h23:  d_rgb = { 3'h5, 3'h4, 2'h3 };
          6'h24:  d_rgb = { 3'h7, 3'h3, 2'h3 };
          6'h25:  d_rgb = { 3'h7, 3'h3, 2'h2 };
          6'h26:  d_rgb = { 3'h7, 3'h3, 2'h1 };
          6'h27:  d_rgb = { 3'h7, 3'h4, 2'h0 };
          6'h28:  d_rgb = { 3'h7, 3'h5, 2'h0 };
          6'h29:  d_rgb = { 3'h4, 3'h6, 2'h0 };
          6'h2a:  d_rgb = { 3'h2, 3'h6, 2'h1 };
          6'h2b:  d_rgb = { 3'h2, 3'h7, 2'h2 };
          6'h2c:  d_rgb = { 3'h0, 3'h7, 2'h3 };
          6'h2d:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h2e:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h2f:  d_rgb = { 3'h0, 3'h0, 2'h0 };

          6'h30:  d_rgb = { 3'h7, 3'h7, 2'h3 };
          6'h31:  d_rgb = { 3'h5, 3'h7, 2'h3 };
          6'h32:  d_rgb = { 3'h6, 3'h6, 2'h3 };
          6'h33:  d_rgb = { 3'h6, 3'h6, 2'h3 };
          6'h34:  d_rgb = { 3'h7, 3'h6, 2'h3 };
          6'h35:  d_rgb = { 3'h7, 3'h6, 2'h3 };
          6'h36:  d_rgb = { 3'h7, 3'h5, 2'h2 };
          6'h37:  d_rgb = { 3'h7, 3'h6, 2'h2 };
          6'h38:  d_rgb = { 3'h7, 3'h7, 2'h2 };
          6'h39:  d_rgb = { 3'h7, 3'h7, 2'h2 };
          6'h3a:  d_rgb = { 3'h5, 3'h7, 2'h2 };
          6'h3b:  d_rgb = { 3'h5, 3'h7, 2'h3 };
          6'h3c:  d_rgb = { 3'h4, 3'h7, 2'h3 };
          6'h3d:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h3e:  d_rgb = { 3'h0, 3'h0, 2'h0 };
          6'h3f:  d_rgb = { 3'h0, 3'h0, 2'h0 };
        endcase
      end
		end //if !menu_toggle
  end
  
  	// menu module
	wire rx_done;
	wire [7:0] rec_data;
	reg [7:0] send_data;
	reg txd_start;
	wire txd_busy;
	reg [2:0] rgb_reg;
	wire [2:0] rgb_next;
	wire[4:0] cursor_y;
	wire [9:0] pixel_x, pixel_y;
   wire video_on, pixel_tick;
	wire menu_hsync, menu_vsync;
	wire data_en;
	reg menu_clk; //50mhz clock
	
   // instantiate main uart
	async_receiver uart_receiver(.clk(clk_in), .RxD(uart_Tx), 
		.RxD_data_ready(rx_done), .RxD_data(rec_data));

	async_transmitter uart_transmitter(.clk(clk_in), .TxD_start(txd_start), .TxD_data(send_data),
		.TxD(uart_Rx), .TxD_busy(txd_busy));
		
   // instantiate vga sync circuit
   video_sync vsync_unit
      (.clk(clk_in), .reset(), .hsync(menu_hsync), .vsync(menu_vsync),
       .video_on(video_on), .p_tick(pixel_tick),
       .pixel_x(pixel_x), .pixel_y(pixel_y));
   // font generation circuit
   text_menu_gen text_gen_unit
      (.clk(clk_in), .video_on(video_on),
        .data(rec_data[7:0]), .data_en(data_en), .text_rx_done(rx_done), .pixel_x(pixel_x),
       .pixel_y(pixel_y), .cursor_y(cursor_y), .text_rgb(rgb_next), .move_up_tick(joypad[4]), 
		 .move_down_tick(joypad[5]), .btn_select(joypad[2]));
	
	//buttons output
	always @*
	begin
		txd_start = 1'b0;
		send_data = 8'h00;
		
		if(joypad[6] && menu_toggle) //left
		begin
			send_data = 8'h80;
			txd_start = 1'b1;
		end
		
		if(joypad[7] && menu_toggle) //right
		begin
			send_data = 8'h81;
			txd_start = 1'b1;
		end
		
		if(joypad[2] && menu_toggle && (cursor_y[4:0] != 5'b00000)) //select
		begin
			send_data = {3'b000, cursor_y[4:0]};
			txd_start = 1'b1;
		end
		
		if(joypad[0] && menu_toggle) //a
		begin
			send_data = 8'h83;
			txd_start = 1'b1;
		end
		
		if(joypad[1] && menu_toggle) //b
		begin
			send_data = 8'h82;
			txd_start = 1'b1;
		end
	end
	
//50MHz clock
always @(posedge clk_in)
      menu_clk <= menu_clk + 1;
		
// rgb buffer
always @(posedge menu_clk)
	begin
		if (pixel_tick)
         rgb_reg <= rgb_next;
	end
		
always @*
	begin
		if(menu_toggle)
		begin
			vde_reg = video_on;
			pclk_reg = pixel_tick;
			hsync_reg = menu_hsync;
			vsync_reg = menu_vsync;
			r_out_reg = rgb_reg[0] ? 3'b111 : 3'b000;
			g_out_reg = rgb_reg[1] ? 3'b111 : 3'b000;
			b_out_reg = rgb_reg[2] ? 2'b11 : 2'b00;
		end
		else
		begin
		   vde_reg = sync_en;
			pclk_reg = sync_pix_en;
			hsync_reg = hsync;
			vsync_reg = vsync;
			r_out_reg = q_rgb[7:5];
			g_out_reg = q_rgb[4:2];
			b_out_reg = q_rgb[1:0];
		end
	end

assign r_out = r_out_reg;
assign g_out = g_out_reg;
assign b_out = b_out_reg;
assign hsync_out = hsync_reg;
assign vsync_out = vsync_reg;
assign pix_en = pclk_reg;
assign vde = vde_reg;

// output
assign data_en =  1'b1;

//assign { r_out, g_out, b_out } = q_rgb;
assign pix_pulse_out           = nes_x_next != nes_x_out;

// Clear the VBLANK signal immediately before starting processing of the pre-0 garbage line.  From
// here.  Set the vblank approximately 2270 CPU cycles before it will be cleared.  This is done
// in order to pass vbl_clear_time.nes.  It eats into the visible portion of the playfield, but we
// currently hide that portion of the screen anyway.
assign d_vblank = ((sync_x == 730) && (sync_y == 477)) ? 1'b1 :
                  ((sync_x == 64) && (sync_y == 519))  ? 1'b0 : q_vblank;

assign vblank_out = q_vblank;

endmodule

