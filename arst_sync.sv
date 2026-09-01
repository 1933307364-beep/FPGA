`timescale 1ns/1ps  
module arst_sync (
    input   clk     ,
    input   arstn   ,
    output  rstn    
);

reg  rst_sync1 = 1'b0;
reg  rst_sync2 = 1'b0;
reg  rst_sync3 = 1'b0;

always @(posedge clk or negedge arstn)
    if(!arstn) begin
        rst_sync1 <= 1'b0;
        rst_sync2 <= 1'b0;
        rst_sync3 <= 1'b0;
    end
    else begin
        rst_sync1 <= 1'b1;
        rst_sync2 <= rst_sync1;
        rst_sync3 <= rst_sync2;
    end

assign rstn = rst_sync3;

endmodule
