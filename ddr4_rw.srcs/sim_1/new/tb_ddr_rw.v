`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/07 14:27:03
// Design Name: 
// Module Name: tb_ddr_rw
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_ddr4_rw(

    );

    // Inputs
    reg ddr_wr_over_ps;
    reg ui_clk;
    reg ui_clk_sync_rst;
    reg init_calib_complete;
    reg app_rdy;
    reg app_wdf_rdy;
    reg app_rd_data_valid;
    reg fiao_wr_en;

    // Outputs
    wire app_en;
    wire app_wdf_wren;
    wire app_wdf_end;
    wire [2:0] app_cmd;
//    reg [27:0] app_addr;
//    reg [20:0] rd_cnt;
//    reg ddr_wr_over;
//    reg ddr_rd_over;
//    reg [1:0] state;
    wire [27:0] app_addr;
    wire [20:0] rd_cnt;
    wire ddr_wr_over;
    wire ddr_rd_over;
    wire [1:0] state;    

    // Instantiate the Unit Under Test (UUT)
    ddr4_rw #(
    .DATA_WIDTH(16),
    .CHANNEL_NUM(32),
//    .TEST_LENGTH(1024*32)
    .TEST_LENGTH(32)
    ) u_ddr4_rw (
        .ddr_wr_over_ps(ddr_wr_over_ps), 
        .ui_clk(ui_clk), 
        .ui_clk_sync_rst(ui_clk_sync_rst), 
        .init_calib_complete(init_calib_complete), 
        .app_rdy(app_rdy), 
        .app_wdf_rdy(app_wdf_rdy), 
        .app_rd_data_valid(app_rd_data_valid), 
        .fiao_wr_en(fiao_wr_en), 
        .app_en(app_en), 
        .app_wdf_wren(app_wdf_wren), 
        .app_wdf_end(app_wdf_end), 
        .app_cmd(app_cmd), 
        .app_addr(app_addr), 
        .rd_cnt(rd_cnt), 
        .ddr_wr_over(ddr_wr_over), 
        .ddr_rd_over(ddr_rd_over), 
        .state(state)
    );

    initial begin
        // Initialize Inputs
        ddr_wr_over_ps = 0;
        ui_clk = 0;
        ui_clk_sync_rst = 1;
        init_calib_complete = 0;
        app_rdy = 0;
        app_wdf_rdy = 0;
        app_rd_data_valid = 0;
        fiao_wr_en = 0;

        // Wait 100 ns for global reset to finish
        #100;
        ui_clk_sync_rst = 0;

        // Add stimulus here
        #100;
        init_calib_complete = 1;
        app_rdy = 1;
        app_wdf_rdy = 1;
        #500;
        ddr_wr_over_ps = 1;
        app_rd_data_valid = 1;
        fiao_wr_en = 1;
        #100;
        app_rd_data_valid = 0;
        #100;
        app_rd_data_valid = 1;

    end

    always begin
        #5 ui_clk = ~ui_clk;
    end

endmodule
