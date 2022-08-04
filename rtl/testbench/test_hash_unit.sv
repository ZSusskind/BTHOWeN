`define MEMORY_CONTENTS '{0,1,0,1,1,0,0,0,0,0,0,1,1,0,1,1,1,0,0,0,1,1,1,1,1,1,1,0,1,1,1,0,0,1,0,1,1,0,0,0,1,1,1,1,1,1,1,0,1,0,0,1,1,1,0,0,1,0,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,0,1,1,0,0,1,1,1,1,0,1,0,1,1,0,1,0,0,0,1,1,1,0,1,0,1,1,0,0,0,1,1,0,0,1,0,0,1,0,0,0,1,1,1,0,1,0,1,1,1,1,1,0,1,0,1,1,0,1,1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,0,0,0,1,1,0,1,1,0,0,1,0,1,0,0,0,1,1,0,0,1,1,0,0,1,0,1,1,0,1,0,1,0,1,0,0,0,0,0,0,0,1,1,0,1,0,0,0,1,1,0,1,0,1,1,0,0,0,1,0,1,1,0,1,0,0,0,0,1,0,0,0,0,1,1,0,0,0,1,1,0,1,1,1,0,1,1,0,1,1,1,1,0,1,0,0,1,1,0,0,0,1,1,0,0,1,0,1}

module Top;
    reg  clk;
    reg  rst;
    reg  inp_vld;
    wire outp_vld;

    reg  [27:0] input_value;
    reg  [7:0] hash_values [27:0];
    wire [7:0] hash_result;

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
            hash_values = '{108,237,82,251,29,70,231,150,137,60,20,35,175,140,42,52,32,54,135,134,209,77,198,35,6,184,201,51};

            rst = 1'b1;
            #16;

            rst = 1'b0;
            inp_vld = 1'b0;
            input_value= 42;
            #30;

            inp_vld = 1'b1;
            input_value = 1234;
            #10;

            inp_vld = 1'b0;
            #20;


            inp_vld = 1'b1;
            for (i = 0; i < 32; i = i + 1) begin
                input_value = $urandom;
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
        $vcdplusfile("test_hash_unit.dump.vpd");
        $vcdpluson(0, Top);
        $vcdpluson(1, Top.dut);
    end // initial begin

    h3_hash dut (.clk(clk), .rst(rst), .inp_vld(inp_vld), .outp_vld(outp_vld), .input_value(input_value), .hash_values(hash_values), .hash_result(hash_result));

endmodule
