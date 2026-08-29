// cla4.v
// Gate-level 4-bit carry-lookahead adder, matching the lecture circuit.
// Every gate needs an explicit delay (constant is fine here, e.g. ) --
// this is the default from Task 2 onward, not a special step.
//
// TODO -- Step 1: generate/propagate signals (one xor + one and per bit)
//   p[i] = a[i] ^ b[i]
//   g[i] = a[i] & b[i]
//
// TODO -- Step 2: direct (non-recursive) carry equations. Verilog's and/or
// primitives accept more than 2 inputs directly, e.g.:
//   and (t2, p1, p0, g0);
// so you do not need to manually chain 2-input gates.
//   c1 = g0 + p0.cin
//   c2 = g1 + p1.g0 + p1.p0.cin
//   c3 = g2 + p2.g1 + p2.p1.g0 + p2.p1.p0.cin
//   c4 = g3 + p3.g2 + p3.p2.g1 + p3.p2.p1.g0 + p3.p2.p1.p0.cin
//
// TODO -- Step 3: sum bits
//   sum[i] = p[i] ^ c[i]     (c0 = cin)

module cla4(
  input  [3:0] a,
  input  [3:0] b,
  input        cin,
  output [3:0] sum,
  output       cout
);

  wire p0, p1, p2, p3;
  wire g0, g1, g2, g3;
  wire c1, c2, c3;

  // TODO: your gate-level P/G, carry, and sum logic goes here.
  // (cout should be connected to c4.) Remember the delay on every gate.

  xor #(2) (p0, a[0], b[0]);
  xor (p1, a[1], b[1]);
  xor (p2, a[2], b[2]);
  xor (p3, a[3], b[3]);

  and (g0, a[0], b[0]);
  and (g1, a[1], b[1]);
  and (g2, a[2], b[2]);
  and (g3, a[3], b[3]);

  wire t1_c1;
  and (t1_c1, p0, cin);
  or (c1, g0, t1_c1);

  wire t1_c2, t2_c2;
  and (t1_c2, p1, g0);
  and (t2_c2, p1, p0, cin);
  or (c2, g1, t1_c2, t2_c2);

  wire t1_c3, t2_c3, t3_c3;
  and (t1_c3, p2, g1);
  and (t2_c3, p2, p1, g0);
  and (t3_c3, p2, p1, p0, cin);
  or (c3, g2, t1_c3, t2_c3, t3_c3);

  wire c4, t1_c4, t2_c4, t3_c4, t4_c4;
  and (t1_c4, p3, g2);
  and (t2_c4, p3, p2, g1);
  and (t3_c4, p3, p2, p1, g0);
  and (t4_c4, p3, p2, p1, p0, cin);
  or (c4, g3, t1_c4, t2_c4, t3_c4, t4_c4);

  assign cout = c4;

  xor (sum[0], p0, cin);
  xor (sum[1], p1, c1);
  xor (sum[2], p2, c2);
  xor (sum[3], p3, c3);

endmodule
