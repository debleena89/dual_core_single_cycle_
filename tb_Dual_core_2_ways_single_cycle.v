`ifndef PROC_BRAM_MACROS
`define PROC_BRAM_MACROS 1
`define PROGRAM_BRAM_MEMORY dut.memory.BRAM_inst.ram

`define REGISTER_FILE0 dut.CORES[0].core.ID.registers.register_file
`define REGISTER_FILE1 dut.CORES[1].core.ID.registers.register_file

`define CURRENT_PC0 dut.CORES[0].core.FI.PC_reg
`define CURRENT_PC1 dut.CORES[1].core.FI.PC_reg
`endif


module tb_Dual_core_2_ways_single_cycle();
    parameter NUM_CORES=2;
    parameter DATA_WIDTH=32;
    parameter ADDRESS_BITS=32;
    parameter MEM_ADDRESS_BITS=14;
    parameter SCAN_CYCLES_MIN=0;
    parameter SCAN_CYCLES_MAX=1000;
    parameter PROGRAM="/home/debleena/CC/work/instructions1.dat"; // set path-name of hex instruction file
    parameter LOG_FILE="Dual_core_2_ways_single_cycle.log";

    genvar i;
    integer x;
    integer log_file;
    integer core_i;
    integer core_finish_count;

    reg clock;
    reg reset;
    reg start;
    reg [NUM_CORES*ADDRESS_BITS-1:0] program_address;

    wire [NUM_CORES*ADDRESS_BITS-1:0] PC;
    wire [ADDRESS_BITS-1:0] PC1;
    wire [ADDRESS_BITS-1:0] PC2;

    assign PC1 = PC[0 +: ADDRESS_BITS];
    assign PC2 = PC[ADDRESS_BITS +: ADDRESS_BITS];

    reg scan;

    
  integer core0_finished;
  integer core1_finished;
    
  localparam TEST_NAME0="./instructions1.dat"; // set path-name of hex instruction file
  localparam TEST_NAME1="./instructions1.dat"; // set path-name of hex instruction file


    Dual_core_2_ways_single_cycle #(
        .NUM_CORES(NUM_CORES),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_BITS(ADDRESS_BITS),
        .MEM_ADDRESS_BITS(MEM_ADDRESS_BITS),
        .SCAN_CYCLES_MIN(SCAN_CYCLES_MIN),
        .SCAN_CYCLES_MAX(SCAN_CYCLES_MAX)
    ) dut(
        .clock(clock),
        .reset(reset),
        .start(start),
        .program_address(program_address),
        .PC(PC),
        .scan(scan)
    );


// Clock generator
    always #1 clock = ~clock;

// Initialize program memory
    initial begin
        for (x = 0; x < 2 ** MEM_ADDRESS_BITS; x = x+1) begin
            dut.memory.BRAM_inst.ram[x] = 32'd0;
        end
        for (x = 0; x < 32; x = x+1) begin
           `REGISTER_FILE0[x] = 32'd0; `REGISTER_FILE1[x] = 32'd0;
        end
        $readmemh(PROGRAM, dut.memory.BRAM_inst.ram);
/* <-- Added By ISI team */
       dut.memory.BRAM_inst.ram[10] = 32'd1000;
       dut.memory.BRAM_inst.ram[11] = 32'd1050;
     dut.memory.BRAM_inst.ram[5] = 32'd2000;
       dut.memory.BRAM_inst.ram[10] = 32'd2050;
       dut.memory.BRAM_inst.ram[11] = 32'd2080;
       dut.memory.BRAM_inst.ram[12] = 32'd3000;
       dut.memory.BRAM_inst.ram[13] = 32'd1000;
       dut.memory.BRAM_inst.ram[49] = 32'd1050;
       dut.memory.BRAM_inst.ram[50] = 32'd2000;
       dut.memory.BRAM_inst.ram[51] = 32'd2050;
     dut.memory.BRAM_inst.ram[52] = 32'd2080;
       dut.memory.BRAM_inst.ram[53] = 32'd3000;
       dut.memory.BRAM_inst.ram[54] = 32'd1000;
       dut.memory.BRAM_inst.ram[55] = 32'd1050;        
       dut.memory.BRAM_inst.ram[56] = 32'd2080;
       dut.memory.BRAM_inst.ram[57] = 32'd3000;
       dut.memory.BRAM_inst.ram[58] = 32'd1000;
       dut.memory.BRAM_inst.ram[59] = 32'd1050;
       dut.memory.BRAM_inst.ram[60] = 32'd2000;
       dut.memory.BRAM_inst.ram[61] = 32'd2050;
       dut.memory.BRAM_inst.ram[62] = 32'd2080;
       dut.memory.BRAM_inst.ram[63] = 32'd3000;
    /* Added By ISI team --> */
        
       
    end


    integer start_time;
    integer end_time;
    integer total_cycles;

    initial begin
        clock = 1;
        reset = 1;
        scan = 0;
        start = 0;
        core_finish_count = 0;
        for (core_i = 0; core_i < NUM_CORES; core_i = core_i+1) begin
            program_address[core_i*ADDRESS_BITS +: ADDRESS_BITS] = core_i*32'h0000_0000;
        end

        #10 #1 reset = 0;
        start = 1;
        start_time = $time;
        #1

            start = 0;

        log_file = $fopen(LOG_FILE, "a+");
        if (!log_file) begin
            $display("Could not open log file... Exiting!");
            $finish();
        end
        #600 $finish();
    end

    always begin
        // Check pass/fail condition every 1000 cycles so that check does not slow
        // down simulation to much
        #1
         

