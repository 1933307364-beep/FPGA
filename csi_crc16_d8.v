`timescale	1ns/1ps
module csi_crc16_d8#(
    parameter   MUX     =       "lit"
)(
    input				clk			,
	input				rst_n		,
		
	input				pre_de		,
	input 		[7:0] 	pre_data	,
	
	input		[7:0]  data_len	,	
	
	output	reg			crc_de		,		
	output 	reg	[15:0] 	crc			
);

wire	[7:0]	data			;

reg		[31:0]	data_cnt		;

reg		[15:0] 	crcIn			;
wire	[15:0]	crcOut			;

// assign data = {pre_data[0],pre_data[1],pre_data[2],pre_data[3],pre_data[4],pre_data[5],pre_data[6],pre_data[7]};

generate    if(MUX == "big")begin

    assign	data = {<<{pre_data[7:0]}};
    
    always@(posedge clk)begin
	   if(rst_n == 1'b0) begin
	   	   crc <= 16'd0;
	   end else if(data_cnt == (data_len - 1'b1) & pre_de)begin
	   	   crc <=  {<<{crcOut}};
	   	   // crc <=  {crcOut[0],crcOut[1],crcOut[2],crcOut[3],crcOut[4],crcOut[5],crcOut[6],crcOut[7],crcOut[8],crcOut[9],crcOut[10],crcOut[11],crcOut[12],crcOut[13],crcOut[14],crcOut[15]};
	   end else begin
	   	   crc <= 16'd0;
	   end
    end
    
end else begin

    assign  data = pre_data;
    
    always@(posedge clk)begin
	   if(rst_n == 1'b0) begin
	   	   crc <= 16'd0;
	   end else if(data_cnt == (data_len - 1'b1) & pre_de)begin
	   	   crc <=  crcOut;
	   end else begin
	   	   crc <= 16'd0;
	   end
    end
    
end
endgenerate

always@(posedge clk)begin
	if(rst_n == 1'b0)begin
		data_cnt <= 32'd0;
	end else if(data_cnt == (data_len - 1'b1) & pre_de)begin
		data_cnt <= 32'd0;
	end else if(pre_de)begin
		data_cnt <= data_cnt + 32'b1;
	end else begin
		data_cnt <= data_cnt;
	end
end

always@(posedge clk)begin
	if(rst_n == 1'b0)begin 
        crcIn <= 16'hFFFF;
 	end else if(crc_de)begin
		crcIn <= 16'hFFFF;
    end else if(pre_de)begin
        crcIn <= crcOut;	
	end else begin
		crcIn <= crcIn;
	end
end

generate    if(MUX == "big")begin

    assign crcOut[0] = crcIn[8] ^ crcIn[12] ^ data[0] ^ data[4];
    assign crcOut[1] = crcIn[9] ^ crcIn[13] ^ data[1] ^ data[5];
    assign crcOut[2] = crcIn[10] ^ crcIn[14] ^ data[2] ^ data[6];
    assign crcOut[3] = crcIn[11] ^ crcIn[15] ^ data[3] ^ data[7];
    assign crcOut[4] = crcIn[12] ^ data[4];
    assign crcOut[5] = crcIn[8] ^ crcIn[12] ^ crcIn[13] ^ data[0] ^ data[4] ^ data[5];
    assign crcOut[6] = crcIn[9] ^ crcIn[13] ^ crcIn[14] ^ data[1] ^ data[5] ^ data[6];
    assign crcOut[7] = crcIn[10] ^ crcIn[14] ^ crcIn[15] ^ data[2] ^ data[6] ^ data[7];
    assign crcOut[8] = crcIn[0] ^ crcIn[11] ^ crcIn[15] ^ data[3] ^ data[7];
    assign crcOut[9] = crcIn[1] ^ crcIn[12] ^ data[4];
    assign crcOut[10] = crcIn[2] ^ crcIn[13] ^ data[5];
    assign crcOut[11] = crcIn[3] ^ crcIn[14] ^ data[6];
    assign crcOut[12] = crcIn[4] ^ crcIn[8] ^ crcIn[12] ^ crcIn[15] ^ data[0] ^ data[4] ^ data[7];
    assign crcOut[13] = crcIn[5] ^ crcIn[9] ^ crcIn[13] ^ data[1] ^ data[5];
    assign crcOut[14] = crcIn[6] ^ crcIn[10] ^ crcIn[14] ^ data[2] ^ data[6];
    assign crcOut[15] = crcIn[7] ^ crcIn[11] ^ crcIn[15] ^ data[3] ^ data[7];
    
end else begin

    assign crcOut[0] = crcIn[0] ^ crcIn[1] ^ crcIn[2] ^ crcIn[3] ^ crcIn[4] ^ crcIn[5] ^ crcIn[6] ^ crcIn[7] ^ crcIn[8] ^ data[0] ^ data[1] ^ data[2] ^ data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[7];
    assign crcOut[1] = crcIn[9];
    assign crcOut[2] = crcIn[10];
    assign crcOut[3] = crcIn[11];
    assign crcOut[4] = crcIn[12];
    assign crcOut[5] = crcIn[13];
    assign crcOut[6] = crcIn[0] ^ crcIn[14] ^ data[0];
    assign crcOut[7] = crcIn[0] ^ crcIn[1] ^ crcIn[15] ^ data[0] ^ data[1];
    assign crcOut[8] = crcIn[1] ^ crcIn[2] ^ data[1] ^ data[2];
    assign crcOut[9] = crcIn[2] ^ crcIn[3] ^ data[2] ^ data[3];
    assign crcOut[10] = crcIn[3] ^ crcIn[4] ^ data[3] ^ data[4];
    assign crcOut[11] = crcIn[4] ^ crcIn[5] ^ data[4] ^ data[5];
    assign crcOut[12] = crcIn[5] ^ crcIn[6] ^ data[5] ^ data[6];
    assign crcOut[13] = crcIn[6] ^ crcIn[7] ^ data[6] ^ data[7];
    assign crcOut[14] = crcIn[0] ^ crcIn[1] ^ crcIn[2] ^ crcIn[3] ^ crcIn[4] ^ crcIn[5] ^ crcIn[6] ^ data[0] ^ data[1] ^ data[2] ^ data[3] ^ data[4] ^ data[5] ^ data[6];
    assign crcOut[15] = crcIn[0] ^ crcIn[1] ^ crcIn[2] ^ crcIn[3] ^ crcIn[4] ^ crcIn[5] ^ crcIn[6] ^ crcIn[7] ^ data[0] ^ data[1] ^ data[2] ^ data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[7];

end
endgenerate
always@(posedge clk)begin
	if(rst_n == 1'b0)begin 
		crc_de <= 1'b0;
	end else if(data_cnt == (data_len - 1'b1) & pre_de)begin
		crc_de <= 1'b1;
	end else begin
		crc_de <= 1'b0;
	end
end
	
endmodule