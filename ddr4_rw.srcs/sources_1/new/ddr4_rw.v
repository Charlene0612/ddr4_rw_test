// `define ILA_DDR4_RW
 module ddr4_rw #(
 parameter  L_TIME = 25'd25_000_000,
 parameter  IDLE        = 2'd0,            //空闲状态
 parameter  WRITE       = 2'd1,            //写状态
 parameter  WAIT        = 2'd2,            //读到写过度等待
 parameter  READ        = 2'd3,            //读状态
// parameter  DATA_WIDTH = 32,
// parameter  CHANNEL_NUM = 16,
// parameter  MEM_NUM = 1000,
// parameter  TEST_LENGTH = CHANNEL_NUM*MEM_NUM
// parameter  TEST_LENGTH = 64
// parameter  TEST_LENGTH  = 1000
  parameter  TEST_LENGTH  = 1024
//  parameter  TEST_LENGTH  = 10
)(          
     //MIG控制的时钟及复位
     input                    ui_clk,                //用户时钟
     input                    ui_clk_sync_rst,       //复位,高有效
     
     //从MIG得到的指令
     input                    init_calib_complete,   //DDR4初始化完成
     input                    app_rdy,               //MIG 命令接收准备好标致
     input                    app_wdf_rdy,           //MIG数据接收准备好
     input                    app_rd_data_valid,     //读数据有效
     
     //从MIG得到的数据
     input          [127:0]   app_rd_data,           //用户读数据
     
     //定时器返回的指令
     input                    fiao_wr_en,    
     
     //向MIG输出的指令
     output                   app_en,                //MIG IP发送命令使能
     output                   app_wdf_wren,          //用户写数据使能
     output                   app_wdf_end,           //突发写当前时钟最后一个数据 
     output         [2:0]     app_cmd,               //MIG IP核操作命令，读或者写
     
     //向MIG输出的数据     
     output reg     [27:0]    app_addr,              //DDR4地址，测试长度1024                     
//     output reg     [8:0]     app_addr,              //测试长度64，对应2的8次方，地址多加一位防止溢出
     output reg     [127:0]   app_wdf_data,          //用户写数据，输出到DDR
//     output reg     [DATA_WIDTH*8-1:0]   app_wdf_data,     
     
     //标记信号，可作为全局输出
     output reg     [1 :0]    state,                 //读写状态
     output reg     [23:0]    rd_addr_cnt,           //用户读地址计数
     output reg     [23:0]    wr_addr_cnt,           //用户写地址计数
     output reg     [20:0]    rd_cnt,                //实际读地址标记
     output reg               error_flag,            //读写错误标志
     output reg               led,                    //读写测试结果指示灯
     
     //写完标记，作为定时器开始读的标志
     output reg               ddr_wr_over,
     
     //读完标记，可作为ZYNQ中断信号
     output reg               ddr_rd_over
     );
 
 //parameter define
// parameter  TEST_LENGTH = 1000;
// parameter  L_TIME = 25'd25_000_000;
// parameter  IDLE        = 2'd0;            //空闲状态
// parameter  WRITE       = 2'd1;            //写状态
// parameter  WAIT        = 2'd2;            //读到写过度等待
// parameter  READ        = 2'd3;            //读状态
 
 //reg define
 reg  [24:0]  led_cnt;    //led计数
 
 //wire define
 wire         error;     //读写错误标记
 wire         rst_n;     //复位，低有效
 
  //*****************************************************
 //**                    main code
 //***************************************************** 
 
 assign rst_n = ~ui_clk_sync_rst;
 
 //读信号有效，且读出的数不是写入的数时，将错误标志位拉高
assign error = (app_rd_data_valid && ((rd_cnt + 50)!=app_rd_data));
 
 //在写状态MIG IP 命令接收和数据接收都准备好,或者在读状态命令接收准备好，此时拉高使能信号，
 assign app_en = ((state == WRITE && (app_rdy && app_wdf_rdy))
                 ||(state == READ && app_rdy)) ? 1'b1:1'b0;
                 
 //在写状态,命令接收和数据接收都准备好，此时拉高写使能
 assign app_wdf_wren = (state == WRITE && (app_rdy && app_wdf_rdy)) ? 1'b1:1'b0;
 
 //由于DDR4芯片时钟和用户时钟的分频选择4:1，突发长度为8，故两个信号相同
 assign app_wdf_end = app_wdf_wren; 
 
 //处于读的时候命令值为1，其他时候命令值为0
 assign app_cmd = (state == READ) ? 3'd1 :3'd0;  
     
 //DDR4读写逻辑实现
 always @(posedge ui_clk or negedge rst_n) begin
// always @(posedge ui_clk or negedge rst_n or posedge fiao_wr_en) begin
     if((~rst_n)||(error_flag)) begin 
         state    <= IDLE;          
//         app_wdf_data <= 128'd0;     
         app_wdf_data <= 128'd50;
         wr_addr_cnt  <= 24'd0;      
         rd_addr_cnt  <= 24'd0;       
         app_addr     <= 28'd0;
         ddr_wr_over  <= 0;          
     end
     else if(init_calib_complete)begin               //MIG IP核初始化完成
         case(state)
             IDLE:begin
                 state    <= WRITE;
