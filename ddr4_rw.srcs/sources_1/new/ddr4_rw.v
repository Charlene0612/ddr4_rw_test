// `define ILA_DDR4_RW
 module ddr4_rw #(
//  parameter  L_TIME = 25'd25_000_000,
  parameter  IDLE        = 2'd0,            //����״̬
  parameter  WRITE       = 2'd1,            //д״̬
  parameter  WAIT        = 2'd2,            //����д���ȵȴ�
  parameter  READ        = 2'd3,            //��״̬
  parameter  DATA_WIDTH = 16,
  parameter  CHANNEL_NUM = 32,
// parameter  MEM_NUM = 1000,
// parameter  TEST_LENGTH = CHANNEL_NUM*MEM_NUM
// parameter  TEST_LENGTH = 64
// parameter  TEST_LENGTH  = 1000
  parameter  TEST_LENGTH  = 1024*32
//  parameter  TEST_LENGTH  = 10
)(          
     //��PS�˵õ���ָ��
     input                    ddr_wr_over_ps,        //PS�˷�����ϣ����Խ����״̬����AXI GPIO��һ���ߵ�ƽ�����ź�
     
     //MIG���Ƶ�ʱ�Ӽ���λ
     input                    ui_clk,                //�û�ʱ��
     input                    ui_clk_sync_rst,       //��λ,����Ч
     
     //��MIG�õ���ָ��
     input                    init_calib_complete,   //DDR4��ʼ�����
     input                    app_rdy,               //MIG�������׼����
     input                    app_wdf_rdy,           //MIG���ݽ���׼����
     input                    app_rd_data_valid,     //��������Ч
     
     //��MIG�õ�������
    //  input          [127:0]   app_rd_data,           //�û�������
    //  input          [DATA_WIDTH*8-1:0]   app_rd_data, 
     
     //��ʱ�����ص�ָ��
     input                    fiao_wr_en,    
     
     //��MIG�����ָ��
     output                   app_en,                //MIG IP��������ʹ�ܣ���д���̶���Ҫ
     output                   app_wdf_wren,          //�û�д����ʹ�ܣ�ͬʱ����PS�ˣ�ָʾ��ʼд����
     output                   app_wdf_end,           //ͻ��д��ǰʱ�����һ������ 
     output         [2:0]     app_cmd,               //MIG IP�˲������������д
     
     //��MIG��������ݣ���Ϊͨ��AXI�ӿڴ�PS�˷���  
    //  output reg     [27:0]    app_addr,              //DDR4��ַ�����Գ���1024 
     output reg     [27:0]    app_addr,              //���ʵ�ʳ���1024*32����Ӧ2��15�η���ͻ�����ȹ̶�Ϊ8����Ӧ2��18�η������Ե�ַ28λ����      
    //  output reg     [127:0]   app_wdf_data,          //�û�д���ݣ������DDR
    //  output reg     [DATA_WIDTH*8-1:0]   app_wdf_data,     //������
     
     //����źţ�����Ϊȫ�����
     output reg     [1 :0]    state,                 //��д״̬��0�����У�1��д��2���ȴ���3����
    //  output reg     [23:0]    rd_addr_cnt,           //�û�����ַ����
    //  output reg     [23:0]    wr_addr_cnt,           //�û�д��ַ��������ΪPS�˲���
     output reg     [20:0]    rd_cnt,                //ʵ�ʶ���ַ���
    //  output reg               error_flag,            //��д�����־
    //  output reg               led,                    //��д���Խ��ָʾ��
     
     //д���ǣ���Ϊ��ʱ����ʼ���ı�־
     output reg               ddr_wr_over,              
     
     //�����ǣ�����ΪPS���ж��ź�
     output reg               ddr_rd_over            //������
     );
 


 //reg define
//  reg  [24:0]  led_cnt;    //led����
 
 //wire define
//  wire         error;     //��д������
 wire         rst_n;     //��λ������Ч
 
  //*****************************************************
 //**                    main code
 //***************************************************** 
 
 assign rst_n = ~ui_clk_sync_rst;
 
 //���ź���Ч���Ҷ�����������д�����ʱ���������־λ����
