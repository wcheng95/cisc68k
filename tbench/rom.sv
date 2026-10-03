module rom #(
    parameter logic [23:0] BASE_ADDR = 24'h000000,
    parameter integer SIZE_BYTES = 65536,
    parameter string HEX_FILE = "labs/rom.hex"
) (
    input  wire [23:1] addr,
    output logic [15:0] data
);

    localparam integer WORDS = SIZE_BYTES / 2;
    logic [15:0] mem [0:WORDS-1];
    integer i;
    integer index;

    initial begin
        for (i = 0; i < WORDS; i = i + 1)
            mem[i] = 16'h4e71; // NOP for unused ROM
        $readmemh(HEX_FILE, mem);
    end

    always_comb begin
        index = addr - (BASE_ADDR >> 1);
        if ((index >= 0) && (index < WORDS))
            data = mem[index];
        else
            data = 16'hffff;
    end

endmodule
