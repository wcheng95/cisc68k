`timescale 1ns/1ps

module cisc68k_tb;

    localparam logic [23:0] ROM_BASE = 24'h000000;
    localparam logic [23:0] ROM_END  = 24'h00ffff;
    localparam logic [23:0] RAM_BASE = 24'h010000;
    localparam logic [23:0] RAM_END  = 24'h01ffff;
    localparam logic [23:0] MON_ADDR = 24'hf00000;

    logic clk = 1'b0;
    logic phase = 1'b0;
    logic extReset = 1'b1;
    logic pwrUp = 1'b1;

    wire enPhi1 = ~phase;
    wire enPhi2 =  phase;

    wire        eRWn;
    wire        ASn;
    wire        LDSn;
    wire        UDSn;
    wire        E;
    wire        VMAn;
    wire        FC0;
    wire        FC1;
    wire        FC2;
    wire        BGn;
    wire        oRESETn;
    wire        oHALTEDn;
    wire [15:0] iEdb;
    wire [15:0] oEdb;
    wire [23:1] eab;

    wire [23:0] byte_addr = {eab, 1'b0};

    wire rom_sel = (byte_addr >= ROM_BASE) && (byte_addr <= ROM_END);
    wire ram_sel = (byte_addr >= RAM_BASE) && (byte_addr <= RAM_END);
    wire mon_sel = (byte_addr == MON_ADDR);

    wire [15:0] rom_data;
    wire [15:0] ram_data;
    wire        mon_done;

    wire DTACKn = (!ASn && (rom_sel || ram_sel || mon_sel)) ? 1'b0 : 1'b1;

    assign iEdb = rom_sel ? rom_data :
                  ram_sel ? ram_data :
                            16'hffff;

    always #5 clk = ~clk;

    always_ff @(posedge clk)
        phase <= ~phase;

    fx68k dut (
        .clk      (clk),
        .HALTn    (1'b1),
        .extReset (extReset),
        .pwrUp    (pwrUp),
        .enPhi1   (enPhi1),
        .enPhi2   (enPhi2),

        .eRWn     (eRWn),
        .ASn      (ASn),
        .LDSn     (LDSn),
        .UDSn     (UDSn),
        .E        (E),
        .VMAn     (VMAn),

        .FC0      (FC0),
        .FC1      (FC1),
        .FC2      (FC2),
        .BGn      (BGn),
        .oRESETn  (oRESETn),
        .oHALTEDn (oHALTEDn),

        .DTACKn   (DTACKn),
        .VPAn     (1'b1),
        .BERRn    (1'b1),
        .BRn      (1'b1),
        .BGACKn   (1'b1),
        .IPL0n    (1'b1),
        .IPL1n    (1'b1),
        .IPL2n    (1'b1),

        .iEdb     (iEdb),
        .oEdb     (oEdb),
        .eab      (eab)
    );

    rom #(
        .BASE_ADDR (ROM_BASE),
        .SIZE_BYTES(65536)
        .HEX_FILE  ("labs/rom.hex")
    ) rom0 (
        .addr (eab),
        .data (rom_data)
    );

    ram #(
        .BASE_ADDR (RAM_BASE),
        .SIZE_BYTES(65536)
    ) ram0 (
        .clk  (clk),
        .sel  (ram_sel),
        .ASn  (ASn),
        .RWn  (eRWn),
        .UDSn (UDSn),
        .LDSn (LDSn),
        .addr (eab),
        .wdata(oEdb),
        .rdata(ram_data)
    );

    monitor monitor0 (
        .clk  (clk),
        .reset(extReset),
        .sel  (mon_sel),
        .ASn  (ASn),
        .RWn  (eRWn),
        .UDSn (UDSn),
        .LDSn (LDSn),
        .wdata(oEdb),
        .done (mon_done)
    );

    initial begin
        $dumpfile("cisc68k.vcd");
        $dumpvars(0, cisc68k_tb);

        repeat (8) @(posedge clk);
        pwrUp    <= 1'b0;
        extReset <= 1'b0;
    end

    initial begin
        wait (mon_done);
        repeat (8) @(posedge clk);
        $display("RESULT: lab00 PASS");
        $finish;
    end

    initial begin
        repeat (200000) @(posedge clk);
        $fatal(1, "TIMEOUT: monitor did not receive newline");
    end

endmodule