// assign error = (app_rd_data_valid && ((rd_cnt + 50)!=app_rd_data));
 
 //��д״̬MIG IP ������պ����ݽ��ն�׼����,�����ڶ�״̬�������׼���ã���ʱ����appʹ���ź�
 assign app_en = ((state == WRITE && (app_rdy && app_wdf_rdy))
                 ||(state == READ && app_rdy)) ? 1'b1:1'b0;
                 
 //��д״̬,������պ����ݽ��ն�׼���ã���ʱ����дʹ�ܣ���state�й�
 assign app_wdf_wren = (state == WRITE && (app_rdy && app_wdf_rdy)) ? 1'b1:1'b0;
 
 //����DDR4оƬʱ�Ӻ��û�ʱ�ӵķ�Ƶѡ��4:1��ͻ������Ϊ8���������ź���ͬ
 assign app_wdf_end = app_wdf_wren; 
 
 //���ڶ���ʱ������ֵΪ1������ʱ������ֵΪ0
 assign app_cmd = (state == READ) ? 3'd1 :3'd0;  
     
 //DDR4��д�߼�ʵ��
 always @(posedge ui_clk or negedge rst_n) begin 
    if(~rst_n) begin
         state    <= IDLE;          
        //  app_wdf_data <= 128'd0;     
        //  app_wdf_data <= 128'd50;
        //  wr_addr_cnt  <= 24'd0;      
        //  rd_addr_cnt  <= 24'd0;  
        //  rd_cnt       <= 20'd0;                      //�����ݼ�����λ 
        //  app_addr     <= 28'd0;
         ddr_wr_over  <= 0;          
     end
     else if(init_calib_complete)begin               //MIG IP�˳�ʼ�����
         case(state)
             IDLE:begin
                 state    <= WRITE;
//                 app_wdf_data <= 128'd0;   
                //  app_wdf_data <= 128'd50;
                //  wr_addr_cnt  <= 24'd0;     
                //  rd_addr_cnt  <= 24'd0; 
                //  rd_cnt       <= 20'd0;       
                 app_addr     <= 28'd0; 
                 ddr_wr_over  <= 0;       
              end
             WRITE:begin
//                  if(wr_addr_cnt == TEST_LENGTH - 1 &&(app_rdy && app_wdf_rdy))begin
//                      state    <= WAIT;                  //д���趨�ĳ��������ȴ�״̬
//                      ddr_wr_over <= 1;
//                  end else if(app_rdy && app_wdf_rdy)begin   //д��������
//                     //  app_wdf_data <= app_wdf_data + 1;  //д�����Լ�
//                      wr_addr_cnt  <= wr_addr_cnt + 1;   //д��ַ�Լ�
//                     //  app_addr     <= app_addr + 8;      //DDR3 ��ַ��8=128/16;��Ϊͻ������Ϊ8
// //                     ddr_wr_over <= 0;               
//                  end else begin                             //д���������㣬���ֵ�ǰֵ
//                     //  app_wdf_data <= app_wdf_data;      
//                      wr_addr_cnt  <= wr_addr_cnt;
//                     //  app_addr     <= app_addr;
// //                     ddr_wr_over  <= ddr_wr_over; 
//                  end
                    if(ddr_wr_over_ps)begin
                        state    <= WAIT;                  //д���趨�ĳ��������ȴ�״̬
                        ddr_wr_over <= 1;
                    end else begin
                        state    <= WRITE;                  
                        ddr_wr_over <= 0;
                    end
               end
             WAIT:begin                                                  
                 state   <= READ;                     //��һ��ʱ�ӣ�������״̬
                //  rd_addr_cnt <= 24'd0;                //��������λ
                //  rd_cnt       <= 20'd0; 
                 app_addr    <= 28'd0;                //DDR4����ַҪ��ô��������PS�˵�д��ַ
                 ddr_wr_over <= 1; 
               end
               
             READ:begin                               //�����趨�ĵ�ַ����    
                //  if(rd_addr_cnt == TEST_LENGTH - 1 && app_rdy)
                 if(rd_cnt == TEST_LENGTH - 1 && app_rdy)
                     state   <= IDLE;                   //����������״̬ 
                 else if(app_rdy && fiao_wr_en)begin                  //��MIG�Ѿ�׼����,��ʼ��
                    //��һ���ָ�MIG���Ͷ����ݵĵ�ַ
                    //  rd_addr_cnt <= rd_addr_cnt + 1'd1; //�û���ַÿ�μ�һ
                     app_addr    <= app_addr + 8;       //����ַÿ�α仯
                 end
                 else begin                             //��MIGû׼����,�򱣳�ԭֵ
                    //  rd_addr_cnt <= rd_addr_cnt;
                     app_addr    <= app_addr; 
                 end
               end  
               
             default:begin
                 state    <= IDLE;
                //  app_wdf_data <= 128'd50;
