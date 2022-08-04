module Top;
    reg  clk;
    reg  rst;
    reg  inp_vld;
    wire outp_vld;
    wire stall;

    reg  [3135:0] inp;
    wire [3:0] outp;
    
    integer i;
    initial begin
        fork
        begin
            clk = 0;
            forever begin
                #5;
                clk = !clk;    
            end
        end
        begin
            rst = 1'b1;
            #16;

            rst = 1'b0;
            inp_vld = 1'b0;
            inp = 42;
            #30;
            
            inp_vld = 1'b1;
            inp = 12345678;
            #10;

            for (i = 0; i < 16; i = i + 1) begin
                while(stall) #10;
                std::randomize(inp);
                #10;
            end
            #200;
            $finish;
        end
        join
    end // initial begin
    
    initial begin // timeout
        #(10000);
        $fatal("Simulation timed out");
    end
    
    initial begin
        $vcdplusfile("test_wisard_top.dump.vpd");
        //$vcdpluson(0, Top);
        $vcdpluson(2, Top.dut);
    end // initial begin

    wisard dut(.clk(clk), .rst(rst), .inp_vld(inp_vld), .outp_vld(outp_vld), .stall(stall), .inp(inp), .outp(outp));
endmodule

