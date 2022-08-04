############################################################
## Generator file for interface.sv
############################################################
<%!
    import math
    import global_parameters
%>\

module device_interface(
    clk, rst, inp_vld, outp_vld, stall,
    inp,
    outp
);
<%
    input_size = global_parameters.input_bus_width
    output_size = math.ceil(math.log2(global_parameters.num_classes))
    model_input_size = global_parameters.input_bits
    cycles_to_fill = math.ceil(model_input_size / input_size)
    last_cycle_bits = model_input_size - ((cycles_to_fill-1) * input_size)
%>\
    input   clk;
    input   rst;
    input   inp_vld;
    output  outp_vld;
    output  stall;

    input   [${input_size-1}:0]     inp;
    output  [${output_size-1}:0]    outp;

    reg     [${model_input_size-1}:0]   model_input_pingpong    [1:0];
// synthesis translate_off
`ifndef SYNTHESIS
    initial $vcdplusmemon(model_input_pingpong);
`endif
// synthesis translate_on
    reg     [0:0]                       r_front_buffer_id;
    reg     [0:0]                       last_dispatch;
    reg     [0:0]                       last_fill;
    wire    [0:0]                       front_buffer_id;
    wire    [0:0]                       front_buffer_done;
    wire    [0:0]                       back_buffer_done;
    wire    [0:0]                       model_inp_vld;
    wire    [0:0]                       model_stall;
    
    assign front_buffer_id = r_front_buffer_id ^ (front_buffer_done && back_buffer_done);
    assign front_buffer_done = !model_stall && (last_dispatch == r_front_buffer_id);
    assign back_buffer_done = (last_fill == !r_front_buffer_id);
    assign model_inp_vld = model_stall || (last_dispatch != front_buffer_id); //!front_buffer_done;

    wisard model(
        .clk(clk), .rst(rst), .inp_vld(model_inp_vld), .outp_vld(outp_vld), .stall(model_stall),
        .inp(model_input_pingpong[front_buffer_id]), .outp(outp)
    );

% if cycles_to_fill > 1: 
    reg     [${math.ceil(math.log2(cycles_to_fill))-1}:0]   fill_state;
% endif

    always_ff @(posedge clk) begin
        if (rst) begin
            r_front_buffer_id <= 1'b0;
            last_dispatch <= 1'b0;
            last_fill <= 1'b0;
% if cycles_to_fill > 1: 
            fill_state <= 0;
% endif
        end else begin
            r_front_buffer_id <= front_buffer_id;
            if (model_inp_vld) begin
                last_dispatch <= front_buffer_id;
            end
            if (inp_vld && !stall) begin
% if cycles_to_fill > 1: 
                if (fill_state < ${cycles_to_fill-1}) begin
                    model_input_pingpong[!front_buffer_id][fill_state*${input_size}+:${input_size}] <= inp;
                    fill_state <= fill_state + 1;
                end else begin
                    model_input_pingpong[!front_buffer_id][fill_state*${input_size}+:${last_cycle_bits}] <= inp[${last_cycle_bits-1}:0];
                    last_fill <= !front_buffer_id;
                    fill_state <= 0;
                end
% else:
                model_input_pingpong[!front_buffer_id][0+:${last_cycle_bits}] <= inp[${last_cycle_bits-1}:0];
                last_fill <= !front_buffer_id;
%endif
            end
        end
    end

    assign stall = back_buffer_done && !front_buffer_done;

endmodule