//                 app_wdf_data <= 128'd0;
                //  wr_addr_cnt  <= 24'd0;
                //  rd_addr_cnt  <= 24'd0;
                //  app_addr     <= 28'd0;
                 app_addr     <= 28'd0; 
                 ddr_wr_over  <= 0;
             end
         endcase
     end
 end   
                         
 //��DDR4ʵ�ʶ����ݸ�����ż���������������־
 always @(posedge ui_clk or negedge rst_n) begin
     if(~rst_n) begin
        rd_cnt  <= 0;  
        ddr_rd_over <= 0;            
     end else if (state == READ) begin
        //����������д���ȣ��Ҷ���Ч����ַ����������0 
        if(fiao_wr_en && app_rd_data_valid && rd_cnt == TEST_LENGTH - 1)begin
            rd_cnt <= 0; 
            ddr_rd_over <= 1;            
        end
        //��������ֻҪ����Ч��ÿ��ʱ������1     
        else if (fiao_wr_en && app_rd_data_valid )begin
            rd_cnt <= rd_cnt + 1;
            ddr_rd_over <= 0;
        end
     end else begin
        rd_cnt <= 0;
        ddr_rd_over <= 0;
     end

     
     
                                            
 end
 
//  //��д�жϱ�־λ
//  always @(posedge ui_clk or negedge rst_n) begin
//      if(~rst_n) 
//          error_flag <= 0;
//      else if(error)
//          error_flag <= 1;
//   end
  
//  //ledָʾЧ������
//  always @(posedge ui_clk or negedge rst_n) begin
//       if((~rst_n) || (~init_calib_complete )) begin
//          led_cnt <= 25'd0;
//          led <= 1'b0;
//      end
//      else begin
//          if(~error_flag)                        //��д������ȷ         
//              led <= 1'b1;                       //led�Ƴ���
//           else begin                            //��д���Դ���
//              led_cnt <= led_cnt + 25'd1;
//              if(led_cnt == L_TIME - 1'b1) begin
//              led_cnt <= 25'd0;
//              led <= ~led;                      //led����˸
//              end                    
//           end
//        end
//  end

// //`ifdef ILA_DDR4_RW
//     ila_0 u_ila (
//         .clk(ui_clk), // input wire clk   
    
//         //���۲���ź�
//         .probe0(ui_clk),
// //        .probe1(ui_clk_sync_rst),
//         .probe1(ddr_wr_over),//1λ
//         .probe2(app_en),
//         .probe3(app_wdf_wren),
//         .probe4(app_cmd),//2:0
//         .probe5(app_addr),//27:0
//         .probe6(wr_addr_cnt),//23:0
//         .probe7(app_wdf_data),//127:0
//         .probe8(rd_addr_cnt),//23:0
//         .probe9(rd_cnt),//20:0
//         .probe10(app_rd_data_valid),
//         .probe11(app_rd_data),//127:0
//         .probe12(state),//1:0
//         .probe13(ddr_rd_over)
        
//     );
// // `endif
 
 endmodule