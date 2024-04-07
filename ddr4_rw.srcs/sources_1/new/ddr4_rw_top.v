// Descriptions:	    先往DDR4 的若干连续地址中分别写入数据，再读出来进行比较
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
module ddr4_rw_top(
  //从mig核输出的,为什么要输出，输出给谁（输出可能是为了方便ILA在线观测）
  output                             c0_ddr4_act_n   ,  //DDR4写操作响应信号，
	output [16:0]                      c0_ddr4_adr     ,  //DDR4地址，
	output [1:0]                       c0_ddr4_ba      ,  //DDR4 bank地址，
	output [0:0]                       c0_ddr4_bg      ,  //DDR4 bank group地址，
	output [0:0]                       c0_ddr4_cke     ,  //DDR4时钟使能，
	output [0:0]                       c0_ddr4_odt     ,  //DDR4输出驱动，
	output [0:0]                       c0_ddr4_cs_n    ,  //DDR4芯片选择，
	output [0:0]                       c0_ddr4_ck_t    ,  //DDR4时钟，
	output [0:0]                       c0_ddr4_ck_c    ,  //DDR4时钟，
	output                             c0_ddr4_reset_n ,  //DDR4复位信号，
  //inout类型，可以同时作为输入和输出信号
	inout  [1:0]                       c0_ddr4_dm_dbi_n,  //DDR4数据掩码，
	inout  [15:0]                      c0_ddr4_dq      ,  //DDR4数据，
	inout  [1:0]                       c0_ddr4_dqs_c   ,  //DDR4数据时钟，
	inout  [1:0]                       c0_ddr4_dqs_t   ,  //DDR4数据时钟，             
	
	//Differential system clocks
	input                              c0_sys_clk_p,
	input                              c0_sys_clk_n,
    input                              sys_rst_n,
	// output                             led,

  //从PS端输入
  input                              c0_ddr4_app_wdf_data,//向DDR写入的数据
  input                              ddr_wr_over_ps,//ps端写数据完成  

  //从定时器输入
  input                              fiao_wr_en,//说明定时器fiao未写满，可以继续写入
  
  //输出到定时器
  output                           c0_ddr4_app_rd_data,//从DDR读出的数据
  output                             ddr_wr_over,//写数据完成

	
	//输出到PS端的中断
	output wire                        ddr_rd_over
	
    );                
                      
 //wire define  
wire c0_ddr4_ui_clk                ;
wire c0_ddr4_ui_clk_sync_rst       ;//复位，高有效
wire c0_ddr4_app_en                ;
wire c0_ddr4_app_hi_pri            ;
wire c0_ddr4_app_wdf_end           ;
wire c0_ddr4_app_wdf_wren          ;
wire c0_ddr4_app_rd_data_end       ; 
wire c0_ddr4_app_rd_data_valid     ; 
wire c0_ddr4_app_rdy               ; 
wire c0_ddr4_app_wdf_rdy           ; 
wire [27 : 0] c0_ddr4_app_addr     ;//用户地址，读写通用
wire [2 : 0] c0_ddr4_app_cmd       ;
// wire [127 : 0] c0_ddr4_app_wdf_data;
wire [15 : 0] c0_ddr4_app_wdf_mask ;
// wire [127 : 0] c0_ddr4_app_rd_data ;



wire                  locked;               //锁相环频率稳定标志
wire                  clk_ref_i;            //DDR3参考时钟
wire                  sys_clk_i;            //MIG IP核输入时钟
wire                  clk_200;              //200M时钟
wire                  ui_clk_sync_rst;      //用户复位信号
wire                  c0_init_calib_complete; //校准完成信号
wire [20:0]           rd_cnt;               //实际读地址计数
wire [1 :0]           state;                //状态计数器
// wire [23:0]           rd_addr_cnt;         //用户读地址计数器
// wire [23:0]           wr_addr_cnt;         //用户写地址计数器


//*****************************************************
//**                    main code
//*****************************************************

// (* keep_hierarchy="yes" *)，这个是保持层次结构的意思，防止综合工具优化导致ila无法捕获信号

//读写模块
 ddr4_rw #(
    .DATA_WIDTH(16),
    .CHANNEL_NUM(32),
    .TEST_LENGTH(1024*32)
) u_ddr4_rw(
    .ddr_wr_over_ps       (ddr_wr_over_ps),
    .ui_clk               (c0_ddr4_ui_clk),                
    .ui_clk_sync_rst      (c0_ddr4_ui_clk_sync_rst),       
    .init_calib_complete  (c0_init_calib_complete),
    .app_rdy              (c0_ddr4_app_rdy),
    .app_wdf_rdy          (c0_ddr4_app_wdf_rdy),
    .app_rd_data_valid    (c0_ddr4_app_rd_data_valid),
//    .app_rd_data          (c0_ddr4_app_rd_data),
    .app_addr             (c0_ddr4_app_addr), 
    .app_en               (c0_ddr4_app_en),
    .app_wdf_wren         (c0_ddr4_app_wdf_wren),
    .app_wdf_end          (c0_ddr4_app_wdf_end),
    .app_cmd              (c0_ddr4_app_cmd),
    // .app_wdf_data         (c0_ddr4_app_wdf_data),
    .state                (state),
    // .rd_addr_cnt          (rd_addr_cnt),
    // .wr_addr_cnt          (wr_addr_cnt),
    .rd_cnt               (rd_cnt),
    
    // .error_flag           (error_flag),
    // .led                  (led),
    
    // .ddr_wr_over          (ddr_wr_over),
    .ddr_rd_over          (ddr_rd_over)
    
    );


//例化mig核
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
  .c0_ddr4_ui_clk(c0_ddr4_ui_clk),                        // output wire c0_ddr4_ui_clk            用户时钟
  .c0_ddr4_ui_clk_sync_rst(c0_ddr4_ui_clk_sync_rst),      // output wire c0_ddr4_ui_clk_sync_rst   用户复位
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