if ((`CURRENT_PC0 == 32'h00000b0 || `CURRENT_PC0 == 32'h00000b0) && core0_finished !== 1) begin
                end_time = $time;
                total_cycles = (end_time-start_time)/2;
                #100 // Wait for pipeline to empty
                    core_finish_count = core_finish_count+1;
                core0_finished = 1;
                $display("\nCore 0 <PROGRAM 1 NAME HERE> is finished!\n");
                $display("\nRun Time (cycles): %d", total_cycles);
                $fdisplay(log_file, "\nRun Time (cycles): %d", total_cycles);
                if (`REGISTER_FILE0[9] == 32'h0000000) begin
                    $display("<PROGRAM 1 NAME HERE>:\nTest Passed!\n\n");
                    $fdisplay(log_file, "<PROGRAM 1 NAME HERE>:\nTest Passed!\n\n");
                end else begin
                    $display("<PROGRAM 1 NAME HERE>:\nTest Failed!\n\n");
                    $fdisplay(log_file, "<PROGRAM 1 NAME HERE>:\nTest Failed!\n\n");
                    $display("Dumping reg file states:");
                    $fdisplay(log_file, "Dumping reg file states:");
                    $display("Reg Index, Value");
                    $fdisplay(log_file, "Reg Index, Value");
                    for (x = 0; x < 32; x = x+1) begin
                        $display("%d: %h", x, `REGISTER_FILE0[x]);
                        $fdisplay(log_file, "%d: %h", x, `REGISTER_FILE0[x]);
                    end
                    $display("");
                    $fdisplay(log_file, "");
                end // pass/fail check

                if (core_finish_count == NUM_CORES) begin
                    $display("Finished running tests for %d cores\n", core_finish_count);
                    $fclose(log_file);
                    $stop();
                end
            end


if ((`CURRENT_PC1 == 32'h0000168 || `CURRENT_PC1 == 32'h0000168) && core1_finished !== 1) begin
                end_time = $time;
                total_cycles = (end_time-start_time)/2;
                #100 // Wait for pipeline to empty
                    core_finish_count = core_finish_count+1;
                core1_finished = 1;
                $display("\nCore 1 <PROGRAM 2 NAME HERE> is finished!\n");
                $display("\nRun Time (cycles): %d", total_cycles);
                $fdisplay(log_file, "\nRun Time (cycles): %d", total_cycles);
                if (`REGISTER_FILE1[9] == 32'h0000000) begin
                    $display("<PROGRAM 2 NAME HERE>:\nTest Passed!\n\n");
                    $fdisplay(log_file, "<PROGRAM 2 NAME HERE>:\nTest Passed!\n\n");
                end else begin
                    $display("<PROGRAM 2 NAME HERE>:\nTest Failed!\n\n");
                    $fdisplay(log_file, "<PROGRAM 2 NAME HERE>:\nTest Failed!\n\n");
                    $display("Dumping reg file states:");
                    $fdisplay(log_file, "Dumping reg file states:");
                    $display("Reg Index, Value");
                    $fdisplay(log_file, "Reg Index, Value");
                    for (x = 0; x < 32; x = x+1) begin 
                        $display("%d: %h", x, `REGISTER_FILE1[x]);
                        $fdisplay(log_file, "%d: %h", x, `REGISTER_FILE1[x]);
                    end
                    $display("");
                    $fdisplay(log_file, "");
                end // pass/fail check

                if (core_finish_count == NUM_CORES) begin
                    $display("Finished running tests for %d cores\n", core_finish_count);
                    $fclose(log_file);
                    $stop();
                end
            end

    end // always

endmodule
