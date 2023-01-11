`timescale 1ns / 1ps
module HM6(LED,Dinout,button,clk,rst);
output LED;
reg LED;
input clk,rst;
input button;
inout Dinout;
wire Din;
wire Dout;
reg en;

assign Dinout = en ? Dout : 1'bz;
assign Dout = 0;
assign Din = en ? 1'b1 : Dinout;
always@(posedge clk or negedge rst)
begin
    if(rst)
        en <= 1'b0;
    else if(button == 1)
            en <= 1'b1;
         else
            en <= 1'b0;
end

always@(posedge clk or negedge rst)
begin
    if(rst)
        LED <= 0;
    else if(Din == 0)
           LED <= 1;
         else
           LED <= 0;
end
endmodule
