// Descriptions:	    ����DDR4 ������������ַ�зֱ�д�����ݣ��ٶ��������бȽ�
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
module ddr4_rw_top(
  //��mig�������,ΪʲôҪ����������˭
  output                             c0_ddr4_act_n   ,  //DDR4д������Ӧ�źţ�
	output [16:0]                      c0_ddr4_adr     ,  //DDR4��ַ��
	output [1:0]                       c0_ddr4_ba      ,  //DDR4 bank��ַ��
	output [0:0]                       c0_ddr4_bg      ,  //DDR4 bank group��ַ��
	output [0:0]                       c0_ddr4_cke     ,  //DDR4ʱ��ʹ�ܣ�
	output [0:0]                       c0_ddr4_odt     ,  //DDR4���������
	output [0:0]                       c0_ddr4_cs_n    ,  //DDR4оƬѡ��
	output [0:0]                       c0_ddr4_ck_t    ,  //DDR4ʱ�ӣ�
	output [0:0]                       c0_ddr4_ck_c    ,  //DDR4ʱ�ӣ�
	output                             c0_ddr4_reset_n ,  //DDR4��λ�źţ�
  //inout���ͣ�����ͬʱ��Ϊ���������ź�
	inout  [1:0]                       c0_ddr4_dm_dbi_n,  //DDR4�������룬
	inout  [15:0]                      c0_ddr4_dq      ,  //DDR4���ݣ�
	inout  [1:0]                       c0_ddr4_dqs_c   ,  //DDR4����ʱ�ӣ�
	inout  [1:0]                       c0_ddr4_dqs_t   ,  //DDR4����ʱ�ӣ�             
	
	//Differential system clocks
	input                              c0_sys_clk_p,
	input                              c0_sys_clk_n,
  input                              sys_rst_n,
	// output                             led,


  //��PS������
  input                              c0_ddr4_app_wdf_data,//��DDRд�������
  input                              ddr_wr_over_ps,//ps��д�������  

  //�Ӷ�ʱ������
  input                              fiao_wr_en,

  // output                             ddr_wr_over,//д������ɣ���PS�˷���

  //�������ʱ��
	output                             c0_ddr4_app_rd_data,//��DDR����������

	
	//�����PS�˵��ж�
	output wire                        ddr_rd_over
	
    );                
                      
 //wire define  

wire                 error_flag;

wire c0_ddr4_ui_clk                ;
wire c0_ddr4_ui_clk_sync_rst       ;//��λ������Ч
wire c0_ddr4_app_en                ;
wire c0_ddr4_app_hi_pri            ;
wire c0_ddr4_app_wdf_end           ;
wire c0_ddr4_app_wdf_wren          ;
wire c0_ddr4_app_rd_data_end       ; 
wire c0_ddr4_app_rd_data_valid     ; 
wire c0_ddr4_app_rdy               ; 
wire c0_ddr4_app_wdf_rdy           ; 
wire [27 : 0] c0_ddr4_app_addr     ;
wire [2 : 0] c0_ddr4_app_cmd       ;
// wire [127 : 0] c0_ddr4_app_wdf_data;
wire [15 : 0] c0_ddr4_app_wdf_mask ;
// wire [127 : 0] c0_ddr4_app_rd_data ;



wire                  locked;              //���໷Ƶ���ȶ���־
wire                  clk_ref_i;           //DDR3�ο�ʱ��
wire                  sys_clk_i;           //MIG IP������ʱ��
wire                  clk_200;             //200Mʱ��
wire                  ui_clk_sync_rst;     //�û���λ�ź�
wire                  init_calib_complete; //У׼����ź�
wire [20:0]           rd_cnt;              //ʵ�ʶ���ַ����
wire [1 :0]           state;                //״̬������
wire [23:0]           rd_addr_cnt;         //�û�����ַ������
wire [23:0]           wr_addr_cnt;         //�û�д��ַ������

//*****************************************************
//**                    main code
//*****************************************************

// (* keep_hierarchy="yes" *)������Ǳ��ֲ�νṹ����˼����ֹ�ۺϹ����Ż�����ila�޷������ź�

//��дģ��
//  ddr4_rw u_ddr4_rw(
//     .ui_clk               (c0_ddr4_ui_clk),                
//     .ui_clk_sync_rst      (c0_ddr4_ui_clk_sync_rst),       
//     .init_calib_complete  (c0_init_calib_complete),
//     .app_rdy              (c0_ddr4_app_rdy),
//     .app_wdf_rdy          (c0_ddr4_app_wdf_rdy),
//     .app_rd_data_valid    (c0_ddr4_app_rd_data_valid),
//     .app_rd_data          (c0_ddr4_app_rd_data),
    
//     // .app_addr             (c0_ddr4_app_addr), 
//     .app_en               (c0_ddr4_app_en),
//     .app_wdf_wren         (c0_ddr4_app_wdf_wren),
//     .app_wdf_end          (c0_ddr4_app_wdf_end),
//     .app_cmd              (c0_ddr4_app_cmd),
//     // .app_wdf_data         (c0_ddr4_app_wdf_data),
//     .state                (state),
//     .rd_addr_cnt          (rd_addr_cnt),
//     .wr_addr_cnt          (wr_addr_cnt),
//     .rd_cnt               (rd_cnt),
    
//     // .error_flag           (error_flag),
//     // .led                  (led),
    
//     .ddr_wr_over          (ddr_wr_over),
//     .ddr_rd_over          (ddr_rd_over)
    
//     );

