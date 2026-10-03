module ram #(
    parameter logic [23:0] BASE_ADDR = 24'h010000,
    parameter integer SIZE_BYTES = 65536
) (
    input  wire        clk,
    input  wire        sel,
    input  wire        ASn,
    input  wire        RWn,
    input  wire        UDSn,
    input  wire        LDSn,
    input  wire [23:1] addr,
    input  wire [15:0] wdata,
    output logic [15:0] rdata
);

    localparam integer WORDS = SIZE_BYTES / 2;
    logic [15:0] mem [0:WORDS-1];
    integer i;
    integer index;

    initial begin
        for (i = 0; i < WORDS; i = i + 1)
            mem[i] = 16'h0000;
    end

    always_comb begin
        index = addr - (BASE_ADDR >> 1);
        if (sel && (index >= 0) && (index < WORDS))
            rdata = mem[index];
        else
            rdata = 16'hffff;
    end

    always_ff @(posedge clk) begin
        if (sel && !ASn && !RWn) begin
            if (!UDSn)
                mem[index][15:8] <= wdata[15:8];
            if (!LDSn)
                mem[index][7:0] <= wdata[7:0];
        end
    end

endmodule
