############################################################
## Generator file for wisard.sv
############################################################
<%!
    import math
    import global_parameters
%>\
`include "sv_srcs/model_parameters.svh"

module max_idx(
    clk, rst, inp_vld, outp_vld,
    inp_values,
    max_index
);
<%
    entry_size = math.ceil(math.log2(global_parameters.filters_per_discriminator+1))
    index_size = math.ceil(math.log2(global_parameters.num_classes))
    input_entries = global_parameters.num_classes
%>\
    input   clk;
    input   rst;
    input   inp_vld;
    output  outp_vld;

    input   [${entry_size-1}:0] inp_values  [${input_entries-1}:0];
// synthesis translate_off
`ifndef SYNTHESIS
    initial $vcdplusmemon(inp_values);
`endif
// synthesis translate_on
    output  [${index_size-1}:0] max_index;

    genvar g;

    wire    [${entry_size-1}:0] reduce_layer0   [${input_entries-1}:0];
    wire    [${index_size-1}:0] index_layer0    [${input_entries-1}:0];
    wire    [0:0]               vld_layer0;
    assign reduce_layer0 = inp_values;
    generate for (g = 0; g < ${input_entries}; g = g + 1) begin: gen_max_layer0
        assign index_layer0[g] = g;
    end endgenerate
    assign vld_layer0 = inp_vld;

<%
    idx = 1
    layer_inputs = input_entries
%>\
% while layer_inputs > 1:
<%
    layer_outputs = math.ceil(layer_inputs / 2)
    odd_input = not (layer_inputs / 2).is_integer()
%>\
    reg     [${entry_size-1}:0] reduce_layer${idx}      [${layer_outputs-1}:0];
    reg     [${index_size-1}:0] index_layer${idx}       [${layer_outputs-1}:0];
    wire    [${entry_size-1}:0] w_reduce_layer${idx}    [${layer_outputs-1}:0];
    wire    [${index_size-1}:0] w_index_layer${idx}     [${layer_outputs-1}:0];
    reg     [0:0]               vld_layer${idx};
// synthesis translate_off
`ifndef SYNTHESIS
        initial $vcdplusmemon(reduce_layer${idx});
        initial $vcdplusmemon(index_layer${idx});
