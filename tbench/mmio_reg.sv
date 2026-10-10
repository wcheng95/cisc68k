module mmio_reg (
    input  wire        clk,
    input  wire        reset,
    input  wire        sel,
    input  wire        ASn,
    input  wire        RWn,
    input  wire        UDSn,
    input  wire        LDSn,
    input  wire [15:0] wdata,
    output logic [15:0] rdata
);

    logic [15:0] reg16;
    logic        handled;

    assign rdata = reg16;

    always @(posedge clk) begin
        if (reset) begin
            reg16   <= 16'h0000;
            handled <= 1'b0;
        end else begin
            if (ASn)
                handled <= 1'b0;

            if (sel && !ASn && !RWn && !handled) begin
                handled <= 1'b1;

                if (!UDSn)
                    reg16[15:8] <= wdata[15:8];

                if (!LDSn)
                    reg16[7:0] <= wdata[7:0];
            end
        end
    end

endmodule
