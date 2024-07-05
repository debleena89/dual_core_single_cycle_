//bus messages
localparam NO_REQ     = 4'd0,
           R_REQ      = 4'd1,
           WB_REQ     = 4'd2,
           FLUSH      = 4'd3,
           FLUSH_S    = 4'd4,
           WS_BCAST   = 4'd5,
           RFO_BCAST  = 4'd6,
           C_WB       = 4'd7,
           C_FLUSH    = 4'd8,
           EN_ACCESS  = 4'd9,
           MEM_RESP   = 4'd10,
           MEM_RESP_S = 4'd11,
           MEM_C_RESP = 4'd12,
           REQ_FLUSH  = 4'd13,
           HOLD_BUS   = 4'd14;



// coherence states
localparam INVALID   = 2'b00,
           EXCLUSIVE = 2'b01,
           SHARED    = 2'b11,
           MODIFIED  = 2'b10;
