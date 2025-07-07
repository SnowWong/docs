`define check_boot_start_crg(ref_freq,clk_path)\
    forever begin\
        @(posedge clk_path)\
        if(cnt == 0) t1 = $realtime;\
        if(cnt == 1) begin\
            t2 = $realtime;\
            freq1 = t2-t1;\
            $display("t1 = %of, t2 = %0f, freq1 = %0f at time %t", t1, t2, $realtime);\
        end\
        if(cnt == 2) begin\
            t3 = $realtime;\
            freq2 = t3-t2;\
            $display("t2 = %of, t3 = %0f, freq2 = %0f at time %t", t1, t2, $realtime);\
        end\
        if((freq1 == freq2) && (freq1 != 0)) begin\
            frequency = freq1;\
            $display("freqency = %of, ref_freq = %0f at time %t", freqency, ref_freq, $realtime);\
            if((frequency <= ref_freq*0.99) || (frequency >= ref_freq*1.01)) begin\
                `uvm_error("soc_clk_check", "clk_path check Failed")
            else begin
                `uvm_info("soc_clk_check", "clk_path check Pass", UVM_LOW)\
                break;\
            end\
        end\
        if(cnt < 2) cnt = cnt + 1;\
        else if(cnt == 2) cnt = 0;\
    end