`timescale 1ns / 1ps
module HM5(LED,O_red,O_green,O_blue,O_hs,O_vs,button1,button2,clk,rst);
output [7:0] LED;
output O_red,O_green,O_blue,O_hs,O_vs;
input button1;		//右player
input button2;		//左player
input clk,rst;
wire divclk;
wire click1,click2;
wire [1:0] LED_state;

div d1(divclk,clk,rst);
button b1(click1,button1,clk,rst);
button b2(click2,button2,clk,rst);
FSM f1(LED,LED_state,click1,click2,divclk,clk,rst);
VGA V1(clk,rst,LED,LED_state,O_red,O_green,O_blue,O_hs,O_vs);
endmodule

//除頻
module div(divclk,clk,rst);

output divclk;
input clk,rst;
reg [25:0] divclkcnt;

assign divclk = divclkcnt[24];

always@(posedge clk or negedge rst)
begin
	if(rst)
		divclkcnt = 0;
	else
		divclkcnt = divclkcnt+1;
end
endmodule

//解彈跳
module button(click,in,clk,rst);
output reg click;
input in,clk,rst;
	
reg [23:0] decnt;
parameter bound =24'hffffff;
always@(posedge clk or negedge rst)
begin
	if(rst)
	begin
		decnt <= 0;
		click <= 0;
	end
	else 
	begin
		if(in)
		begin
		if(decnt < bound)
		begin
			decnt <= decnt+1;
			click <= 0;
		end
		else 
		begin
			decnt <= decnt;
			click <= 1;
		end
	end
	else 
	begin
		decnt <= 0;
		click <= 0;
	end
	end
end
endmodule

//FSM
module FSM(LED,LED_state,button1,button2,divclk,clk,rst);
output [7:0] LED;
reg [7:0] LED;
input button1,button2;
input divclk,clk,rst;
parameter S0 = 3'b000 ,			//初始發球
			 S1 = 3'b001 ,		//判斷右player是否擊中
			 S2 = 3'b010 ,		//判斷左player是否擊中
			 S3 = 3'b011 ,		//顯示分數，等待右發
			 S4 = 3'b100 ;		//顯示分數，等待左發
parameter LED_S0 = 2'b00 ,		//初始 LED <= 8'b0000_0000
			 LED_S1 = 2'b01 ,	//LED 右移
			 LED_S2 = 2'b10 ,	//LED 左移
			 LED_S3 = 2'b11 ;	//顯示分數
reg [2:0] state;					//FSM狀態
output [1:0] LED_state;
reg [1:0] LED_state;				//LED狀態
reg [3:0] score1 = 0;			//右player分數
reg [3:0] score2 = 0;			//左player分數
reg model = 0;					//判斷LED移動模式或LED顯示分數模式

always@(posedge clk or negedge rst)
begin
if(rst)
begin
	state <= S0;
	score1 <= 0;
	score2 <= 0;
end
else
	case(state)
		S0:begin
			if(button1 == 1)			//右發
			begin
				LED_state <= LED_S2;
				state <= S2;
			end
			else if(button2 == 1)	    //左發
				  begin
					  LED_state <= LED_S1;
					  state <= S1;
				  end				
				  else					//等待發球
				  begin
					  LED_state <= LED_S0;
					  state <= state;
					  score1 <= 0;
	                  score2 <= 0;
				  end
			end
			
		S1:begin
		    if((LED < 8'b1000_0000) && (button1 == 1))      //右早
			begin
				LED_state <= LED_S0;
				score2 <= score2+1;
				state <= S4;
			end
			else if((LED == 8'b0000_0000) && (button2 == 0)) //右漏
			begin
				LED_state <= LED_S0;
				score2 <= score2+1;
				state <= S4;
			end
			if((LED == 8'b1000_0000) && (button1 == 1))		 //判斷右player是否打中
			begin
				LED_state <= LED_S2;
				state <= S2;
			end
			end
			
		S2:begin
		    if((LED > 8'b0000_0001) && (button2 == 1))      //左早
			begin
				LED_state <= LED_S0;
				score1 <= score1+1;
				state <= S3;
			end
			else if((LED == 8'b0000_0000) && (button1 == 0)) //左漏
			begin
				LED_state <= LED_S0;
				score1 <= score1+1;
				state <= S3;
			end
			if((LED == 8'b0000_0001) && (button2 == 1))		 //判斷左player是否打中
			begin
				LED_state <= LED_S1;
				state <= S1;
			end
			end
			
		S3:begin
			if(button1 == 1)		//右發
			begin
				LED_state <= LED_S2;
				state <= S2;
			end
			else
				LED_state <= LED_S3;
			end
			
		S4:begin
			if(button2 == 1)		//左發
			begin
				LED_state <= LED_S1;
				state <= S1;
			end
			else
				LED_state <= LED_S3;
			end	
	endcase
end

//LED_state		
always@(posedge divclk or negedge rst)
begin
if(rst)
    model <= 0;
else
begin
case(LED_state)
	LED_S0:begin		//初始狀態
		LED <= 8'b0000_0000;
		end
	LED_S1:begin		//LED右移
	    if(model)
	    begin
	        LED <= 8'b0000_0001;
	        model <= 0;
	    end
	    else if(LED == 8'b1000_0000)
	        LED <= 8'b0000_0000;
		else if(LED == 8'b0000_0000)
			LED <= {LED[6:0],1'b1};
		else
			LED <= {LED[6:0],LED[7]};
		end
	LED_S2:begin		//LED左移
	    if(model)
	    begin
	        LED <= 8'b1000_0000;
	        model <= 0;
	    end
	    else if(LED == 8'b0000_0001)
	        LED <= 8'b0000_0000;
		else if(LED == 8'b0000_0000)
			LED <= {1'b1,LED[7:1]};
		else
			LED <= {LED[0],LED[7:1]};
	    end
   LED_S3:begin		//LED顯示分數
        LED[7:4] <= score1;
        LED[3:0] <= score2;
        model <= 1;
       end
endcase
end
end
endmodule

module VGA
(
    input           I_clk , //系統50MHz時鐘
    input           I_rst_n , //系統復位
    input    [7:0]   LED,
    input    [1:0]   LED_state,
    output    reg    O_red , // VGA紅色分量
    output    reg    O_green , // VGA綠色分量
    output    reg    O_blue , // VGA藍色分量
    output           O_hs , // VGA行同步信號
    output           O_vs       // VGA場同步信號
);
//分辨率為640*480時行時序各個參數定義
parameter        C_H_SYNC_PULSE =    96   ,
                C_H_BACK_PORCH       =    48   ,
                C_H_ACTIVE_TIME      =    640 ,
                C_H_FRONT_PORCH      =    16   ,
                C_H_LINE_PERIOD      =    800 ;

//分辨率為640*480時場時序各個參數定義               
parameter        C_V_SYNC_PULSE =    2    ,
                C_V_BACK_PORCH       =    33   ,
                C_V_ACTIVE_TIME      =    480 ,
                C_V_FRONT_PORCH      =    10   ,
                C_V_FRAME_PERIOD     =    525 ;
                
parameter        C_COLOR_BAR_WIDTH = C_H_ACTIVE_TIME / 8   ; 
parameter        C_COLOR_BAR_HIGH = C_V_ACTIVE_TIME / 5   ; 
reg [7:0]      vgaled;

reg [ 11 : 0 ] R_h_cnt ; //行時序計數器
reg [ 11 : 0 ] R_v_cnt ; //列時序計數器
reg              [1:0] R_clk_25M ;

wire             W_active_flag ; //激活標誌，當這個信號為1時RGB的數據可以顯示在屏幕上

//////////////////////////////////////////////////////////////////
 //功能： 產生25MHz的像素時鐘
//////////////////////////////////////////////////////////////////
 always @( posedge I_clk or  negedge I_rst_n)
 begin 
    if (I_rst_n)
        R_clk_25M    <=   2'b0 ; 
    else 
        R_clk_25M    <=  R_clk_25M+1 ;     
 end 
//////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
 //功能：產生行時序
//////////////////////////////////////////////////////////////////
 always @( posedge R_clk_25M[1] or  negedge I_rst_n)
 begin 
    if (I_rst_n)
        R_h_cnt <=   12'd0 ; 
    else  if (R_h_cnt == C_H_LINE_PERIOD - 1'b1) 
        R_h_cnt <=   12'd0 ; 
    else 
        R_h_cnt <= R_h_cnt + 1'b1 ;                 
end                

assign O_hs = (R_h_cnt < C_H_SYNC_PULSE) ? 1'b0 : 1'b1 ; 
 //////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////
 //功能：產生場時序
//////////////////////////////////////////////////////////////////
 always @( posedge R_clk_25M[1] or  negedge I_rst_n)
 begin 
    if (I_rst_n)
        R_v_cnt <=   12'd0 ; 
    else  if (R_v_cnt == C_V_FRAME_PERIOD - 1'b1) 
        R_v_cnt <=   12'd0 ; 
    else  if (R_h_cnt == C_H_LINE_PERIOD - 1'b1) 
        R_v_cnt <= R_v_cnt + 1'b1 ; 
    else 
        R_v_cnt <=   R_v_cnt ;                        
 end                

assign O_vs = (R_v_cnt < C_V_SYNC_PULSE) ? 1'b0 : 1'b1 ; 
 //////////////////////////////////////////////////////////////////  
 
always @( posedge R_clk_25M or  negedge I_rst_n)
begin
    if(I_rst_n)
      vgaled <= 0;
    else if(LED[0]==1 && (LED_state <= 2'b10))
        vgaled<=0;
    else if(LED[1]==1 && (LED_state <= 2'b10))
        vgaled<=1;
    else if(LED[2]==1 && (LED_state <= 2'b10))
        vgaled<=2;
    else if(LED[3]==1 && (LED_state <= 2'b10))
        vgaled<=3;
    else if(LED[4]==1 && (LED_state <= 2'b10))
        vgaled<=4;
    else if(LED[5]==1 && (LED_state <= 2'b10))
        vgaled<=5;
    else if(LED[6]==1 && (LED_state <= 2'b10))
        vgaled<=6;
    else if(LED[7]==1 && (LED_state <= 2'b10))
        vgaled<=7;
end

assign W_active_flag = (R_h_cnt >= (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*vgaled)) && 
                        (R_h_cnt <= (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*(vgaled+1))) &&  
                        (R_v_cnt >= (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_COLOR_BAR_HIGH*2)) && 
                        (R_v_cnt <= (C_V_SYNC_PULSE + C_V_BACK_PORCH + C_COLOR_BAR_HIGH*3)) ;                     

//////////////////////////////////////////////////////////////////
 //功能：把顯示器屏幕分成8個縱列，每個縱列的寬度是80 
//////////////////////////////////////////////////////////////////
 always @( posedge R_clk_25M[1] or  negedge I_rst_n)
 begin 
    if (I_rst_n) 
         begin 
            O_red    <=   1'b0 ; 
            O_green <=   1'b0 ; 
            O_blue <=   1'b0 ; 
        end 
    else  if (W_active_flag)     
         begin 
            if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH)) //紅色彩條
                begin 
                    O_red    <=   1'b1 ; // 紅色彩條把紅色分量全部給1，綠色和藍色給0 
                    O_green <=   1'b0 ; 
                    O_blue <=   1'b0 ; 
                end 
            else  if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 2 )) //綠色彩條
                begin 
                    O_red    <=   1'b0 ; 
                    O_green <=   1'b1 ; // 綠色彩條把綠色分量全部給1，紅色和藍色分量給0 
                    O_blue <=   1'b0 ; 
                end  
            else  if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 3 )) //藍色彩條
                begin 
                    O_red    <=   1'b1 ; 
                    O_green <=   1'b0 ; 
                    O_blue <=   1'b0 ; // 藍色彩條把藍色分量全部給1，紅色和綠分量給0
                 end  
            else  if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH*4 )) //白色彩條
                begin 
                    O_red    <=   1'b0 ; // 白色彩條是有紅綠藍三基色混合而成
                    O_green <=   1'b1 ; // 所以白色彩條要把紅綠藍三個分量全部給1 
                    O_blue <=   1'b0 ; 
                end  
            else  if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 5 )) //黑色彩條
                begin 
                    O_red    <=   1'b1 ; // 黑色彩條就是把紅綠藍所有分量全部給0 
                    O_green <=  1'b0 ; 
                    O_blue <=  1'b0 ; 
                end  
            else  if (R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 6 )) //黃色彩條
                begin 
                    O_red    <=   1'b0 ; // 黃色彩條是有紅綠兩種顏色混合而成
                    O_green <=   1'b1 ; // 所以黃色彩條要把紅綠兩個分量給1 
                    O_blue <=   1'b0 ; // 藍色分量給0
                 end  
            else  if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 7 )) //紫色彩條
                begin 
                    O_red    <=   1'b1 ; // 紫色彩條是有紅藍兩種顏色混合而成
                    O_green <=   1'b0 ; // 所以紫色彩條要把紅藍兩個分量給1 
                    O_blue <=   1'b0 ; // 綠色分量給0
                 end  
            else  if(R_h_cnt < (C_H_SYNC_PULSE + C_H_BACK_PORCH + C_COLOR_BAR_WIDTH* 8 )) //青色彩條
                begin 
                    O_red    <=   1'b0 ; // 青色彩條是由藍綠兩種顏色混合而成
                    O_green <=   1'b1 ; // 所以青色彩條要把藍綠兩個分量給1 
                    O_blue <=   1'b0 ; // 紅色分量給0
                 end                    
        end 
    else 
        begin 
            O_red    <=   1'b0 ; 
            O_green <=   1'b0 ; 
            O_blue <=   1'b0 ; 
        end            
end 
endmodule
