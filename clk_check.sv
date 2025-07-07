module clk_check(clk_in, clk_out, clk_gating_bit, power_domain_ctrl, clk_div_cfg, clk_test_ctrl);
timeunit 1ps;
timeprecision 1ps;
parameter number = 0;
parameter freq = 480; //MHz default test clock frequence
parameter fix_div_num = 0;
parameter duty_ratio_en = 0;
parameter duty_clk_float = 10;
parameter upward_float = 1;
parameter downward_float = 1;
 
input logic clk_in;
input logic clk_out;
input logic clk_gating_bit;
input logic power_domain_ctrl;
input logic clk_test_ctrl;
input [13:0] clk_div_cfg;
integer div_num_add;
bit clk_frq_test_en;
bit [1:0] clk_out_cnt;
bit clk_out_b;
bit clk_gate;
bit clk_gate_bit;
bit clk_in_d;
bit error_not_overflow = 1;
real r0, r1, r2;
real a_min, a_max;
real a1, a2;
 
integer freq_count;
integer freq_count_l;
integer freq_count_h;
 
int clk_open_err_num;
int clk_close_err_num;
 
reg [31:0] frq_error_cnt = 0;
reg [31:0] clk_cnt = 0;
 
bit clk_gen;
bit clk_gen_temp;
bit check_time;
 
event freq_overflow;
event freq_underflow;
event freq_zero;
event clk_close;
event clk_stable;
event clk_open;
 
assign clk_frq_test_en = error_not_overflow & clk_test_ctrl & clk_gating_bit & power_domain_ctrl;
assign clk_gate_bit = clk_gating_bit & power_domain_ctrl;
assign clk_gate = clk_test_ctrl & clk_gating_bit & power_domain_ctrl;
 
assign #2ps clk_in_d = clk_in;
assign #1ps clk_gen = (div_num_add < 2) ? clk_in : clk_gen_temp;
 
always @(posedge clk_in) begin
    div_num_add = fix_div_num + clk_div_cfg;
    if(div_add_num < 2) begin
        clk_cnt = 0;
    end else if(clk_cnt == (div_num_add/2-1) && (div_num_add > 1)) begin
        clk_gen_temp = ~clk_gen_temp;
        clk_cnt = 0;
    end else begin
        clk_cnt = clk_cnt + 1;
    end
end
 
always @(posedge clk_out) begin
    if(clk_frq_test_en) begin
        //first cycle
        @(posedge clk_out or negedge clk_out);
        r0 = $realtime();
        @(posedge clk_out or negedge clk_out);
        r1 = $realtime();
        @(posedge clk_out or negedge clk_out);
        r2 = $realtime();
 
        a1 = (r1>r0) ? (r1-r0) : (r0-r1);
        a2 = (r2>r1) ? (r2-r1) : (r1-r2);
        
        a_min = a1*(100-duty_clk_float)/100;
        a_max = a1*(100+duty_clk_float)/100;
 
        //test frequence MHz
        freq_count = 1000000000.00/(a1+a2);
        freq_count_h = freq*1000*(100+upward_float)/100;
        freq_count_l = freq*1000*(100-downward_float)/100;
        
        if(freq_cpunt > freq_count_h) begin
            ->freq_overflow;
            freq_error_cnt = freq_error_cnt+1;
            `uvm_error("freq_overflow", $sformatf("time at %0t clk freq overflow! num = %0d, freq_count = %0d, freq_count_h = %0d", $time, number, freq_count, freq_count_h));
        end
        if(freq_cpunt < freq_count_l) begin
            ->freq_underflow;
            freq_error_cnt = freq_error_cnt+1;
            `uvm_error("freq_underflow", $sformatf("time at %0t clk freq underflow! num = %0d, freq_count = %0d, freq_count_h = %0d", $time, number, freq_count, freq_count_l));
        end
        if(freq_cpunt == 0) begin
            ->freq_zero;
            freq_error_cnt = freq_error_cnt+1;
            `uvm_error("freq_zero", $sformatf("time at %0t clk freq zero! num = %0d, freq_count = %0d, freq_count_h = %0d, freq_count_l = %0d", $time, number, freq_count, freq_count_h, freq_count_l));
        end
    end
end
 
initial begin
    check_time = 0;
    #10000ns;
    check_time = 1;
end
 
property clock_close;
    @(posedge clk_gen) disable iff(!check_time)
    (($past(clk_gate_bit, 1) == 1'b1) && (clk_gate_bit == 0)) |-> ##[2:10] ($stable(clk_out) & !clk_out);
endproperty
property clock_stable;
    @(posedge clk_gen) (($past(clk_gate_bit, 1) == 1'b0) && (clk_gate_bit == 0)) |-> ##(10) ($stable(clk_out) & !clk_out);
endproperty
 
property clock_open;
    @(posedge clk_in_d) disable iff(!check_time)
    (($past(clk_gate_bit, 1) == 1'b1) && (clk_gate_bit == 1)) |-> ##[1:20000] ($rose(clk_out));
endproperty
assert property(clock_close) -> clk_close;
else begin
    clk_close_err_num++;
    `uvm_error("ERROR", $sformatf("time at %0t clock is not close, num = %0d", $time, number))
end
assert property(clock_open) -> clk_open;
else begin
    clk_open_err_num++;
    `uvm_error("ERROR", $sformatf("time at %0t clock is not open, num = %0d", $time, number))
end
endmodule