module irq_autovec #(
    parameter logic [2:0] LEVEL = 3'd3
) (
    input  wire        clk,
    input  wire        reset,

    input  wire        sel,
    input  wire        ASn,
    input  wire        RWn,
    input  wire        UDSn,
    input  wire        LDSn,

    input  wire        FC0,
    input  wire        FC1,
    input  wire        FC2,

    output wire        IPL0n,
    output wire        IPL1n,
    output wire        IPL2n,
    output wire        VPAn
);

    logic pending;
    logic write_handled;
    logic iack_seen;

    wire iack = ({FC2, FC1, FC0} == 3'b111);

    /*
     * Any write to the trigger register raises one fixed-level interrupt.
     * Keep it asserted through the complete interrupt-acknowledge cycle.
     */
    always @(posedge clk) begin
        if (reset) begin
            pending       <= 1'b0;
            write_handled <= 1'b0;
            iack_seen     <= 1'b0;
        end else begin
            if (ASn)
                write_handled <= 1'b0;

            if (sel && !ASn && !RWn && (!UDSn || !LDSn) && !write_handled) begin
                pending       <= 1'b1;
                write_handled <= 1'b1;
            end

            if (pending && iack && !ASn)
                iack_seen <= 1'b1;

            if (iack_seen && ASn) begin
                pending   <= 1'b0;
                iack_seen <= 1'b0;
            end
        end
    end

    /*
     * IPL inputs are active-low encoded. fx68k internally inverts them.
     * LEVEL=3 -> pins 100 -> internal interrupt level 011.
     */
    wire [2:0] ipl_n = pending ? ~LEVEL : 3'b111;

    assign {IPL2n, IPL1n, IPL0n} = ipl_n;

    /*
     * Pull VPA low during interrupt acknowledge to request autovectoring.
     */
    assign VPAn = (pending && iack) ? 1'b0 : 1'b1;

endmodule
