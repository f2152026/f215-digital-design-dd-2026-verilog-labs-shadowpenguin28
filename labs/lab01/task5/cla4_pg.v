// cla4_pg.v
// 4-bit CLA block that also exposes block-level generate (Gblk) and
// propagate (Pblk) signals for use in a second-level lookahead unit.
//
// Gblk = "this block generates a carry regardless of carry-in"
//   Gblk = g3 + p3.g2 + p3.p2.g1 + p3.p2.p1.g0
//
// Pblk = "carry-in propagates all the way through this block"
//   Pblk = p3.p2.p1.p0

module cla4_pg(
  input  [3:0] a,
  input  [3:0] b,
  input        cin,
  output [3:0] sum,
  output       cout,
  output       Gblk,
  output       Pblk
);

  wire p0, p1, p2, p3;
  wire g0, g1, g2, g3;
  wire c1, c2, c3;

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

  wire c4;
  wire t1_c4, t2_c4, t3_c4, t4_c4;
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

  and (Pblk, p3, p2, p1, p0);

  wire tg1, tg2, tg3;
  and (tg1, p3, g2);
  and (tg2, p3, p2, g1);
  and (tg3, p3, p2, p1, g0);
  or (Gblk, g3, tg1, tg2, tg3);

endmodule
