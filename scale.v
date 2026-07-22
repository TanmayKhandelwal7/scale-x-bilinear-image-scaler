`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.06.2026 16:49:04
// Design Name: 
// Module Name: scale
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module scale#(
    parameter Win  = 2,
    parameter Hin  = 2,
    parameter Wout = 3,
    parameter Hout = 5,
    parameter CHANNELS = 1   // 1 = grayscale, 3 = RGB
)(
    input clk,
    input rst,
    output reg done,    
    output reg [15:0] xout,
    output reg [15:0] yout
);

    // Input image memory
    reg [7:0] in_memR [0:Win*Hin-1];
    reg [7:0] in_memG [0:Win*Hin-1];
    reg [7:0] in_memB [0:Win*Hin-1];

    // Output image memory
    reg [7:0] out_memR [0:Wout*Hout-1];
    reg [7:0] out_memG [0:Wout*Hout-1];
    reg [7:0] out_memB [0:Wout*Hout-1];
 
   
   
   initial begin
    $readmemh("inputR.hex", in_memR);
    $readmemh("inputG.hex", in_memG);
    $readmemh("inputB.hex", in_memB);
end

integer i;

reg [23:0]xin,yin;


initial begin
    xout = 15'd0;
    yout = 15'd0;
for (i = 0; i < Wout*Hout; i = i + 1) begin
            out_memR[i] = 8'd0;
            out_memG[i] = 8'd0;
            out_memB[i] = 8'd0;
        end
end
reg [31:0]addr;
reg [15:0]wa,wb,wc,wd;
reg files_written = 0;
reg [3:0]state;
wire [7:0]a,b;
wire [15:0]x0,y0;
reg [24:0]base;
wire rw,dw,last;
parameter scalex = (Win<<8)/Wout;
parameter scaley = (Hin<<8)/Hout;
parameter S0 = 4'b000,S1 = 4'd1,S2 = 4'd2,S3 = 4'd3,S4 =4'd4,S5 = 4'd5,S6 = 4'd6,S7 = 4'd7,S8 = 4'd8,S9 = 4'd9,S10 = 4'd10,S11 = 4'd11,S12 = 4'd12,S13 = 4'd13,S14 = 4'd14,S15 = 4'd15;

assign x0 = xin[23:8];
assign y0 = yin[23:8];
assign a = xin[7:0];
assign b = yin[7:0];
assign rw = (x0 == Win - 1) && (y0 != Hin - 1);
assign dw = (x0 != Win - 1) && (y0 == Hin - 1);
assign last = (x0 == Win - 1) && (y0 == Hin - 1);


always@(posedge clk)begin

if(rst) state<=S0;
else begin
   case(state)
   S0:begin
   if(xout == 0 && yout == 0) begin
   xin<=16'd0;
   yin<=16'd0;
   end
   else if(xout == 0) begin
   yin<=yin+ scaley;
   xin<=16'd0;
   end
   else xin<=xin + scalex;
   
   base<=yout*Wout + xout;
   state<=S1;
   end
   
   S1: begin
      addr<=y0*Win + x0;
      state<=S2;
      end
   
   S2:begin
     wa <= ((a*b)>>8);   //ab
     state<=S3; 
    end
   
  S3:begin
     wb <= a - wa;
     if(last == 1'd1) out_memR[base] <= ((wa)*in_memR[addr]) >> 8;
     else if(rw == 1'd1) out_memR[base] <= ((wa)*in_memR[addr + Win]) >> 8;
     else if(dw == 1'd1) out_memR[base] <= ((wa)*in_memR[addr + 1]) >> 8;
     else out_memR[base] <= ((wa)*in_memR[addr + 1 + Win]) >> 8;
     state <= S4;
   end
   
   S4:begin
     wc <= b - wa;
     if(last == 1'd1) out_memR[base] <= out_memR[base] + (((wb)*in_memR[addr]) >> 8);
     else if(rw == 1'd1) out_memR[base] <= out_memR[base] + (((wb)*in_memR[addr]) >> 8);
     else if(dw == 1'd1) out_memR[base] <= out_memR[base] + (((wb)*in_memR[addr+1]) >> 8);
     else out_memR[base] <= out_memR[base] + (((wb)*in_memR[addr+1]) >> 8);
     state <= S5;
   end
   
   S5:begin
     wd <= wa - a - b + 16'd256;
     if(last == 1'd1) out_memR[base] <= out_memR[base] + (((wc)*in_memR[addr]) >> 8);
     else if(rw == 1'd1) out_memR[base] <= out_memR[base] + (((wc)*in_memR[addr+Win]) >> 8);
     else if(dw == 1'd1) out_memR[base] <= out_memR[base] + (((wc)*in_memR[addr]) >> 8);
     else out_memR[base] <= out_memR[base] + (((wc)*in_memR[addr+Win]) >> 8);
     state <= S6;
   end
   
   S6:begin
     // wd (I00) always pulls from addr!
     out_memR[base] <= out_memR[base] + (((wd)*in_memR[addr]) >> 8);
     
     if(CHANNELS == 3) state <= S7;
     else state <= S15;
   end
 // Green Channel
  // --- GREEN CHANNEL ---
   S7:begin
     if(last == 1'd1) out_memG[base] <= ((wa)*in_memG[addr]) >> 8;
     else if(rw == 1'd1) out_memG[base] <= ((wa)*in_memG[addr + Win]) >> 8;
     else if(dw == 1'd1) out_memG[base] <= ((wa)*in_memG[addr + 1]) >> 8;
     else out_memG[base] <= ((wa)*in_memG[addr + 1 + Win]) >> 8;
     state <= S8;
   end
   
   S8:begin
     if(last == 1'd1) out_memG[base] <= out_memG[base] + (((wb)*in_memG[addr]) >> 8);
     else if(rw == 1'd1) out_memG[base] <= out_memG[base] + (((wb)*in_memG[addr]) >> 8);
     else if(dw == 1'd1) out_memG[base] <= out_memG[base] + (((wb)*in_memG[addr+1]) >> 8);
     else out_memG[base] <= out_memG[base] + (((wb)*in_memG[addr+1]) >> 8);
     state <= S9;
   end
   
   S9:begin
     if(last == 1'd1) out_memG[base] <= out_memG[base] + (((wc)*in_memG[addr]) >> 8);
     else if(rw == 1'd1) out_memG[base] <= out_memG[base] + (((wc)*in_memG[addr+Win]) >> 8);
     else if(dw == 1'd1) out_memG[base] <= out_memG[base] + (((wc)*in_memG[addr]) >> 8);
     else out_memG[base] <= out_memG[base] + (((wc)*in_memG[addr+Win]) >> 8);
     state <= S10;
   end
   
   S10:begin
     out_memG[base] <= out_memG[base] + (((wd)*in_memG[addr]) >> 8);
     state <= S11;
   end
   
   // --- BLUE CHANNEL ---
   S11:begin
     if(last == 1'd1) out_memB[base] <= ((wa)*in_memB[addr]) >> 8;
     else if(rw == 1'd1) out_memB[base] <= ((wa)*in_memB[addr + Win]) >> 8;
     else if(dw == 1'd1) out_memB[base] <= ((wa)*in_memB[addr + 1]) >> 8;
     else out_memB[base] <= ((wa)*in_memB[addr + 1 + Win]) >> 8;
     state <= S12;
   end
   
   S12:begin
     if(last == 1'd1) out_memB[base] <= out_memB[base] + (((wb)*in_memB[addr]) >> 8);
     else if(rw == 1'd1) out_memB[base] <= out_memB[base] + (((wb)*in_memB[addr]) >> 8);
     else if(dw == 1'd1) out_memB[base] <= out_memB[base] + (((wb)*in_memB[addr+1]) >> 8);
     else out_memB[base] <= out_memB[base] + (((wb)*in_memB[addr+1]) >> 8);
     state <= S13;
   end
   
   S13:begin
     if(last == 1'd1) out_memB[base] <= out_memB[base] + (((wc)*in_memB[addr]) >> 8);
     else if(rw == 1'd1) out_memB[base] <= out_memB[base] + (((wc)*in_memB[addr+Win]) >> 8);
     else if(dw == 1'd1) out_memB[base] <= out_memB[base] + (((wc)*in_memB[addr]) >> 8);
     else out_memB[base] <= out_memB[base] + (((wc)*in_memB[addr+Win]) >> 8);
     state <= S14;
   end
   
   S14:begin
     out_memB[base] <= out_memB[base] + (((wd)*in_memB[addr]) >> 8);
     state <= S15; 
   end
   
   S15: begin
   if(xout == Wout -1 && yout  == Hout - 1) done<=1'd1;
   else if(xout == Wout -1) begin
   xout<= 16'd0;
   yout<=yout + 16'd1;
   state<=S0;
   end
   else begin
   xout<=xout +16'd1;
   state<=S0;
end  
   end
   
   
   
   endcase

end



end



    always @(posedge clk) begin
        // When processing is done, and we haven't written yet
        if (done == 1'b1 && files_written == 1'b0) begin
            
            $writememh("outputR.hex", out_memR);
            $writememh("outputG.hex", out_memG);
            $writememh("outputB.hex", out_memB);
            
            files_written <= 1'b1; // Lock it so it doesn't write every clock cycle
            $display("Scaling complete! Hex files generated successfully.");
        end
    end
endmodule











