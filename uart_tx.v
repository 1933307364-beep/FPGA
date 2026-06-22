`timescale  1ns/1ps
module  uart_tx#(
    parameter   BAUD_RATE   =   115200      ,
    parameter   CLK_FREQ    =   50_000_000
)(
    input                       clkin   ,
    input                       rst_n   ,
    input                       tx_flag ,
    input       [7:0]           tx_data ,
    output  reg                 rs232_tx,
    output  reg                 tx_busy ,
    output  reg                 tx_done
);

localparam  baud_max    =   CLK_FREQ/BAUD_RATE;

localparam  IDLE        =   4'b0000;
localparam  START       =   4'b0001;
localparam  DATA_SEND   =   4'b0011;
localparam  STOP        =   4'b0010;
localparam  DONE        =   4'b0110;
localparam  END         =   4'b0111;

reg     [31:0]      cnt_st;
reg     [3:0]       bit_cnt;
reg     [3:0]       state , next_state;

always @ (posedge clkin)begin
    if(rst_n == 1'b0)begin
        state   <=  IDLE;
    end else begin
        state   <=  next_state;
    end
end

always @ (*)begin
    case(state)
        IDLE    :   if(tx_flag)begin
                        next_state      =   START;
                    end else begin
                        next_state      =   IDLE;
                    end
        START   :   if(cnt_st >= baud_max-1)begin
                        next_state      =   DATA_SEND;
                    end else begin
                        next_state      =   START;
                    end
        DATA_SEND:  if(bit_cnt >= 4'd7 & cnt_st >= baud_max-1)begin
                        next_state      =   STOP;
                    end else begin
                        next_state      =   DATA_SEND;
                    end
        STOP    :   if(cnt_st >= baud_max-1)begin
                        next_state      =   DONE;
                    end else begin
                        next_state      =   STOP;
                    end
        DONE    :   next_state  =   IDLE;
        default :   next_state  =   IDLE;
    endcase
end

always @ (posedge clkin)begin
    if(rst_n == 1'b0)begin
        cnt_st      <=      32'd0;
    end else if(cnt_st >= baud_max-1)begin
        cnt_st      <=      32'd0;
    end else if(state !== next_state)begin
        cnt_st      <=      32'd0;
    end else begin
        cnt_st      <=      cnt_st + 1'd1;
    end
end

always @ (posedge clkin)begin
    if(rst_n == 1'b0)begin
        bit_cnt     <=      4'd0;
    end else if(state == DATA_SEND & cnt_st >= baud_max-1)begin
        bit_cnt     <=      bit_cnt + 1'd1;
    end else if(state == DATA_SEND)begin
        bit_cnt     <=      bit_cnt;
    end else begin
        bit_cnt     <=      4'd0;
    end
end

reg     [7:0]       data_reg;

always @ (posedge clkin)begin
    if(rst_n == 1'b0)begin
        data_reg    <=      8'd0;
    end else if(state == IDLE & tx_flag)begin
        data_reg    <=      tx_data;
    end
end

always @ (posedge clkin)begin
    if(rst_n == 1'b0)begin
        rs232_tx    <=      1'b1;
        tx_busy     <=      1'b0;
        tx_done     <=      1'b0;
    end else begin
        case(state)
            IDLE    :   begin
                            rs232_tx    <=      1'b1;
                            tx_busy     <=      1'b0;
                            tx_done     <=      1'b0;
                        end
            START   :   begin
                            rs232_tx    <=      1'b0;
                            tx_busy     <=      1'b1;
                            tx_done     <=      1'b0;
                        end
            DATA_SEND:  begin
                            rs232_tx    <=      data_reg[bit_cnt];
                            tx_busy     <=      1'b1;
                            tx_done     <=      1'b0;
                        end
            STOP    :   begin
                            rs232_tx    <=      1'b1;
                            tx_busy     <=      1'b1;
                            tx_done     <=      1'b0;
                        end
            DONE    :   begin
                            rs232_tx    <=      1'b1;
                            tx_busy     <=      1'b1;
                            tx_done     <=      1'b1;
                        end
            default :   begin
                            rs232_tx    <=      1'b1;
                            tx_busy     <=      1'b1;
                            tx_done     <=      1'b0;
                        end
        endcase
    end
end

endmodule