ddr4_rw #(
    .DATA_WIDTH(16),
    .CHANNEL_NUM(32),
    .TEST_LENGTH(1024*32)
) u_ddr4_rw (
    .ddr_wr_over_ps(ddr_wr_over_ps),
    .ui_clk(ui_clk),
    .ui_clk_sync_rst(ui_clk_sync_rst),
    .init_calib_complete(init_calib_complete),
    .app_rdy(app_rdy),
    .app_wdf_rdy(app_wdf_rdy),
    .app_rd_data_valid(app_rd_data_valid),
    // .app_rd_data(app_rd_data),
    .fiao_wr_en(fiao_wr_en),
    .app_en(app_en),
    .app_wdf_wren(app_wdf_wren),
    .app_wdf_end(app_wdf_end),
    .app_cmd(app_cmd),
    .state(state),
    .rd_addr_cnt(rd_addr_cnt),
    .rd_cnt(rd_cnt),
    .ddr_wr_over(ddr_wr_over),
    .ddr_rd_over(ddr_rd_over)
);




//����mig��
ddr4_0 u_ddr4_0 (
  .c0_init_calib_complete(c0_init_calib_complete),        // output wire c0_init_calib_complete
  .dbg_clk(),                                             // output wire dbg_clk
  .c0_sys_clk_p(c0_sys_clk_p),                            // input wire c0_sys_clk_p
  .c0_sys_clk_n(c0_sys_clk_n),                            // input wire c0_sys_clk_n
  .dbg_bus(),                                             // output wire [511 : 0] dbg_bus
  .c0_ddr4_adr(c0_ddr4_adr),                              // output wire [16 : 0] c0_ddr4_adr
  .c0_ddr4_ba(c0_ddr4_ba),                                // output wire [1 : 0] c0_ddr4_ba
  .c0_ddr4_cke(c0_ddr4_cke),                              // output wire [0 : 0] c0_ddr4_cke
  .c0_ddr4_cs_n(c0_ddr4_cs_n),                            // output wire [0 : 0] c0_ddr4_cs_n
  .c0_ddr4_dm_dbi_n(c0_ddr4_dm_dbi_n),                    // inout wire [1 : 0] c0_ddr4_dm_dbi_n
  .c0_ddr4_dq(c0_ddr4_dq),                                // inout wire [15 : 0] c0_ddr4_dq
  .c0_ddr4_dqs_c(c0_ddr4_dqs_c),                          // inout wire [1 : 0] c0_ddr4_dqs_c
  .c0_ddr4_dqs_t(c0_ddr4_dqs_t),                          // inout wire [1 : 0] c0_ddr4_dqs_t
  .c0_ddr4_odt(c0_ddr4_odt),                              // output wire [0 : 0] c0_ddr4_odt
  .c0_ddr4_bg(c0_ddr4_bg),                                // output wire [0 : 0] c0_ddr4_bg
  .c0_ddr4_reset_n(c0_ddr4_reset_n),                      // output wire c0_ddr4_reset_n
  .c0_ddr4_act_n(c0_ddr4_act_n),                          // output wire c0_ddr4_act_n
  .c0_ddr4_ck_c(c0_ddr4_ck_c),                            // output wire [0 : 0] c0_ddr4_ck_c
  .c0_ddr4_ck_t(c0_ddr4_ck_t),                            // output wire [0 : 0] c0_ddr4_ck_t
  //user interface
  .c0_ddr4_ui_clk(c0_ddr4_ui_clk),                        // output wire c0_ddr4_ui_clk            �û�ʱ��
  .c0_ddr4_ui_clk_sync_rst(c0_ddr4_ui_clk_sync_rst),      // output wire c0_ddr4_ui_clk_sync_rst   �û���λ
  .c0_ddr4_app_en(c0_ddr4_app_en),                        // input wire c0_ddr4_app_en
  .c0_ddr4_app_hi_pri(1'b0),                              // input wire c0_ddr4_app_hi_pri
  .c0_ddr4_app_wdf_end(c0_ddr4_app_wdf_end),              // input wire c0_ddr4_app_wdf_end
  .c0_ddr4_app_wdf_wren(c0_ddr4_app_wdf_wren),            // input wire c0_ddr4_app_wdf_wren
  .c0_ddr4_app_rd_data_end(c0_ddr4_app_rd_data_end),      // output wire c0_ddr4_app_rd_data_end
  .c0_ddr4_app_rd_data_valid(c0_ddr4_app_rd_data_valid),  // output wire c0_ddr4_app_rd_data_valid
  .c0_ddr4_app_rdy(c0_ddr4_app_rdy),                      // output wire c0_ddr4_app_rdy
  .c0_ddr4_app_wdf_rdy(c0_ddr4_app_wdf_rdy),              // output wire c0_ddr4_app_wdf_rdy
  .c0_ddr4_app_addr(c0_ddr4_app_addr),                    // input wire [27 : 0] c0_ddr4_app_addr
  .c0_ddr4_app_cmd(c0_ddr4_app_cmd),                      // input wire [2 : 0] c0_ddr4_app_cmd
  .c0_ddr4_app_wdf_data(c0_ddr4_app_wdf_data),            // input wire [127 : 0] c0_ddr4_app_wdf_data
  .c0_ddr4_app_wdf_mask(16'b0),                           // input wire [15 : 0] c0_ddr4_app_wdf_mask
  .c0_ddr4_app_rd_data(c0_ddr4_app_rd_data),              // output wire [127 : 0] c0_ddr4_app_rd_data
  .sys_rst(~sys_rst_n)                                       // input wire sys_rst
);    

endmodule
