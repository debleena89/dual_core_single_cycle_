/** @module : cache_hierarchy_v3.0
 *  @author : Adaptive & Secure Computing Systems (ASCS) Laboratory

 *  Copyright (c) 2018 BRISC-V (ASCS/ECE/BU)
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

module cache_hierarchy #(
parameter STATUS_BITS_L1      = 2,
          STATUS_BITS_L2      = 3,
          COHERENCE_BITS      = 2,
          OFFSET_BITS_L1      = {32'd2, 32'd2, 32'd2, 32'd2},
          OFFSET_BITS_L2      = 2,
          DATA_WIDTH          = 32,
          NUMBER_OF_WAYS_L1   = {32'd2, 32'd2, 32'd2, 32'd2},
          NUMBER_OF_WAYS_L2   = 4,
          REPLACEMENT_MODE_L1 = 1'b0,
          REPLACEMENT_MODE_L2 = 1'b0,
          ADDRESS_BITS        = 32,
          INDEX_BITS_L1       = {32'd5, 32'd5, 32'd5, 32'd5},
          INDEX_BITS_L2       = 6,
          MSG_BITS            = 4,
          NUM_L1_CACHES       = 4, //4, debleena
          BUS_OFFSET_BITS     = 2,
          MAX_OFFSET_BITS     = 2
)(
  clock, reset,
  read, write, invalidate, flush,
  w_byte_en,
  address,
  data_in,
  report,
  data_out,
  out_address,
  ready,
  valid,
  mem2cachehier_msg,
  mem2cachehier_address,
  mem2cachehier_data,
  cachehier2mem_msg,
  cachehier2mem_address,
  cachehier2mem_data
);

//Define the log2 function
function integer log2;
input integer value;
begin
  value = value-1;
  for(log2=0; value>0; log2=log2+1)
    value = value>>1;
  end
endfunction

// Define INCLUDE_FILE  to point to /includes/params.h. The path should be
// relative to your simulation/sysnthesis directory. You can add the macro
// when compiling this file in modelsim by adding the following argument to the
// vlog command that compiles this module:
// +define+INCLUDE_FILE="../../../includes/params.h"
`include "./params.h" //added by Debleena

localparam BUS_WORDS     = 1 << BUS_OFFSET_BITS;
localparam BUS_WIDTH     = BUS_WORDS*DATA_WIDTH;
localparam L2_WORDS      = 1 << OFFSET_BITS_L2;
localparam L2_WIDTH      = L2_WORDS*DATA_WIDTH;
localparam BUS_PORTS     = NUM_L1_CACHES + 1;
localparam MEM_PORT      = BUS_PORTS - 1;
localparam BUS_SIG_WIDTH = log2(BUS_PORTS);
localparam WIDTH_BITS    = log2(MAX_OFFSET_BITS) + 1;


//ports
input  clock, reset;
input  report;
input  [NUM_L1_CACHES-1:0] read, write, invalidate, flush;
input  [NUM_L1_CACHES*DATA_WIDTH/8-1:0] w_byte_en;
input  [NUM_L1_CACHES*ADDRESS_BITS-1:0] address;
input  [NUM_L1_CACHES*DATA_WIDTH-1  :0] data_in;
output [NUM_L1_CACHES*ADDRESS_BITS-1:0] out_address;
output [NUM_L1_CACHES*DATA_WIDTH-1  :0] data_out;
output [NUM_L1_CACHES-1:0] valid, ready;

input  [MSG_BITS-1    :0]     mem2cachehier_msg;
input  [ADDRESS_BITS-1:0] mem2cachehier_address;
input  [L2_WIDTH-1    :0]    mem2cachehier_data;
output [MSG_BITS-1    :0]     cachehier2mem_msg;
output [ADDRESS_BITS-1:0] cachehier2mem_address;
output [L2_WIDTH-1    :0]    cachehier2mem_data;


//internal signals
genvar i;
wire [DATA_WIDTH-1  :0] w_data_in     [NUM_L1_CACHES-1:0];
wire [DATA_WIDTH/8-1:0] w_w_byte_en   [NUM_L1_CACHES-1:0];
wire [ADDRESS_BITS-1:0] w_address     [NUM_L1_CACHES-1:0];
wire [DATA_WIDTH-1  :0] w_data_out    [NUM_L1_CACHES-1:0];
wire [ADDRESS_BITS-1:0] w_out_address [NUM_L1_CACHES-1:0];

wire [MSG_BITS-1    :0] w_l1tobus_msg     [NUM_L1_CACHES-1:0];
wire [ADDRESS_BITS-1:0] w_l1tobus_address [NUM_L1_CACHES-1:0];
wire [BUS_WIDTH-1   :0] w_l1tobus_data    [NUM_L1_CACHES-1:0];
wire [WIDTH_BITS-1  :0] w_l1tobus_offset  [NUM_L1_CACHES-1:0];

wire [NUM_L1_CACHES*MSG_BITS-1    :0] l1tobus_msg;
wire [NUM_L1_CACHES*ADDRESS_BITS-1:0] l1tobus_address;
wire [NUM_L1_CACHES*BUS_WIDTH-1   :0] l1tobus_data;
wire [NUM_L1_CACHES*WIDTH_BITS-1  :0] l1tobus_offset;

wire [MSG_BITS-1    :0] l2tobus_msg;
wire [ADDRESS_BITS-1:0] l2tobus_address;
wire [BUS_WIDTH-1   :0] l2tobus_data;
wire [WIDTH_BITS-1  :0] l2tobus_offset;

wire [MSG_BITS-1    :0] bus_msg;
wire [ADDRESS_BITS-1:0] bus_address;
wire [BUS_WIDTH-1   :0] bus_data;
wire [WIDTH_BITS-1  :0] req_offset;

wire [NUM_L1_CACHES-1:0] bus_master;
wire [BUS_SIG_WIDTH-1:0] bus_ctrl;
wire req_ready;
wire bus_en;


//Separate bundled up signals
generate
  for(i=0; i<NUM_L1_CACHES; i=i+1)begin: INPUTS
    assign w_w_byte_en[i] = w_byte_en[i*DATA_WIDTH/8 +: DATA_WIDTH/8];
    assign w_address[i] = address[i*ADDRESS_BITS +: ADDRESS_BITS];
    assign w_data_in[i] = data_in[i*DATA_WIDTH   +: DATA_WIDTH  ];
  end
endgenerate

//bundle up signals
generate
  for(i=0; i<NUM_L1_CACHES; i=i+1)begin: OUTPUTS
    assign data_out[i*DATA_WIDTH +: DATA_WIDTH]        =    w_data_out[i];
    assign out_address[i*ADDRESS_BITS +: ADDRESS_BITS] = w_out_address[i];
  end
  for(i=0; i<NUM_L1_CACHES; i=i+1)begin: BUS_SIGNALS
    assign l1tobus_msg[i*MSG_BITS+:MSG_BITS]             = w_l1tobus_msg[i];
    assign l1tobus_address[i*ADDRESS_BITS+:ADDRESS_BITS] = w_l1tobus_address[i];
    assign l1tobus_data[i*BUS_WIDTH+:BUS_WIDTH]          = w_l1tobus_data[i];
    assign l1tobus_offset[i*WIDTH_BITS+:WIDTH_BITS]      = w_l1tobus_offset[i];
  end
endgenerate


//Instantiate L1 caches
generate
  for(i=0; i<NUM_L1_CACHES; i=i+1)begin: L1INST
    L1cache_wrapper #(
      .STATUS_BITS(STATUS_BITS_L1),
      .COHERENCE_BITS(COHERENCE_BITS),
      .CACHE_OFFSET_BITS(OFFSET_BITS_L1[i*32 +: 32]),
      .DATA_WIDTH(DATA_WIDTH),
      .NUMBER_OF_WAYS(NUMBER_OF_WAYS_L1[i*32 +: 32]),
      .ADDRESS_BITS(ADDRESS_BITS),
      .INDEX_BITS(INDEX_BITS_L1[i*32 +: 32]),
      .MSG_BITS(MSG_BITS),
      .BUS_OFFSET_BITS(BUS_OFFSET_BITS),
      .MAX_OFFSET_BITS(MAX_OFFSET_BITS),
      .REPLACEMENT_MODE(REPLACEMENT_MODE_L1),
      .CORE(i/2),
      .CACHE_NO(i)
    ) l1cache (
      .clock(clock),
      .reset(reset),
      //processor interface
      .read(read[i]),
      .write(write[i]),
      .w_byte_en(w_w_byte_en[i]),
      .invalidate(invalidate[i]),
      .flush(flush[i]),
      .address(w_address[i]),
      .data_in(w_data_in[i]),
      .report(report),
      .data_out(w_data_out[i]),
      .out_address(w_out_address[i]),
      .ready(ready[i]),
      .valid(valid[i]),
      //bus interface
      .bus_msg_in(bus_msg),
      .bus_address_in(bus_address),
      .bus_data_in(bus_data),
      .bus_msg_out(w_l1tobus_msg[i]),
      .bus_address_out(w_l1tobus_address[i]),
      .bus_data_out(w_l1tobus_data[i]),
      .active_offset(w_l1tobus_offset[i]),
      .bus_master(bus_master[i]),
      .req_ready(req_ready),
      .curr_offset(req_offset)
    );
  end
endgenerate


//Instantiate shared buses
mux_bus #(
  .WIDTH(MSG_BITS),
  .NUM_PORTS(BUS_PORTS)
) msg_bus (
  .data_in({l2tobus_msg, l1tobus_msg}),
  .enable_port(bus_ctrl),
  .valid_enable(bus_en),
  .data_out(bus_msg)
);

mux_bus #(
  .WIDTH(ADDRESS_BITS),
  .NUM_PORTS(BUS_PORTS)
) address_bus (
  .data_in({l2tobus_address, l1tobus_address}),
  .enable_port(bus_ctrl),
  .valid_enable(bus_en),
  .data_out(bus_address)
);

mux_bus #(
  .WIDTH(BUS_WIDTH),
  .NUM_PORTS(BUS_PORTS)
) data_bus (
  .data_in({l2tobus_data, l1tobus_data}),
  .enable_port(bus_ctrl),
  .valid_enable(bus_en),
  .data_out(bus_data)
);

mux_bus #(
  .WIDTH(log2(MAX_OFFSET_BITS) + 1),
  .NUM_PORTS(BUS_PORTS)
) offset_bus (
  .data_in({l2tobus_offset, l1tobus_offset}),
  .enable_port(bus_ctrl),
  .valid_enable(bus_en),
  .data_out(req_offset)
);


//Instantiate bus controller
coherence_controller #(
  .MSG_BITS(MSG_BITS),
  .NUM_CACHES(NUM_L1_CACHES)
) bus_controller (
  .clock(clock),
  .reset(reset),
  .cache2mem_msg(l1tobus_msg),
  .mem2controller_msg(l2tobus_msg),
  .bus_msg(bus_msg),
  .bus_control(bus_ctrl),
  .bus_en(bus_en),
  .curr_master(bus_master),
  .req_ready(req_ready)
);


//Instantiate the L2 cache
Lxcache_wrapper #(
  .STATUS_BITS(STATUS_BITS_L2),
  .COHERENCE_BITS(COHERENCE_BITS),
  .CACHE_OFFSET_BITS(OFFSET_BITS_L2),
  .DATA_WIDTH(DATA_WIDTH),
  .NUMBER_OF_WAYS(NUMBER_OF_WAYS_L2),
  .REPLACEMENT_MODE(REPLACEMENT_MODE_L2),
  .ADDRESS_BITS(ADDRESS_BITS),
  .INDEX_BITS(INDEX_BITS_L2),
  .MSG_BITS(MSG_BITS),
  .BUS_OFFSET_BITS(BUS_OFFSET_BITS),
  .MAX_OFFSET_BITS(MAX_OFFSET_BITS)
) l2cache (
  .clock(clock),
  .reset(reset),
  .address(bus_address),
  .data_in(bus_data),
  .msg_in(bus_msg),
  .req_ready(req_ready),
  .req_offset(req_offset),
  .report(report),
  .data_out(l2tobus_data),
  .out_address(l2tobus_address),
  .msg_out(l2tobus_msg),
  .active_offset(l2tobus_offset),

  .mem2cache_msg(mem2cachehier_msg),
  .mem2cache_address(mem2cachehier_address),
  .mem2cache_data(mem2cachehier_data),
  .cache2mem_msg(cachehier2mem_msg),
  .cache2mem_address(cachehier2mem_address),
  .cache2mem_data(cachehier2mem_data)
);


endmodule
