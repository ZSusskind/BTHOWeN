`define MEMORY_CONTENTS '{0,1,0,1,1,0,0,0,0,0,0,1,1,0,1,1,1,0,0,0,1,1,1,1,1,1,1,0,1,1,1,0,0,1,0,1,1,0,0,0,1,1,1,1,1,1,1,0,1,0,0,1,1,1,0,0,1,0,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,0,1,1,0,0,1,1,1,1,0,1,0,1,1,0,1,0,0,0,1,1,1,0,1,0,1,1,0,0,0,1,1,0,0,1,0,0,1,0,0,0,1,1,1,0,1,0,1,1,1,1,1,0,1,0,1,1,0,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,0,0,0,1,1,0,1,1,0,0,1,0,1,0,0,0,1,1,0,0,1,1,0,0,1,0,1,1,0,1,0,1,0,1,0,0,0,0,0,0,0,1,1,0,1,0,0,0,1,1,0,1,0,1,1,0,0,0,1,0,1,1,0,1,0,0,0,0,1,0,0,0,0,1,1,0,0,0,1,1,0,1,1,1,0,1,1,0,1,1,1,1,0,1,0,0,1,1,0,0,0,1,1,0,0,1,0,1}

module Top;
    reg  [0:0] clk;
    reg  [0:0] rst;
    reg  [0:0] inp_vld;
    wire [0:0] outp_vld;

    reg  [7:0] hashed_inp;
    wire [0:0] result;

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
            hashed_inp = 42;
            #30;

            inp_vld = 1'b1;
            hashed_inp = 230;
            #10;

            inp_vld = 1'b0;
            #20;

            inp_vld = 1'b1;
            hashed_inp = 52;
            #10;

            hashed_inp = 133;
            #10;


            for (i = 0; i < 32; i = i + 1) begin
                hashed_inp = $urandom;
                #10;
                
                hashed_inp = $urandom;
                #10;
                
                hashed_inp = $urandom;
                #10;
            end
            #20;

            $finish;
        end
        join
    end // initial begin

    initial begin // timeout
        #(2000);
        $fatal("Simulation timed out");
    end

    initial begin
        $vcdplusfile("test_filter.dump.vpd");
        $vcdpluson(0, Top);
    end // initial begin

    bloom_filter #(.DATA(`MEMORY_CONTENTS)) dut (.clk(clk), .rst(rst), .inp_vld(inp_vld), .outp_vld(outp_vld), .hashed_inp(hashed_inp), .result(result));

endmodule
