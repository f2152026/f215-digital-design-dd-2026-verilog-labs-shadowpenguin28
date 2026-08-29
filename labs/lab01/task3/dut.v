module dut(input [3:0] a, b, input cin, output [3:0] sum, output cout); cla4_dataflow U_IMPL (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout)); endmodule
