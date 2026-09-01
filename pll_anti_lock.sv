`timescale	1ns/1ps
module	pll_anti_lock#(
	parameter 	CLK_FREQ	=	50_000_000	,
	parameter	LOCK_CNT	=	1000		,
	parameter	PLL_RST_CNT =	50
)(
	input							clkin		,
	input							rst_n		,
	input							locked		,
	output	reg						pll_rstn
);

localparam 	 	TIME_MAX	= 	(CLK_FREQ / 1000) * LOCK_CNT;
localparam 	 	PLL_RST_MAX	= 	(CLK_FREQ / 1000) * PLL_RST_CNT;

reg							locked_r1;
reg							locked_r2;

reg							rst_n_r1;
reg							rst_n_use;
reg			[31:0]			cnt_time	 = 32'd0;
reg			[31:0]			cnt_pll_rstn = 32'd0;

always @(posedge clkin or negedge rst_n)begin
	if(rst_n == 1'b0)begin
		rst_n_r1		<=		1'b0;
		rst_n_use		<=		1'b0;
	end else begin
		rst_n_r1		<=		rst_n;
		rst_n_use		<=		rst_n_r1;
	end
end

always @(posedge clkin)begin
	locked_r1		<=		locked;
	locked_r2		<=		locked_r1;
end

always @(posedge clkin)begin
	if((rst_n_use == 1'b0) | locked_r2 | (pll_rstn == 1'b0))begin
		cnt_time	<=		32'd0;
	end else if(cnt_time >= TIME_MAX-1)begin
		cnt_time	<=		TIME_MAX-1;
	end else begin
		cnt_time	<=		cnt_time + 1'd1;
	end
end

always @(posedge clkin)begin
    if(rst_n_use == 1'b0)begin
		cnt_pll_rstn	<=	32'd0;
	end else if(cnt_pll_rstn >= PLL_RST_MAX-1)begin
        cnt_pll_rstn   	<=  32'd0;
    end else if(pll_rstn == 1'b0)begin
        cnt_pll_rstn   	<= cnt_pll_rstn + 1'd1;
    end
end

always @(posedge clkin)begin
    if(rst_n_use == 1'b0)begin
		pll_rstn      	<=		1'b0;
	end else if(cnt_pll_rstn >= PLL_RST_MAX-1)begin
        pll_rstn    	<=  	1'b1;
    end else if(cnt_time >= TIME_MAX-1)begin
        pll_rstn       	<=		1'b0;
    end
end

endmodule