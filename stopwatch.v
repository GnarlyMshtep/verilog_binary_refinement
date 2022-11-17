`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:28:36 10/26/2021 
// Design Name: 
// Module Name:    stopwatch 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
/* 
creates four clocks: 1hz, 2hz, 100hz, and 5hz
*/ 
module clocks( // this is the module that does the clock conversion -- it does so by checking simple equality of counters
	input clk,
	input rst,
	output reg clk_1hz, //? why does it output registers?  
	output reg clk_2hz,
	output reg clk_high,
	output reg clk_mid
	);

reg [31:0] hz1_a;
reg [31:0] hz2_a;
reg [31:0] hz_high;
reg [31:0] hz_mid;
	
always @ (posedge clk) begin
	if (rst) begin
		hz1_a <= 1'b0;
		clk_1hz = 0;
	end else begin
		hz1_a <= hz1_a + 'd1; 
		if (hz1_a == 'd50000000) begin
			clk_1hz = ~clk_1hz;
			hz1_a <= 0;
		end
	end
end

always @ (posedge clk) begin
	if (rst) begin
		hz2_a <= 1'b0;
		clk_2hz = 0;
	end else begin
		hz2_a <= hz2_a + 'd1;
		if (hz2_a == 'd25000000) begin
			clk_2hz = ~clk_2hz;
			hz2_a <= 0;
		end
	end
end

always @ (posedge clk) begin
	if (rst) begin
		hz_mid <= 1'b0;
		clk_mid = 0;
	end else begin
		hz_mid <= hz_mid + 'd1;
		if (hz_mid == 'd10000000) begin
			clk_mid = ~clk_mid;
			hz_mid <= 0;
		end
	end
end

always @ (posedge clk) begin
	if (rst) begin
		hz_high <= 1'b0;
		clk_high = 0;
	end else begin
		hz_high <= hz_high + 'd1;
		if (hz_high == 'd100000) begin
			clk_high = ~clk_high;
			hz_high <= 0;
		end
	end
end

endmodule

module debouncer( // we want to capture the button as only if it has been held for 2^16 clock cycles, we just keep recording it's value 
	input clk,
	input btn,
	output btn_db
	);

reg btn_db_temp;
reg [15:0] btn_count;

always @ (posedge clk) begin
	if(btn == 0) begin
		btn_count <= 0;
		btn_db_temp <= 0;
	end else begin
		btn_count <= btn_count + 1;
		if(btn_count == 16'b1111111111111111) begin
			btn_db_temp <= 1;
		end
	end
end

assign btn_db = btn_db_temp; //we use the assign statement becuase the output is a wire, which we can't write to 
                            //input wire is not meaningful 
	
endmodule

//Given an input 0-8, will translate to 8 bit array for seven sig display
module sevensig( //a convertor from numbers to segements, We always let the 7'th bit be on here (which is the dot next to the display) -- we might not want to do that 
	input [3:0] disp,
	output reg [7:0] rish
	);
	always @ (*) begin
		if(disp == 4'b1001) begin
			rish <= 8'b10010000;
		end
		if(disp == 4'b1000) begin
			rish <= 8'b10000000;
		end
		if(disp == 4'b0111) begin
			rish <= 8'b11111000;
		end
		if(disp == 4'b0110) begin
			rish <= 8'b10000010;
		end
		if(disp == 4'b0101) begin
			rish <= 8'b10010010;
		end
		if(disp == 4'b0100) begin
			rish <= 8'b10011001;
		end
		if(disp == 4'b0011) begin
			rish <= 8'b10110000;
		end
		if(disp == 4'b0010) begin
			rish <= 8'b10100100;
		end
		if(disp == 4'b0001) begin
			rish <= 8'b11111001;
		end
		if(disp == 4'b0000) begin
			rish <= 8'b11000000;
		end
	end
endmodule

// will select a clock depending on the value of adj -- this will be useful once pause is clicked
module demux_clk(
    input clk,
    input clk_1hz,
    input clk_2hz,
    input adj,
    output clk_out
    );

reg clk_temp;
    
always @ (posedge clk) begin
    if(adj) begin
        clk_temp = clk_2hz;
    end else begin
        clk_temp = clk_1hz;
    end
end

assign clk_out = clk_temp;
    
endmodule

module counter( // takes all input from the board, gives output of the number in each place
	input clk,
	input rst,
	input pause,
	input sel, //select if we want to use the adj
	input adj,

	output reg [3:0] m1, //here they didn't do output wire, see Ben Jackson's comment: https://stackoverflow.com/questions/5360508/using-wire-or-reg-with-input-or-output-in-verilog
    output reg [3:0] m0,
    output reg [3:0] s1,
    output reg [3:0] s0
	);

always @ (posedge clk or posedge rst) begin //we just incremnet conditioanlly, this is not complicated
	if(rst) begin
        m0 = 'd0;
        m1 = 'd0;
        s0 = 'd0;
        s1 = 'd0;
	end else if(pause) begin
		s0 = s0;
		s1 = s1;
		m0 = m0;
		m1 = m1;
	end else if(adj) begin // this is where we increment based on select
        if(sel) begin
            if(s0 == 'd9) begin
                s0 = 'd0;
                if(s1 == 'd5) begin
                    s1 = 'd0;
                end else begin
                    s1 = s1 + 'd1;
                end
            end else begin
                s0 = s0 + 'd1;
            end
        end else begin
            if(m0 == 'd9) begin
                m0 = 'd0;
                if(m1 == 'd5) begin
                    m1 = 'd0;
                end else begin
                    m1 = m1 + 'd1;
                end
            end else begin
                m0 = m0 + 'd1;
            end
        end
    end else if(s0 == 'd9) begin//normal incrmentation 
		s0 = 'd0;
		if(s1 == 'd5) begin
		    s1 = 'd0;
		    if(m0 == 'd9) begin
		        m0 = 'd0;
		        if(m1 == 'd5) begin
		            m1 = 'd0;
		        end else begin
		            m1 = m1 + 'd1;
		        end
		    end else begin
		        m0 = m0 + 'd1;
		    end
		end else begin
		    s1 = s1 + 'd1;
		end
	end else begin
		s0 = s0 + 'd1;
	end
end

endmodule

module display(
    input clk_high,
    input clk_blink,
    input rst, //reset  
    input adj, //select which clock 
    input sel, // slect if mins or second are selected
    input [7:0] min1,
    input [7:0] min0,
    input [7:0] sec1,
    input [7:0] sec0,
    output wire [7:0] rish, //the display we should have 
    output wire [3:0] an    // for whcih digit
    );
    
reg [1:0] anode_state = 2'b0;
reg [7:0] rish_temp;
reg [3:0] an_temp;

always @ (posedge clk_high or posedge rst) begin
	if(rst) begin
		anode_state <= 0;
		rish_temp <= 8'b11000000; // not sure why to assign this value -- I guess these should be chaned on the next clock cycle... Maybe this sets a 0
		                            // we should experiment and see what happens if we hold rst
		an_temp <= 4'b1111;
    end else if(anode_state == 0) begin
        anode_state <= anode_state + 1; //we cycle through which digit which should display (we do this in both conditions ahwich are not rest )
        rish_temp <= min1;              // 0 is the first digit
        an_temp <= 4'b0111;             // the only thing we'll show
        if(clk_blink) begin             //Here we do the blinking by turning all the display off 
            if(adj) begin               // They blink if the blicking conditions
                if(!sel) begin
                    an_temp <= 4'b1111;
                end
            end
        end
    end else if(anode_state == 1) begin
        anode_state <= anode_state + 1;
        rish_temp <= min0;
        an_temp <= 4'b1011;
        if(clk_blink) begin
            if(adj) begin
                if(!sel) begin
                    an_temp <= 4'b1111;
                end
            end
        end
    end else if(anode_state == 2) begin
        anode_state <= anode_state + 1;
        rish_temp <= sec1;
        an_temp <= 4'b1101;
        if(clk_blink) begin
            if(adj) begin
                if(sel) begin
                    an_temp <= 4'b1111;
                end
            end
        end
    end else if(anode_state == 3) begin
        anode_state <= 2'b0;
        rish_temp <= sec0;
        an_temp <= 4'b1110;
        if(clk_blink) begin
            if(adj) begin
                if(sel) begin
                    an_temp <= 4'b1111;
                end
            end
        end
    end
end  
    
assign rish = rish_temp;
assign an   = an_temp;
    
endmodule

// main module, will create clocks then start counting
module stopwatch(
	input clk,
	input btns,//btn stop and btn reset
	input btnr,
	input sw0,
	input sw1,
	output [7:0] rish,
	output [3:0] an
	);
	
// clocks
wire clk_1hz;
wire clk_2hz;
wire clk_high;
wire clk_mid;
wire count_clk;

// minutes and seconds placeholders m1m0:s1s0
wire [3:0] m0;
wire [3:0] m1;
wire [3:0] s0;
wire [3:0] s1;

// sevensig encoding of m1m0:s1s0
wire [7:0] rish_min0;
wire [7:0] rish_min1;
wire [7:0] rish_sec0;
wire [7:0] rish_sec1;

wire pause_btn;
reg pause = 0;// so we can flip the state

debouncer debounce_pause(clk, btnr, pause_btn);

always @ (posedge pause_btn) begin
	pause = ~pause;
end

clocks clocks_inst( //init clks
	.clk(clk), .rst(btns), //not best choice of name
	.clk_1hz(clk_1hz), 
	.clk_2hz(clk_2hz), 
	.clk_high(clk_high), 
	.clk_mid(clk_mid)
	);
    
demux_clk choose_clk(
    .clk(clk),
    .clk_1hz(clk_1hz),
    .clk_2hz(clk_2hz),
    .adj(sw1), //if sw1 is high, we want to use the 2hz clock for incrememnting 
    .clk_out(count_clk) //the clock with which we count up or down (how do we choose what to count at this speed? )
    );
	
counter counter_inst(
	.clk(count_clk),
	.rst(btns),
	.pause(pause),
	.sel(sw0),
	.adj(sw1),
	.m1(m1),
	.m0(m0),
	.s1(s1),
	.s0(s0)
	);
	
sevensig sevensig_m1(.disp(m1), .rish(rish_min1));
sevensig sevensig_m0(.disp(m0), .rish(rish_min0));
sevensig sevensig_s1(.disp(s1), .rish(rish_sec1));
sevensig sevensig_s0(.disp(s0), .rish(rish_sec0));

display display_inst(
    .clk_high(clk_high),
    .clk_blink(clk_mid),
    .rst(btns),
    .sel(sw0),
	.adj(sw1),
    .min1(rish_min1),
    .min0(rish_min0),
    .sec1(rish_sec1),
    .sec0(rish_sec0),
    .rish(rish),
    .an(an)
    );

endmodule
