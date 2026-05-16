/*
 * Copyright (c) 2024-2025 James Ross
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_matrix_abc (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // --- VGA Controller Pins Assignment ---
    wire hsync, vsync, video_on;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;

    assign uo_out[0] = hsync;
    assign uo_out[1] = vsync;
    // Remainder of uo_out usually routes to RGB lines (e.g., bits [7:2] or custom maps)
    
    // Assign unused bi-directional pins to safe values or high-Z
    assign uio_out = 8'b00000000;
    assign uio_oe  = 8'b00000000;

    // --- VGA Sync Generator Instance ---
    // (Assuming hvsync_generator or a similar module is bundled in your project)
    hvsync_generator vga_sync (
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .video_on(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    // --- Text Matrix / Character Definition for "colegio de muntinlupa" ---
    // Length of "colegio de muntinlupa" is 21 characters.
    reg [5:0] char_code;
    wire [4:0] char_index;

    // Divide pixel_x to create grid columns for characters (e.g., 1 character per 16 or 32 pixels wide)
    assign char_index = pixel_x[8:4]; // Adjust bits depending on your exact font scale scaling

    // Mapping 0-20 to ASCII/Custom encoding index equivalents for "colegio de muntinlupa"
    // Using standard custom 6-bit index mapping (A=1, B=2, C=3, ..., Space=0 or 32)
    always @(*) begin
        case (char_index)
            5'd0:  char_code = 6'd3;  // 'c'
            5'd1:  char_code = 6'd15; // 'o'
            5'd2:  char_code = 6'd12; // 'l'
            5'd3:  char_code = 6'd5;  // 'e'
            5'd4:  char_code = 6'd7;  // 'g'
            5'd5:  char_code = 6'd9;  // 'i'
            5'd6:  char_code = 6'd15; // 'o'
            5'd7:  char_code = 6'd0;  // ' ' (Space)
            5'd8:  char_code = 6'd4;  // 'd'
            5'd9:  char_code = 6'd5;  // 'e'
            5'd10: char_code = 6'd0;  // ' ' (Space)
            5'd11: char_code = 6'd13; // 'm'
            5'd12: char_code = 6'd21; // 'u'
            5'd13: char_code = 6'd14; // 'n'
            5'd14: char_code = 6'd20; // 't'
            5'd15: char_code = 6'd9;  // 'i'
            5'd16: char_code = 6'd14; // 'n'
            5'd17: char_code = 6'd12; // 'l'
            5'd18: char_code = 6'd21; // 'u'
            5'd19: char_code = 6'd16; // 'p'
            5'd20: char_code = 6'd1;  // 'a'
            default: char_code = 6'd0; // Clear / Empty space
        endcase
    end

    // --- Font Generation Bit-mapping ---
    wire font_bit;
    // Internal instance passing `char_code` plus row indexing (`pixel_y[3:0]`) 
    // down to your alphabet matrix generation sub-module to retrieve individual pixels.
    font_rom font_unit (
        .char_code(char_code),
        .row(pixel_y[4:1]),
        .col(pixel_x[3:1]),
        .bit_out(font_bit)
    );

    // --- Video Output Multiplexing ---
    // Outputs pixels when video_on framework window active and character text bit is high.
    wire pixel_data = video_on && font_bit;
    
    // RGB outputs to uo_out (adjust color bit indices according to your DAC configuration)
    assign uo_out[7:2] = pixel_data ? 6'b111111 : 6'b000000;

endmodule
