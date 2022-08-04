############################################################
## Generator file for discriminator.sv
############################################################
<%!
    import math
    import global_parameters
%>\

module popcount (
    clk, rst, inp_vld, outp_vld,
    inp,
    sum
);
<%
    input_size = global_parameters.filters_per_discriminator
    output_size = math.ceil(math.log2(input_size+1))
%>\
    input   clk;
    input   rst;
    input   inp_vld;
    output  outp_vld;

    input   [${input_size-1}:0]     inp;
    output  [${output_size-1}:0]    sum;

    genvar g;

    wire    [0:0]   reduce_layer0 [${input_size-1}:0];
    generate for (g = 0; g < ${input_size}; g = g + 1) begin: gen_popcount_layer0
        assign reduce_layer0[g] = inp[g];
    end endgenerate

    wire    [0:0]   vld_layer0;
    assign vld_layer0 = inp_vld;

<%
    idx = 1
    layer_inputs = input_size
%>\
% while layer_inputs > 1:
<%
    layer_outputs = math.ceil(layer_inputs / 2)
    odd_input = not (layer_inputs / 2).is_integer()
%>\
    wire    [${idx}:0]  w_reduce_layer${idx}    [${layer_outputs-1}:0];
    reg     [${idx}:0]  reduce_layer${idx}      [${layer_outputs-1}:0];
// synthesis translate_off
`ifndef SYNTHESIS
    initial $vcdplusmemon(reduce_layer${idx});
`endif
// synthesis translate_on
    reg     [0:0]       vld_layer${idx};
    generate for (g = 0; g < ${layer_outputs - (1 if odd_input else 0)}; g = g + 1) begin: gen_popcount_layer${idx}
        assign w_reduce_layer${idx}[g] = reduce_layer${idx-1}[2*g] + reduce_layer${idx-1}[2*g+1];
    end endgenerate
% if odd_input:
    assign w_reduce_layer${idx}[${layer_outputs-1}] = reduce_layer${idx-1}[${layer_inputs-1}];
% endif

<%
    layer_inputs = layer_outputs
    idx += 1
%>\
% endwhile

    always_ff @(posedge clk) begin
        if (rst) begin
% for i in range(1, idx):
            vld_layer${i} <= 0;
% endfor
        end else begin
% for i in range(1, idx):
            reduce_layer${i} <= w_reduce_layer${i};
            vld_layer${i} <= vld_layer${i-1};
% endfor
        end
    end

    assign sum = reduce_layer${idx-1}[0][${output_size-1}:0];
    assign outp_vld = vld_layer${idx-1};

endmodule


module discriminator(
    clk, rst, inp_vld, outp_vld,
    inp,
    outp
);
<%
    input_size = global_parameters.filters_per_discriminator * int(math.log2(global_parameters.filter_entries))
    output_size = math.ceil(math.log2(global_parameters.filters_per_discriminator+1))
    num_filters = global_parameters.filters_per_discriminator
    filter_inputs = global_parameters.inputs_per_filter
    filter_entries = global_parameters.filter_entries
    assert(math.log2(global_parameters.filter_entries).is_integer())
    hash_size = int(math.log2(global_parameters.filter_entries))
    num_hashes = global_parameters.hash_functions_per_filter
    filter_data_total_size = num_filters * filter_entries
%> 
    parameter reg [${filter_data_total_size-1}:0] FILTER_DATA = ${filter_data_total_size}'b0;

    input   clk;
    input   rst;
    input   inp_vld;
    output  outp_vld;

    input   [${input_size-1}:0]     inp;
    output  [${output_size-1}:0]    outp;

    genvar g;

    // Instantiate ${num_filters} filters
    wire [${num_filters-1}:0]               filter_outps;
    wire [0:0]                              filter_outp_vld;
    bloom_filter #(.DATA(FILTER_DATA[0+:${filter_entries}])) filter0(
        .clk(clk), .rst(rst), .inp_vld(inp_vld), .outp_vld(filter_outp_vld),
        .hashed_inp(inp[0+:${hash_size}]), .result(filter_outps[0])
    );
    generate for (g = 1; g < ${num_filters}; g = g + 1) begin: gen_filt_inst
        bloom_filter #(.DATA(FILTER_DATA[g*${filter_entries}+:${filter_entries}])) filter(
            .clk(clk), .rst(rst), .inp_vld(inp_vld), .outp_vld(/* Intentionally left unconnected */),
            .hashed_inp(inp[g*${hash_size}+:${hash_size}]), .result(filter_outps[g])
        );
    end endgenerate

    // Counts the number of "1" filter outputs
    popcount count(
        .clk(clk), .rst(rst), .inp_vld(filter_outp_vld), .outp_vld(outp_vld),
        .inp(filter_outps),
        .sum(outp)
    );
endmodule

