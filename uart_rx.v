`timescale  1ns/1ps
module  uart_rx#(
    parameter   BAUD_RATE   =   115200      ,
    parameter   CLK_FREQ    =   50_000_000
)(
    input                       clkin       ,
    input                       rst_n       ,
    input                       rs232_rx    ,
    output  reg                 rx_flag     ,
    output  reg [7:0]           rx_data
);

localparam  baud_max    =   CLK_FREQ/BAUD_RATE;

localparam  IDLE            =   4'b0000;
localparam  START           =   4'b0001;
localparam  DATA_RECEVIE    =   4'b0011;
localparam  STOP            =   4'b0010;
localparam  DONE            =   4'b0110;
localparam  ERROR           =   4'b0111;

reg     [31:0]      cnt_st;
reg     [3:0]       bit_cnt;
reg     [3:0]       state , next_state;
reg                 rx_start;
reg                 rs232_rx_r1 , rs232_rx_r2 , rs232_rx_r3;

always @ (posedge clkin)begin
    rs232_rx_r1     <=      rs232_rx;
    rs232_rx_r2     <=      rs232_rx_r1;
    rs232_rx_r3     <=      rs232_rx_r2;
    if(rst_n == 1'b0)begin
        rx_start    <=      1'b0;
    end else begin
        rx_start    <=      ~rs232_rx_r2 & rs232_rx_r3;
    end
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
    end else if(state == DATA_RECEVIE & cnt_st >= baud_max-1)begin
        bit_cnt     <=      bit_cnt + 1'd1;
    end else if(state == DATA_RECEVIE)begin
        bit_cnt     <=      bit_cnt;
    end else begin
        bit_cnt     <=      4'd0;
    end
end

always @ (posedge clkin)begin
    if(rst_n == 1'b0)begin
        state   <=  IDLE;
    end else begin
        state   <=  next_state;
    end
end

reg             sampling_flag;

always @ (posedge clkin)begin
    if(rst_n == 1'b0)begin
        sampling_flag   <=  1'b0;
    end else if(state !== IDLE)begin
        if(cnt_st == baud_max/2-1)begin
            sampling_flag   <=  1'b1;
        end else begin
            sampling_flag   <=  1'b0;
        end
    end else begin
        sampling_flag   <=  1'b0;
    end
end

always @ (*)begin
    case(state)
        IDLE    :   if(rx_start)begin
                        next_state      =   START;
                    end else begin
                        next_state      =   IDLE;
                    end
        START   :   if(cnt_st >= baud_max-1)begin
                        next_state      =   DATA_RECEVIE;
                    end else if(sampling_flag & rs232_rx_r3)begin
                        next_state      =   ERROR;
                    end else begin
                        next_state      =   START;
                    end
        DATA_RECEVIE:if(bit_cnt >= 4'd7 & cnt_st >= baud_max-1)begin
                        next_state      =   STOP;
                    end else begin
                        next_state      =   DATA_RECEVIE;
                    end
        STOP    :   if(cnt_st >= baud_max/4)begin
                        next_state      =   DONE;
                    end else if(~rs232_rx_r3 & sampling_flag)begin
                        next_state      =   ERROR;
                    end else begin
                        next_state      =   STOP;
                    end
        ERROR   :   if(rs232_rx_r3)begin
                        next_state      =   IDLE;
                    end else begin
                        next_state      =   ERROR;
                    end
        DONE    :   next_state  =   IDLE;
        default :   next_state  =   IDLE;
    endcase
end

always @ (posedge clkin)begin
    if(rst_n == 1'b0)begin
        rx_flag     <=      1'b0;
        rx_data     <=      8'd0;
    end else begin
        case(state)
            IDLE    :   begin
                            rx_flag     <=      1'b0;
                            rx_data     <=      8'd0;
                        end
            START   :   begin
                            rx_flag     <=      1'b0;
                            rx_data     <=      8'd0;
                        end
            DATA_RECEVIE:begin
                            rx_flag     <=      1'b0;
                            if(sampling_flag)begin
                                rx_data <=      {rs232_rx_r3 , rx_data[7:1]};
                            end else begin
                                rx_data <=      rx_data;
                            end
                        end
            STOP    :   begin
                            rx_flag     <=      1'b0;
                            rx_data     <=      rx_data;
                        end
            ERROR   :   begin
                            rx_flag     <=      1'b0;
                            rx_data     <=      8'd0;
                        end
            DONE    :   begin
                            rx_flag     <=      1'b1;
                            rx_data     <=      rx_data;
                        end
            default :   begin
                            rx_flag     <=      1'b0;
                            rx_data     <=      8'd0;
                        end
        endcase
    end
end

endmodule