//                 app_wdf_data <= 128'd0;   
                 app_wdf_data <= 128'd50;
                 wr_addr_cnt  <= 24'd0;     
                 rd_addr_cnt  <= 24'd0;       
                 app_addr     <= 28'd0; 
                 ddr_wr_over  <= 0;       
              end
             WRITE:begin
                 if(wr_addr_cnt == TEST_LENGTH - 1 &&(app_rdy && app_wdf_rdy))begin
                     state    <= WAIT;                  //写到设定的长度跳到等待状态
                     ddr_wr_over <= 1;
                 end    
                 else if(app_rdy && app_wdf_rdy)begin   //写条件满足
                     app_wdf_data <= app_wdf_data + 1;  //写数据自加
                     wr_addr_cnt  <= wr_addr_cnt + 1;   //写地址自加
                     app_addr     <= app_addr + 8;      //DDR3 地址加8=128/16;因为突发长度为8
//                     ddr_wr_over <= 0;               
                 end
                 else begin                             //写条件不满足，保持当前值
                     app_wdf_data <= app_wdf_data;      
                     wr_addr_cnt  <= wr_addr_cnt;
                     app_addr     <= app_addr;
//                     ddr_wr_over  <= ddr_wr_over; 
                 end
               end
             WAIT:begin                                                  
                 state   <= READ;                     //下一个时钟，跳到读状态
                 rd_addr_cnt <= 24'd0;                //读地址复位
                 app_addr    <= 28'd0;                //DDR4读从地址0开始
//                 ddr_wr_over <= 0; 
               end
//             READ:begin                               //读到设定的地址长度    
//                 if(rd_addr_cnt == TEST_LENGTH - 1 && app_rdy)
//                     state   <= IDLE;                   //则跳到空闲状态 
//                 else if(app_rdy)begin                  //若MIG已经准备好,则开始读
//                     rd_addr_cnt <= rd_addr_cnt + 1'd1; //用户地址每次加一
//                     app_addr    <= app_addr + 8;       //DDR3地址加8
//                 end
//                 else begin                             //若MIG没准备好,则保持原值
//                     rd_addr_cnt <= rd_addr_cnt;
//                     app_addr    <= app_addr; 
//                 end
//               end
               
             READ:begin                               //读到设定的地址长度    
                 if(rd_addr_cnt == TEST_LENGTH - 1 && app_rdy)
                     state   <= IDLE;                   //则跳到空闲状态 
                 else if(app_rdy && fiao_wr_en)begin                  //若MIG已经准备好,则开始读
                     rd_addr_cnt <= rd_addr_cnt + 1'd1; //用户地址每次加一
                     app_addr    <= app_addr + 8;       //DDR3地址加8
                 end
                 else begin                             //若MIG没准备好,则保持原值
                     rd_addr_cnt <= rd_addr_cnt;
                     app_addr    <= app_addr; 
                 end
               end  
               
             default:begin
                 state    <= IDLE;
                 app_wdf_data <= 128'd50;
//                 app_wdf_data <= 128'd0;
                 wr_addr_cnt  <= 24'd0;
                 rd_addr_cnt  <= 24'd0;
                 app_addr     <= 28'd0;
                 ddr_wr_over  <= 0;
             end
         endcase
     end
 end   
                         
 //对DDR4实际读数据个数编号计数，并输出读完标志
 always @(posedge ui_clk or negedge rst_n) begin
     if(~rst_n) begin
         rd_cnt  <= 0;  
         ddr_rd_over <= 0;            
     end
     
     //若计数到读写长度，且读有效，地址计数器则置0                                        
     else if(app_rd_data_valid && rd_cnt == TEST_LENGTH - 1)begin
          rd_cnt <= 0; 
          ddr_rd_over <= 1;            
     end
     
     //其他条件只要读有效，每个时钟自增1     
     else if (app_rd_data_valid )begin
         rd_cnt <= rd_cnt + 1;
         ddr_rd_over <= 0;
     end
 end
 
 //读写判断标志位
 always @(posedge ui_clk or negedge rst_n) begin
     if(~rst_n) 
         error_flag <= 0;
     else if(error)
         error_flag <= 1;
  end
  
 //led指示效果控制
 always @(posedge ui_clk or negedge rst_n) begin
      if((~rst_n) || (~init_calib_complete )) begin
         led_cnt <= 25'd0;
         led <= 1'b0;
     end
     else begin
         if(~error_flag)                        //读写测试正确         
             led <= 1'b1;                       //led灯常亮
          else begin                            //读写测试错误
             led_cnt <= led_cnt + 25'd1;
             if(led_cnt == L_TIME - 1'b1) begin
             led_cnt <= 25'd0;
             led <= ~led;                      //led灯闪烁
             end                    
          end
       end
 end

//`ifdef ILA_DDR4_RW
    ila_0 u_ila (
        .clk(ui_clk), // input wire clk   
    
        //待观测的信号
        .probe0(ui_clk),
//        .probe1(ui_clk_sync_rst),
        .probe1(ddr_wr_over),//1位
        .probe2(app_en),
        .probe3(app_wdf_wren),
        .probe4(app_cmd),//2:0
        .probe5(app_addr),//27:0
        .probe6(wr_addr_cnt),//23:0
        .probe7(app_wdf_data),//127:0
        .probe8(rd_addr_cnt),//23:0
        .probe9(rd_cnt),//20:0
        .probe10(app_rd_data_valid),
        .probe11(app_rd_data),//127:0
        .probe12(state),//1:0
        .probe13(ddr_rd_over)
        
    );
// `endif
 
 endmodule