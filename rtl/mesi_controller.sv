`timescale 1ns / 1ps

module mesi_controller (
      input  logic        clk,
      input  logic        rst_n,
      // Core Request Interface
      input  logic        core_read_req,
      input  logic        core_write_req,
  input  logic [1:0]  curr_state,      // 2'b00: I, 2'b01: S, 2'b10: E, 2'b11: M
      // Snooping Bus Interface
      input  logic        snoop_read_req,
      input  logic        snoop_write_req,
      input  logic        snoop_hit_other, // High if another core has the line
      // Outputs
  output logic [1:0]  next_state,
      output logic        bus_read_req,
      output logic        bus_inv_req,     // Broadcast Invalidation
      output logic        snoop_flush_req  // Flush dirty line to bus
);

      localparam STATE_I = 2'b00; // Invalid
      localparam STATE_S = 2'b01; // Shared
      localparam STATE_E = 2'b10; // Exclusive
      localparam STATE_M = 2'b11; // Modified

      always_comb begin
                next_state      = curr_state;
                bus_read_req    = 1'b0;
                bus_inv_req     = 1'b0;
                snoop_flush_req = 1'b0;

                // Core-Initiated Transitions
        case (curr_state)
                      STATE_I: begin
                        if (core_read_req) begin
                                              bus_read_req = 1'b1;
                                              next_state   = snoop_hit_other ? STATE_S : STATE_E;
                        end else if (core_write_req) begin
                                              bus_read_req = 1'b1;
                                              bus_inv_req  = 1'b1;
                                              next_state   = STATE_M;
                        end
                      end

                      STATE_S: begin
                        if (core_write_req) begin
                                              bus_inv_req = 1'b1; // Invalidate other sharers
                                              next_state  = STATE_M;
                        end
                      end

                      STATE_E: begin
                        if (core_write_req) begin
                          next_state = STATE_M; // Silent transition (no bus traffic)
                        end
                      end

                      STATE_M: begin
                                        // Write hits remain in Modified
                      end
        endcase

                // Bus Snoop-Initiated Transitions
        if (snoop_read_req) begin
          if (curr_state == STATE_M) begin
                            snoop_flush_req = 1'b1; // Supply data to bus and downgrade
                            next_state      = STATE_S;
          end else if (curr_state == STATE_E) begin
                            next_state      = STATE_S;
          end
        end

        if (snoop_write_req) begin
          if (curr_state == STATE_M) begin
                            snoop_flush_req = 1'b1;
          end
                      next_state = STATE_I; // Invalidation received
        end
      end

endmodule
