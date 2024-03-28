// Descriptions:	    先往DDR4 的若干连续地址中分别写入数据，再读出来进行比较
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
module ddr4_rw_top(
    output                             c0_ddr4_act_n   ,
	output [16:0]                      c0_ddr4_adr     ,
	output [1:0]                       c0_ddr4_ba      ,
	output [0:0]                       c0_ddr4_bg      ,
	output [0:0]                       c0_ddr4_cke     ,
	output [0:0]                       c0_ddr4_odt     ,
	output [0:0]                       c0_ddr4_cs_n    ,
	output [0:0]                       c0_ddr4_ck_t    ,
	output [0:0]                       c0_ddr4_ck_c    ,
	output                             c0_ddr4_reset_n ,
	inout  [1:0]                       c0_ddr4_dm_dbi_n,
	inout  [15:0]                      c0_ddr4_dq      ,
	inout  [1:0]                       c0_ddr4_dqs_c   ,
	inout  [1:0]                       c0_ddr4_dqs_t   ,               
	
	//Differential system clocks
	input                              c0_sys_clk_p,
	input                              c0_sys_clk_n,
//	output[1:0]                        led,
	output                             led,
//	output                             c0_ddr4_app_rd_data,
	input                              sys_rst_n,
	
	//输出到定时器的写数据完成
	output                             ddr_wr_over,
	
	//输出到PS端的中断
	output                             ddr_rd_over
	
    );                
                      
 //wire define  

wire                 error_flag;

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
wire [27 : 0] c0_ddr4_app_addr     ;
wire [2 : 0] c0_ddr4_app_cmd       ;
wire [127 : 0] c0_ddr4_app_wdf_data;
wire [15 : 0] c0_ddr4_app_wdf_mask ;
wire [127 : 0] c0_ddr4_app_rd_data ;



wire                  locked;              //锁相环频率稳定标志
wire                  clk_ref_i;           //DDR3参考时钟
wire                  sys_clk_i;           //MIG IP核输入时钟
wire                  clk_200;             //200M时钟
wire                  ui_clk_sync_rst;     //用户复位信号
wire                  init_calib_complete; //校准完成信号
wire [20:0]           rd_cnt;              //实际读地址计数
wire [1 :0]           state;                //状态计数器
wire [23:0]           rd_addr_cnt;         //用户读地址计数器
wire [23:0]           wr_addr_cnt;         //用户写地址计数器

//*****************************************************
//**                    main code
//*****************************************************

(* keep_hierarchy="yes" *)
//读写模块
 ddr4_rw u_ddr4_rw(
    .ui_clk               (c0_ddr4_ui_clk),                
    .ui_clk_sync_rst      (c0_ddr4_ui_clk_sync_rst),       
    .init_calib_complete  (c0_init_calib_complete),
    .app_rdy              (c0_ddr4_app_rdy),
    .app_wdf_rdy          (c0_ddr4_app_wdf_rdy),
    .app_rd_data_valid    (c0_ddr4_app_rd_data_valid),
    .app_rd_data          (c0_ddr4_app_rd_data),
    
    .app_addr             (c0_ddr4_app_addr),
    .app_en               (c0_ddr4_app_en),
    .app_wdf_wren         (c0_ddr4_app_wdf_wren),
    .app_wdf_end          (c0_ddr4_app_wdf_end),
    .app_cmd              (c0_ddr4_app_cmd),
    .app_wdf_data         (c0_ddr4_app_wdf_data),
    .state                (state),
    .rd_addr_cnt          (rd_addr_cnt),
    .wr_addr_cnt          (wr_addr_cnt),
    .rd_cnt               (rd_cnt),
    
    .error_flag           (error_flag),
    .led                  (led),
    
    .ddr_wr_over          (ddr_wr_over),
    .ddr_rd_over          (ddr_rd_over)
    
    );
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
