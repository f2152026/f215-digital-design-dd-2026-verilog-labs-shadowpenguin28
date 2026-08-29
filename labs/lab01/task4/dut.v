module dut(input [63:0] a, b, input cin, output [63:0] sum, output cout); cla64_blocked U_IMPL (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout)); endmodule
