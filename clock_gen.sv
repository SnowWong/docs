`timescale 1ns/1ps
module clk_gen(input [31:0] ref_freq, jit, output reg clk_out);
    timeunit 1ps;
    timeprecision 1fs;
    real cycle_real;
    real ref_freq_real;
    loongint cycle,cycle_real_p,cycle_real_n;
    bit randbit;
    
    initial begin
        clk=0;
        #1ns;
        ref_freq_real = $itor(ref_freq); //integer转换为real类型
        cycle_real = (0.5*(10**9))/ref_freq_real; //half of cycle
        randbit=$urandom_range(0,1);
        cycle_real_p = cycle_real+jit;
        cycle_real_n = cycle_real-jit;
        forever clk=#($urandom_range(cycle_real_p-cycle_real_n)) ~clk;
    end
endmodule