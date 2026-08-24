`timescale 1ns / 1ps

module deadlock_monitor #(
      parameter TIMEOUT_CYCLES = 1000,
      parameter NUM_BANKS      = 4
)(
      input  logic        clk,
      input  logic        rst_n,
  input  logic [31:0] pending_req_count,
  input  logic [NUM_BANKS-1:0] bank_busy,
  input  logic [NUM_BANKS-1:0] bank_grant
);

      int unsigned stall_counter;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
                  stall_counter <= 0;
    end else begin
      if (pending_req_count > 0 && (bank_busy != 0) && (bank_grant == 0)) begin
                        stall_counter <= stall_counter + 1;
        if (stall_counter >= TIMEOUT_CYCLES) begin
          $error("[DEADLOCK DETECTED] Cycle: %0d | Outstanding Requests: %0d | Blocked Banks: %b",
                 $time, pending_req_count, bank_busy);
                              $finish;
        end
      end else begin
                        stall_counter <= 0;
      end
    end
  end

endmodule
