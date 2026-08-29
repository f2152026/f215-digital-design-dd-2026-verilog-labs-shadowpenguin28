// cla4_dataflow.v
// The same 4-bit CLA as cla4.v, rewritten using dataflow modeling
// (continuous `assign` statements) instead of gate primitives. Compare
// the line count and readability of this file to cla4.v.
//
// TODO: add a delay to every assign statement (e.g. assign ...) --
// same default-delay expectation as everywhere else from Task 2 onward.
//   assign p = a ^ b;
//   assign g = a & b;
//   assign c1   = g[0] | (p[0] & cin);
//   assign c2   = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
//   assign c3   = ... (same pattern, one more term)
//   assign cout = ... (same pattern, one more term)
//   assign sum  = p ^ {c3, c2, c1, cin};

module cla4_dataflow(
  input  [3:0] a,
  input  [3:0] b,
  input        cin,
  output [3:0] sum,
  output       cout
);

  wire [3:0] p, g;
  wire c1, c2, c3;

  // ---- P and G signals (one assign covers all 4 bits at once) ----
  assign p = a ^ b;
  assign g = a & b;

  // ---- Direct carry equations ----
  assign c1   = g[0] | (p[0] & cin);
  assign c2   = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
  assign c3   = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
  assign cout = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);

  // ---- Sum bits ----
  assign sum = p ^ {c3, c2, c1, cin};


endmodule
