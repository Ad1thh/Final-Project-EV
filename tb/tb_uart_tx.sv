`timescale 1ns / 1ps

module tb_uart_tx;

    // Testbench signals
    logic clk;
    logic rstn;
    logic valid;
    logic ready;
    logic [7:0] tx_data;
    logic tx;

    // Parameters for testing
    localparam int CLK_FREQ = 25000000;
    localparam int BAUD_RATE = 2500000; // Faster baud rate for simulation (divider = 10)
    localparam int BAUD_DIVIDER = CLK_FREQ / BAUD_RATE;
    
    // Calculate expected bit period in ns
    localparam real BIT_PERIOD_NS = (1.0 / BAUD_RATE) * 1e9;
    localparam real CLK_PERIOD_NS = (1.0 / CLK_FREQ) * 1e9;

    // Instantiate the DUT with NONE parity first
    uart_tx #(
        .BAUD_DIVIDER(BAUD_DIVIDER),
        .PARITY("NONE")
    ) dut_none (
        .clk(clk),
        .rstn(rstn),
        .valid(valid),
        .ready(ready),
        .tx_data(tx_data),
        .tx(tx)
    );

    // Clock generation (25 MHz)
    always #(CLK_PERIOD_NS/2.0) clk = ~clk;

    // Test sequence
    initial begin
        $display("=================================================");
        $display("Starting UART TX Testbench");
        $display("BAUD_DIVIDER = %0d", BAUD_DIVIDER);
        $display("Expected Bit Period = %0.2f ns", BIT_PERIOD_NS);
        $display("=================================================");

        // Initialize
        clk = 0;
        rstn = 0;
        valid = 0;
        tx_data = 8'h00;

        // Reset
        #100;
        rstn = 1;
        #100;

        // Check IDLE state
        if (tx !== 1'b1) $fatal(1, "TEST FAILED: TX should be HIGH in IDLE state");
        if (ready !== 1'b1) $fatal(1, "TEST FAILED: Ready should be HIGH in IDLE state");
        $display("IDLE state verified.");

        // Send a byte (0x55 - 01010101)
        @(posedge clk);
        tx_data = 8'h55;
        valid = 1;
        
        @(posedge clk);
        valid = 0; // Deassert valid
        
        if (ready !== 1'b0) $fatal(1, "TEST FAILED: Ready should be LOW immediately after accepting valid");

        // Start bit check
        #(BIT_PERIOD_NS/2.0); // Sample in the middle of the bit
        if (tx !== 1'b0) $fatal(1, "TEST FAILED: Start bit should be LOW. Actual: %b", tx);
        $display("Start bit verified.");

        // Data bits check (LSB first for 0x55: 1, 0, 1, 0, 1, 0, 1, 0)
        for (int i = 0; i < 8; i++) begin
            #(BIT_PERIOD_NS);
            if (tx !== tx_data[i]) $fatal(1, "TEST FAILED: Data bit %0d mismatched. Expected: %b, Actual: %b", i, tx_data[i], tx);
        end
        $display("Data bits verified.");

        // Stop bit check (Parity is NONE, so this should be STOP)
        #(BIT_PERIOD_NS);
        if (tx !== 1'b1) $fatal(1, "TEST FAILED: Stop bit should be HIGH. Actual: %b", tx);
        $display("Stop bit verified.");

        // Wait for ready to assert again
        wait(ready == 1'b1);
        $display("UART returned to ready state.");

        $display("=================================================");
        $display("ALL TESTS PASSED SUCCESSFULLY");
        $display("=================================================");
        $finish;
    end

    // Dump waves
    initial begin
        $dumpfile("tb_uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);
    end

endmodule
