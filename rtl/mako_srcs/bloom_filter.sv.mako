############################################################
## Generator file for bloom_filter.sv
############################################################
<%!
    import math
    import global_parameters
%>\

module lookup_table (
    address,
    data
);
<%
    assert(math.log2(global_parameters.filter_entries).is_integer())
    num_inputs = int(math.log2(global_parameters.filter_entries))
%>\

    parameter reg   [${(1<<num_inputs)-1}:0]    DATA    = ${1<<num_inputs}'b0;

    input   [${num_inputs-1}:0] address;
    output  [0:0]               data;

    reg     [${(1<<num_inputs)-1}:0]    data_arr;

    initial
        data_arr = DATA;

    assign data = data_arr[address];

endmodule

module bloom_filter(
    clk, rst, inp_vld, outp_vld,
    hashed_inp,
    result
);
<%
    assert(math.log2(global_parameters.filter_entries).is_integer())
    hash_size = int(math.log2(global_parameters.filter_entries))
    max_state = global_parameters.hash_functions_per_filter - 1
%>\
    parameter reg   [${(1<<num_inputs)-1}:0]    DATA    = ${1<<num_inputs}'b0;

    input   clk;
    input   rst;
    input   inp_vld;
    output  outp_vld;

    input   [${hash_size-1}:0]  hashed_inp;
    output  [0:0]               result;

% if max_state > 1:
    reg     [${math.ceil(math.log2(max_state+1))-1}:0] state;
    wire    [${math.ceil(math.log2(max_state+1))-1}:0] vld_next_state;
% endif
    reg     [0:0] accumulator;
    wire    [0:0] vld_next_accumulator;
    reg     [0:0] r_outp_vld;
    wire    [0:0] next_r_outp_vld;

    wire[0:0] table_data;
    lookup_table #(.DATA(DATA)) lut(.address(hashed_inp), .data(table_data));

% if max_state > 1:
    assign vld_next_state = (state < ${max_state}) ? state+1 : 0;
    assign vld_next_accumulator = (state == 0) ? table_data : (accumulator & table_data);
    assign next_r_outp_vld = (state == ${max_state}) && inp_vld;
% else:
    assign vld_next_accumulator = table_data;
    assign next_r_outp_vld = inp_vld;
% endif

    always_ff @(posedge clk) begin
        if (rst) begin
% if max_state > 1:
            state <= 0;
% endif
            r_outp_vld <= 0;
        end else begin
            if (inp_vld) begin
% if max_state > 1:
                state <= vld_next_state;
% endif
                accumulator <= vld_next_accumulator;
            end
            r_outp_vld <= next_r_outp_vld;
        end
    end

    assign outp_vld = r_outp_vld;
    assign result = accumulator;

endmodule

