module monitor (
    input  wire        clk,
    input  wire        reset,
    input  wire        sel,
    input  wire        ASn,
    input  wire        RWn,
    input  wire        UDSn,
    input  wire        LDSn,
    input  wire [15:0] wdata,
    output logic       done
);

    logic handled;

    always @(posedge clk) begin
        if (reset) begin
            handled <= 1'b0;
            done    <= 1'b0;
        end else begin
            if (ASn)
                handled <= 1'b0;

            if (sel && !ASn && !RWn && (!UDSn || !LDSn) && !handled) begin
                handled <= 1'b1;

                if (!UDSn) begin
                    $write("%c", wdata[15:8]);
                    if (wdata[15:8] == 8'h0a)
                        done <= 1'b1;
                end

                if (!LDSn) begin
                    $write("%c", wdata[7:0]);
                    if (wdata[7:0] == 8'h0a)
                        done <= 1'b1;
                end
            end
        end
    end

endmodule
