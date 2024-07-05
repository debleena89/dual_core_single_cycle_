
/** @module : Default_Project
 *  @author : Adaptive & Secure Computing Systems (ASCS) Laboratory

 *  Copyright (c) 2019 BRISC-V (ASCS/ECE/BU)
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.

 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

module Dual_core_2_ways_single_cycle #(
    parameter NUM_CORES=2,
    parameter DATA_WIDTH=32,
    parameter ADDRESS_BITS=32,
    parameter ADDRESS_WIDTH=32,
    parameter MEM_ADDRESS_BITS=10,
    parameter SCAN_CYCLES_MIN=0,
    parameter SCAN_CYCLES_MAX=1000
)(
    input clock,
    input reset,

    input start,
    input [NUM_CORES*ADDRESS_BITS-1:0] program_address,

    output [NUM_CORES*ADDRESS_BITS-1:0] PC,

    input scan
);

    localparam MSG_BITS=4;
    localparam L2_OFFSET=2;
    localparam L2_WIDTH=DATA_WIDTH*(1 << L2_OFFSET);

//fetch stage interface
    wire [NUM_CORES-1:0] fetch_read;
    wire [NUM_CORES*ADDRESS_BITS-1:0] fetch_address_out;
    wire [NUM_CORES*DATA_WIDTH-1:0] fetch_data_in;
    wire [NUM_CORES*ADDRESS_BITS-1:0] fetch_address_in;
    wire [NUM_CORES-1:0] fetch_valid;
    wire [NUM_CORES-1:0] fetch_ready;
//memory stage interface
    wire [NUM_CORES-1:0] memory_read;
    wire [NUM_CORES-1:0] memory_write;
    wire [NUM_CORES*DATA_WIDTH/8-1:0] memory_byte_en;
    wire [NUM_CORES*ADDRESS_BITS-1:0] memory_address_out;
    wire [NUM_CORES*DATA_WIDTH-1:0] memory_data_out;
    wire [NUM_CORES*DATA_WIDTH-1:0] memory_data_in;
    wire [NUM_CORES*ADDRESS_BITS-1:0] memory_address_in;
    wire [NUM_CORES-1:0] memory_valid;
    wire [NUM_CORES-1:0] memory_ready;
//instruction memory/cache interface
    wire [NUM_CORES*DATA_WIDTH-1:0] i_mem_data_out;
    wire [NUM_CORES*ADDRESS_BITS-1:0] i_mem_address_out;
    wire [NUM_CORES-1:0] i_mem_valid;
    wire [NUM_CORES-1:0] i_mem_ready;
    wire [NUM_CORES-1:0] i_mem_read;
    wire [NUM_CORES*ADDRESS_BITS-1:0] i_mem_address_in;
//data memory/cache interface
    wire [NUM_CORES*DATA_WIDTH-1:0] d_mem_data_out;
    wire [NUM_CORES*ADDRESS_BITS-1:0] d_mem_address_out;
    wire [NUM_CORES-1:0] d_mem_valid;
    wire [NUM_CORES-1:0] d_mem_ready;
    wire [NUM_CORES-1:0] d_mem_read;
    wire [NUM_CORES-1:0] d_mem_write;
    wire [NUM_CORES*DATA_WIDTH/8-1:0] d_mem_byte_en;
    wire [NUM_CORES*ADDRESS_BITS-1:0] d_mem_address_in;
    wire [NUM_CORES*DATA_WIDTH-1:0] d_mem_data_in;
//cache hierarchy to main memory interface signals
    wire [MSG_BITS-1:0] intf2cachehier_msg;
    wire [ADDRESS_BITS-1:0] intf2cachehier_address;
    wire [L2_WIDTH-1:0] intf2cachehier_data;
    wire [MSG_BITS-1:0] cachehier2intf_msg;
    wire [ADDRESS_BITS-1:0] cachehier2intf_address;
    wire [L2_WIDTH-1:0] cachehier2intf_data;
//main memory interface to main memory signals
    wire [MSG_BITS-1:0] mem2intf_msg;
    wire [ADDRESS_BITS-1:0] mem2intf_address;
    wire [DATA_WIDTH-1:0] mem2intf_data;
    wire [MSG_BITS-1:0] intf2mem_msg;
    wire [ADDRESS_BITS-1:0] intf2mem_address;
    wire [DATA_WIDTH-1:0] intf2mem_data;


    genvar i;
    generate
        for (i = 0; i < NUM_CORES; i = i+1) begin : CORES
            assign PC[i*ADDRESS_WIDTH +: ADDRESS_WIDTH] = fetch_address_in[i*ADDRESS_WIDTH +: ADDRESS_WIDTH];
            single_cycle_core #(
                .CORE(i),
                .DATA_WIDTH(DATA_WIDTH),
                .ADDRESS_BITS(ADDRESS_BITS),
                .SCAN_CYCLES_MIN(SCAN_CYCLES_MIN),
                .SCAN_CYCLES_MAX(SCAN_CYCLES_MAX),
                .RESET_PC(0)//debleena i*16
            ) core(
                .clock(clock),
                .reset(reset),
                .start(start),
                .program_address(program_address[i*ADDRESS_BITS +: ADDRESS_BITS]),
                //memory interface
                .fetch_valid(fetch_valid[i +: 1]),
                .fetch_ready(fetch_ready[i +: 1]),
                .fetch_data_in(fetch_data_in[i*DATA_WIDTH +: DATA_WIDTH]),
                .fetch_address_in(fetch_address_in[i*ADDRESS_WIDTH +: ADDRESS_WIDTH]),
                .memory_valid(memory_valid[i +: 1]),
                .memory_ready(memory_ready[i +: 1]),
                .memory_data_in(memory_data_in[i*DATA_WIDTH +: DATA_WIDTH]),
                .memory_address_in(memory_address_in[i*ADDRESS_BITS +: ADDRESS_BITS]),
                .fetch_read(fetch_read[i +: 1]),
                .fetch_address_out(fetch_address_out[i*ADDRESS_BITS +: ADDRESS_BITS]),
                .memory_read(memory_read[i +: 1]),
                .memory_write(memory_write[i +: 1]),
                .memory_byte_en(memory_byte_en[i*DATA_WIDTH/8 +: DATA_WIDTH/8]),
                .memory_address_out(memory_address_out[i*ADDRESS_BITS +: ADDRESS_BITS]),
                .memory_data_out(memory_data_out[i*ADDRESS_BITS +: ADDRESS_BITS]),
                //scan signal
                .scan(scan)
            );

            memory_interface #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDRESS_BITS(ADDRESS_BITS)
            ) mem_interface(
                //fetch stage interface
                .fetch_read(fetch_read[i +: 1]),
                .fetch_address_out(fetch_address_out[i*ADDRESS_BITS +: ADDRESS_BITS]),
                .fetch_data_in(fetch_data_in[i*ADDRESS_BITS +: DATA_WIDTH]),
                .fetch_address_in(fetch_address_in[i*ADDRESS_BITS +: ADDRESS_WIDTH]),
                .fetch_valid(fetch_valid[i +: 1]),
                .fetch_ready(fetch_ready[i +: 1]),
                //memory stage interface
                .memory_read(memory_read[i +: 1]),
                .memory_write(memory_write[i +: 1]),
                .memory_byte_en(memory_byte_en[i*DATA_WIDTH/8 +: DATA_WIDTH/8]),
                .memory_address_out(memory_address_out[i*ADDRESS_BITS +: ADDRESS_BITS]),
                .memory_data_out(memory_data_out[i*ADDRESS_BITS +: ADDRESS_BITS]),
                .memory_data_in(memory_data_in[i*DATA_WIDTH +: DATA_WIDTH]),
                .memory_address_in(memory_address_in[i*ADDRESS_BITS +: ADDRESS_BITS]),
                .memory_valid(memory_valid[i +: 1]),
                .memory_ready(memory_ready[i +: 1]),
                //instruction memory/cache interface
                .i_mem_data_out(i_mem_data_out[i*DATA_WIDTH +: DATA_WIDTH]),
                .i_mem_address_out(i_mem_address_out[i*ADDRESS_BITS +: ADDRESS_BITS]),
                .i_mem_valid(i_mem_valid[i +: 1]),
                .i_mem_ready(i_mem_ready[i +: 1]),
                .i_mem_read(i_mem_read[i +: 1]),
                .i_mem_address_in(i_mem_address_in[i*ADDRESS_BITS +: ADDRESS_BITS]),
                //data memory/cache interface
                .d_mem_data_out(d_mem_data_out[i*DATA_WIDTH +: DATA_WIDTH]),
                .d_mem_address_out(d_mem_address_out[i*ADDRESS_BITS +: ADDRESS_BITS]),
                .d_mem_valid(d_mem_valid[i +: 1]),
                .d_mem_ready(d_mem_ready[i +: 1]),
                .d_mem_read(d_mem_read[i +: 1]),
                .d_mem_write(d_mem_write[i +: 1]),
                .d_mem_byte_en(d_mem_byte_en[i*DATA_WIDTH/8 +: DATA_WIDTH/8]),
                .d_mem_address_in(d_mem_address_in[i*ADDRESS_BITS +: ADDRESS_BITS]),
                .d_mem_data_in(d_mem_data_in[i*DATA_WIDTH +: DATA_WIDTH]),

                .scan(scan)
            );
        end

    endgenerate


   
/*Cache hierarchy*/
    cache_hierarchy #(
        .STATUS_BITS_L1(2),
        .STATUS_BITS_L2(3),
        .COHERENCE_BITS(2),
        .OFFSET_BITS_L1({32'd2, 32'd2, 32'd2, 32'd2}),
        .OFFSET_BITS_L2(2),
        .DATA_WIDTH(DATA_WIDTH),
        .NUMBER_OF_WAYS_L1({32'd2, 32'd2, 32'd2, 32'd2}),
        .NUMBER_OF_WAYS_L2(2),
        .REPLACEMENT_MODE_L1(1'b0),
        .REPLACEMENT_MODE_L2(1'b0),
        .ADDRESS_BITS(ADDRESS_BITS),
        .INDEX_BITS_L1({32'd5, 32'd5, 32'd5, 32'd5}),
        .INDEX_BITS_L2(5),
        .MSG_BITS(4),
        .NUM_L1_CACHES(4), //DEBLEENA
        .BUS_OFFSET_BITS(2),
        .MAX_OFFSET_BITS(2)
    ) cache_hier(
        .clock(clock),
        .reset(reset),
        .read({d_mem_read, i_mem_read}),
        .write({d_mem_write, {NUM_CORES{1'b0}}}),
        .w_byte_en({d_mem_byte_en, {NUM_CORES*DATA_WIDTH/8{1'b0}}}),
        .invalidate({NUM_CORES*2{1'b0}}),
        .flush({NUM_CORES*2{1'b0}}),
        .address({d_mem_address_in, i_mem_address_in}),
        .data_in({d_mem_data_in, {DATA_WIDTH*NUM_CORES{1'b0}}}),
        .report(scan),
        .data_out({d_mem_data_out, i_mem_data_out}),
        .out_address({d_mem_address_out, i_mem_address_out}),
        .ready({d_mem_ready, i_mem_ready}),
        .valid({d_mem_valid, i_mem_valid}),
        .mem2cachehier_msg(intf2cachehier_msg),
        .mem2cachehier_address(intf2cachehier_address),
        .mem2cachehier_data(intf2cachehier_data),
        .cachehier2mem_msg(cachehier2intf_msg),
        .cachehier2mem_address(cachehier2intf_address),
        .cachehier2mem_data(cachehier2intf_data)
    );



    /*Main memory interface*/
    main_memory_interface #(
        .OFFSET_BITS(L2_OFFSET),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_BITS),
        .MSG_BITS(MSG_BITS)
    ) mem_intf(
        .clock(clock),
        .reset(reset),
        .cache2interface_msg(cachehier2intf_msg),
        .cache2interface_address(cachehier2intf_address),
        .cache2interface_data(cachehier2intf_data),
        .interface2cache_msg(intf2cachehier_msg),
        .interface2cache_address(intf2cachehier_address),
        .interface2cache_data(intf2cachehier_data),
        .network2interface_msg(4'd0),
        .network2interface_address(0),
        .network2interface_data(0),
        .interface2network_msg(),
        .interface2network_address(),
        .interface2network_data(),
        .mem2interface_msg(mem2intf_msg),
        .mem2interface_address(mem2intf_address),
        .mem2interface_data(mem2intf_data),
        .interface2mem_msg(intf2mem_msg),
        .interface2mem_address(intf2mem_address),
        .interface2mem_data(intf2mem_data)
    );


    /*Main memory*/
    main_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_BITS),
        .MSG_BITS(MSG_BITS),
        .INDEX_BITS(10),
        .NUM_PORTS(1),
        .INIT_FILE("")
    ) memory(
        .clock(clock),
        .reset(reset),
        .msg_in(intf2mem_msg),
        .address(intf2mem_address),
        .data_in(intf2mem_data),
        .msg_out(mem2intf_msg),
        .address_out(mem2intf_address),
        .data_out(mem2intf_data)
    );
endmodule
