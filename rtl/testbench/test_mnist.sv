`include "sv_srcs/global_parameters.svh"

module Top;
    reg  clk;
    reg  rst;
    reg  inp_vld;
    wire outp_vld;
    wire stall;

    wire  [`INPUT_BUS_WIDTH-1:0] inp;
    wire [3:0] outp;

    reg [`INPUT_BITS-1:0]   input_samples   [9999:0];
    reg [7:0]               input_labels    [9999:0];

    integer i, j;
    integer samples, correct;
    integer file;
    reg [0:0] last_stall;
    wire [`INPUT_BITS+`INPUT_BUS_WIDTH-1:0] padded_input;
    wire [7:0] label;
    assign padded_input[`INPUT_BITS+`INPUT_BUS_WIDTH-1:`INPUT_BITS] = 0;
    assign padded_input[`INPUT_BITS-1:0] = input_samples[i];
    assign label = input_labels[samples];
    assign inp = padded_input[`INPUT_BUS_WIDTH*j+:`INPUT_BUS_WIDTH];
    initial begin
        $display("Reading dataset...");
        //file = $fopen("../../software_model/mnist_model_28input_1024entry_2hash_2bpi_inputs.mem", "rb");
        file = $fopen("../../software_model/mnist_model_49input_8192entry_4hash_6bpi_inputs.mem", "rb");
        $fread(input_samples, file);
        //file = $fopen("../../software_model/mnist_model_28input_1024entry_2hash_2bpi_labels.mem", "rb");
        file = $fopen("../../software_model/mnist_model_49input_8192entry_4hash_6bpi_labels.mem", "rb");
        $fread(input_labels, file);
        $display("Running simulation...");
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
            inp_vld = 1'b1;
            i = 0;
            j = 0;
            forever begin
                if (!last_stall) j = j + 1;
                if (j == ((`INPUT_BITS+`INPUT_BUS_WIDTH-1)/`INPUT_BUS_WIDTH)) begin
                    j = 0;
                    i = i + 1;
                end
                if (i == 10000) break;
                last_stall = stall;
                #10;
            end
            inp_vld = 1'b0;
        end
        begin
            samples = 0;
            correct = 0;
            while (samples < 10000) begin
                if (outp_vld) begin
                    if (outp == label) correct = correct + 1;
                    samples = samples + 1;
                    if ((samples % 1000) == 0) $display(samples);
                end
                #10;
            end
            $display(correct);
            
            $finish;
        end
        join
    end // initial begin
    
    initial begin
        //$vcdpluson(0, Top);
        $vcdpluson(2, Top);
        //$vcdpluson(0, Top.dut);
        $vcdplusfile("test_mnist.dump.vpd");
    end // initial begin

    device_interface dut(.clk(clk), .rst(rst), .inp_vld(inp_vld), .outp_vld(outp_vld), .stall(stall), .inp(inp), .outp(outp));
endmodule

