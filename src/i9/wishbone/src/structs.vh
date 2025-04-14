`ifndef STRUTCS_VH_  // guard
`define STRUTCS_VH_

package structs_pkg;

typedef struct packed {
  reg [31:0] cnt;
  reg [31:0] duty;
  reg [31:0] phase;
} pwm_regs_t;

endpackage

`endif
