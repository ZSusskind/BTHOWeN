############################################################
## Generator file for hash.sv
############################################################
<%!
    import math
    import global_parameters
%>\

module h3_hash (
    clk, rst, inp_vld, outp_vld,
    input_value, hash_values,
    hash_result
);
<%
    input_size = global_parameters.inputs_per_filter
    assert(math.log2(global_parameters.filter_entries).is_integer())
    hash_size = int(math.log2(global_parameters.filter_entries))
    hash_input_set_size = input_size * hash_size;
    intermediate_buffer = False #// Set this to True if you encounter timing violations
%>\
    input   clk;
    input   rst;
    input   inp_vld;
    output  outp_vld;

    input   [${input_size-1}:0]             input_value;
    input   [${hash_input_set_size-1}:0]    hash_values;
    output  [${hash_size-1}:0]  hash_result;

    genvar g;

    // Assumption: We can handle all of this in a single cycle
    // That might not be a good assumption, in which case we should look into retiming / repipelining
    // A simple approach would be to add some "do-nothing" registers to the design
    wire    [${hash_input_set_size-1}:0]    w_gated_values;
    generate for (g = 0; g < ${input_size}; g = g + 1) begin: gen_gated_val
        assign w_gated_values[g*${hash_size}+:${hash_size}] = input_value[g] ? hash_values[g*${hash_size}+:${hash_size}] : 0;
    end endgenerate

% if intermediate_buffer:
    reg     [${hash_input_set_size-1}:0]    gated_values;
    reg     [0:0]                           gated_values_vld;
% else: 
    wire    [${hash_input_set_size-1}:0]    gated_values;
    wire    [0:0]                           gated_values_vld;
    assign gated_values = w_gated_values;
    assign gated_values_vld = inp_vld;
% endif

    wire    [${hash_size-1}:0]  w_hash_result;
    generate for (g = 0; g < ${hash_size}; g = g + 1) begin: gen_hash_res
        assign w_hash_result[g:g] = 
% for i in range(input_size-1):
            gated_values[${i*hash_size}+g] ^
% endfor
            gated_values[${(input_size-1)*hash_size}+g];
    end endgenerate

    reg     [${hash_size-1}:0]  r_hash_result;
    reg     r_outp_vld;
    always_ff @(posedge clk) begin
        if (rst) begin
% if intermediate_buffer:
            gated_values_vld <= 0;
% endif
            r_outp_vld <= 0;
        end else begin
% if intermediate_buffer:
            gated_values <= w_gated_values;
            gated_values_vld <= inp_vld;
% endif
            r_hash_result <= w_hash_result;
            r_outp_vld <= gated_values_vld;
        end
    end 

    assign hash_result = r_hash_result;
    assign outp_vld = r_outp_vld;

endmodule