`endif
// synthesis translate_on
    // In the event of a tie, the lower-indexed (left-hand) term should win
    generate for (g = 0; g < ${layer_outputs - (1 if odd_input else 0)}; g = g + 1) begin: gen_max_layer${idx}
        assign w_reduce_layer${idx}[g] = (reduce_layer${idx-1}[2*g] >= reduce_layer${idx-1}[2*g+1]) ? reduce_layer${idx-1}[2*g] : reduce_layer${idx-1}[2*g+1];
        assign w_index_layer${idx}[g] = (reduce_layer${idx-1}[2*g] >= reduce_layer${idx-1}[2*g+1]) ? index_layer${idx-1}[2*g] : index_layer${idx-1}[2*g+1];
    end endgenerate
% if odd_input:
    assign w_reduce_layer${idx}[${layer_outputs-1}] = reduce_layer${idx-1}[${layer_inputs-1}];
    assign w_index_layer${idx}[${layer_outputs-1}] = index_layer${idx-1}[${layer_inputs-1}];
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
            index_layer${i} <= w_index_layer${i};
            vld_layer${i} <= vld_layer${i-1};
% endfor
        end
    end

    assign max_index = index_layer${idx-1}[0];
    assign outp_vld = vld_layer${idx-1};

endmodule

module wisard(
    clk, rst, inp_vld, outp_vld, stall,
    inp,
    outp
);
<%
    input_size = global_parameters.input_bits
    num_classes = global_parameters.num_classes
    output_size = math.ceil(math.log2(global_parameters.num_classes))
    discriminator_output_size = math.ceil(math.log2(global_parameters.filters_per_discriminator+1))
    num_filters = global_parameters.filters_per_discriminator
    filter_inputs = global_parameters.inputs_per_filter
    filter_entries = global_parameters.filter_entries
    assert(math.log2(global_parameters.filter_entries).is_integer())
    hash_size = int(math.log2(global_parameters.filter_entries))
    num_hashes = global_parameters.hash_functions_per_filter
    discriminator_filter_data_size = num_filters * filter_entries
    total_filter_data_size = discriminator_filter_data_size * num_classes
    hash_parameter_set_size = filter_inputs * hash_size
    hash_parameter_total_size = hash_parameter_set_size * num_hashes
%>\

    parameter reg [${total_filter_data_size-1}:0] FILTER_DATA = `MODEL_PARAM_FILTER_DATA; 
    parameter reg [${hash_parameter_total_size-1}:0] HASH_PARAMS = `MODEL_PARAM_HASH_PARAMS;

    input   clk;
    input   rst;
    input   inp_vld;
    output  outp_vld;
    output  stall;

    input   [${input_size-1}:0]     inp;
    output  [${output_size-1}:0]    outp;

    genvar g;
    
    reg [${hash_parameter_total_size-1}:0] hash_parameters;
    initial begin
        hash_parameters = HASH_PARAMS;
    end

<%
    num_hashers = min(global_parameters.hashers_per_discriminator, num_filters)
    hash_steps = math.ceil(num_filters / num_hashers)
    last_step_hashes = num_filters - (num_hashers * (hash_steps - 1))
    has_tmp_buffer = num_hashers < num_filters
    tmp_buffer_size = hash_size*(num_filters-last_step_hashes)
%>\
    reg     [${math.ceil(math.log2(num_hashes+1))-1}:0]   hash_inp_count;
    reg     [${math.ceil(math.log2(hash_steps+1))-1}:0]   hash_inp_state;
    // reg     [${math.ceil(math.log2(num_hashes+1))-1}:0]   hash_outp_count; // Unnecessary since filters count internally
    reg     [${math.ceil(math.log2(hash_steps+1))-1}:0]   hash_outp_state;
    
    wire    [${hash_parameter_set_size-1}:0]    sel_hash_params;
    assign sel_hash_params = hash_parameters[hash_inp_count*${hash_parameter_set_size}+:${hash_parameter_set_size}];

% if has_tmp_buffer:
    // Since we have fewer hash units than filters, we need a way to store intermediate results
    reg [${tmp_buffer_size-1}:0]  tmp_hash_buffer;
% endif

    // Instantiate ${num_hashers} hash units
    wire [${(filter_inputs*num_hashers)-1}:0]   hasher_inps;
    wire [${(hash_size*num_hashers)-1}:0]       hasher_outps;
    wire [0:0]                                  hasher_outp_vld;
% if last_step_hashes < num_hashers:
    wire [${hash_steps*num_hashers*filter_inputs-1}:0] padded_inp;
    assign padded_inp[${hash_steps*num_hashers*filter_inputs-1}:${input_size}] = 0;
    assign padded_inp[${input_size}:0] = inp;
    assign hasher_inps = padded_inp[hash_inp_state*${num_hashers*filter_inputs}+:${num_hashers*filter_inputs}];
% else:
    assign hasher_inps = inp[hash_inp_state*${num_hashers*filter_inputs}+:${num_hashers*filter_inputs}];
% endif
    h3_hash hasher0(
        .clk(clk), .rst(rst), .inp_vld(inp_vld), .outp_vld(hasher_outp_vld),
        .input_value(hasher_inps[0+:${filter_inputs}]), .hash_values(sel_hash_params),
        .hash_result(hasher_outps[0+:${hash_size}])
    );
    generate for (g = 1; g < ${num_hashers}; g = g + 1) begin: gen_hash_inst
        h3_hash hasher(
            .clk(clk), .rst(rst), .inp_vld(inp_vld), .outp_vld(/* Intentionally left unconnected */),
            .input_value(hasher_inps[g*${filter_inputs}+:${filter_inputs}]), .hash_values(sel_hash_params),
            .hash_result(hasher_outps[g*${hash_size}+:${hash_size}])
        );
    end endgenerate

    wire [${(hash_size*num_filters)-1}:0]   filter_inps;
% if has_tmp_buffer:
    wire [${hash_steps*num_hashers*hash_size-1}:0] full_hash_result;
    assign full_hash_result = {hasher_outps, tmp_hash_buffer};
    assign filter_inps = full_hash_result[${(hash_size*num_filters)-1}:0];
% else:
    assign filter_inps = hasher_outps;
% endif
    
    wire [0:0]  discrim_inp_vld;
    assign discrim_inp_vld = hasher_outp_vld && (hash_outp_state == ${hash_steps-1}); // Assumption: All hashers operate in lockstep

    // Instantiate ${num_classes} discriminators
    wire    [${discriminator_output_size-1}:0]  discrim_outp        [${num_classes-1}:0];
    wire    [0:0]                               discrim_outp_vld;
    discriminator #(.FILTER_DATA(FILTER_DATA[0+:${discriminator_filter_data_size}])) discrim0(
        .clk(clk), .rst(rst), .inp_vld(discrim_inp_vld), .outp_vld(discrim_outp_vld),
        .inp(filter_inps), .outp(discrim_outp[0])
    );
    generate for (g = 1; g < ${num_classes}; g = g + 1) begin: gen_discriminator
        discriminator #(.FILTER_DATA(FILTER_DATA[g*${discriminator_filter_data_size}+:${discriminator_filter_data_size}])) discrim(
            .clk(clk), .rst(rst), .inp_vld(discrim_inp_vld), .outp_vld(/* Intentionally unconnected */),
            .inp(filter_inps), .outp(discrim_outp[g])
        );
    end endgenerate

    // Finds the index of the maximum results
    max_idx max(
        .clk(clk), .rst(rst), .inp_vld(discrim_outp_vld), .outp_vld(outp_vld),
        .inp_values(discrim_outp),
        .max_index(outp)
    );
    
    reg[0:0] r_stall;
    always_ff @(posedge clk) begin
        if (rst) begin
            hash_inp_count <= 0;
            hash_inp_state <= 0;
            hash_outp_state <= 0;
            r_stall <= 0;
        end else begin
            r_stall <= inp_vld && !((hash_inp_count == ${num_hashes-1}) && (hash_inp_state == ${hash_steps-1}));
            if (inp_vld) begin
                if (hash_inp_state == ${hash_steps-1}) begin
                    hash_inp_count <= (hash_inp_count < ${num_hashes-1}) ? hash_inp_count+1 : 0;
                end
                hash_inp_state <= (hash_inp_state < ${hash_steps-1}) ? hash_inp_state+1 : 0;
            end
            if (hasher_outp_vld) begin
                hash_outp_state <= (hash_outp_state < ${hash_steps-1}) ? hash_outp_state+1 : 0;
% if has_tmp_buffer:
                tmp_hash_buffer[${tmp_buffer_size-1}:${tmp_buffer_size-(hash_size*num_hashers)}] <= hasher_outps;
% if hash_steps > 2:
                tmp_hash_buffer[${tmp_buffer_size-(hash_size*num_hashers)-1}:0] <= tmp_hash_buffer[${tmp_buffer_size-1}:${hash_size*num_hashers}];
% endif
% endif
            end
        end 
    end

    assign stall = r_stall;
endmodule

