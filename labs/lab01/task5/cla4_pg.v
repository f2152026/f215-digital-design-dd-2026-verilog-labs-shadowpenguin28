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
  xor #(2) (p1, a[1], b[1]);
  xor #(2) (p2, a[2], b[2]);
  xor #(2) (p3, a[3], b[3]);

  and #(2) (g0, a[0], b[0]);
  and #(2) (g1, a[1], b[1]);
  and #(2) (g2, a[2], b[2]);
  and #(2) (g3, a[3], b[3]);

  wire t1_c1;
  and #(2) (t1_c1, p0, cin);
  or  #(2) (c1, g0, t1_c1);

  wire t1_c2, t2_c2;
  and #(2) (t1_c2, p1, g0);
  and #(2) (t2_c2, p1, p0, cin);
  or  #(2) (c2, g1, t1_c2, t2_c2);

  wire t1_c3, t2_c3, t3_c3;
  and #(2) (t1_c3, p2, g1);
  and #(2) (t2_c3, p2, p1, g0);
  and #(2) (t3_c3, p2, p1, p0, cin);
  or  #(2) (c3, g2, t1_c3, t2_c3, t3_c3);

  wire c4;
  wire t1_c4, t2_c4, t3_c4, t4_c4;
  and #(2) (t1_c4, p3, g2);
  and #(2) (t2_c4, p3, p2, g1);
  and #(2) (t3_c4, p3, p2, p1, g0);
  and #(2) (t4_c4, p3, p2, p1, p0, cin);
  or  #(2) (c4, g3, t1_c4, t2_c4, t3_c4, t4_c4);

  assign cout = c4;

  xor #(2) (sum[0], p0, cin);
  xor #(2) (sum[1], p1, c1);
  xor #(2) (sum[2], p2, c2);
  xor #(2) (sum[3], p3, c3);

  and #(2) (Pblk, p3, p2, p1, p0);

  wire tg1, tg2, tg3;
  and #(2) (tg1, p3, g2);
  and #(2) (tg2, p3, p2, g1);
  and #(2) (tg3, p3, p2, p1, g0);
  or  #(2) (Gblk, g3, tg1, tg2, tg3);

endmodule
