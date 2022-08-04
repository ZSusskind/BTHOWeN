module Top;
    reg  clk;
    reg  rst;
    reg  inp_vld;
    wire outp_vld;
    wire stall;

    reg  [511:0] inp;
    wire [3:0] outp;
    
    integer i;
    reg [0:0] last_stall;
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

            inp_vld = 1'b0;
            #30;

            inp_vld = 1'b1;
            i = 0;
            while (i < 16) begin
                last_stall = stall;
                if (outp_vld) i = i + 1;
                #10;
                if (!last_stall) std::randomize(inp);
            end
            
            $finish;
        end
        join
    end // initial begin
    
    initial begin // timeout
        #(20000);
        $fatal("Simulation timed out");
    end
    
    initial begin
        $vcdplusfile("test_interface_basic.dump.vpd");
        //$vcdpluson(0, Top);
        $vcdpluson(3, Top);
    end // initial begin

    device_interface dut(.clk(clk), .rst(rst), .inp_vld(inp_vld), .outp_vld(outp_vld), .stall(stall), .inp(inp), .outp(outp));
endmodule

