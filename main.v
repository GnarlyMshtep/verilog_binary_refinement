//decodes keypad value
module keypad_decoder(
    input clk,
    input [3:0] row,                      // 4 buttons per row, Pmod JA pins 10 to 7
    output reg [3:0] col,                 // 4 buttons per col, Pmod JA pins 4 to 1
    output reg [3:0] dec_out              // binary value of button press
    );

    parameter LAG = 10;                   // 100ns delay for button presses

	reg [19:0] scan_timer = 0;            // to count up to 99,999
	reg [1:0] col_select = 0;             // 2 bit counter to select 4 columns
	
	// scan timer/column select control
	always @(posedge clk)                 // 1ms
		if(scan_timer == 99_999) begin    // 100MHz / 100,000 = 1000
			scan_timer <= 0;
			col_select <= col_select + 1;
		end
		else
			scan_timer <= scan_timer + 1;

    // set columns, check rows
	always @(posedge clk)
		case(col_select)
			2'b00 :	begin
					   col = 4'b0111;
					   if(scan_timer == LAG)
						  case(row)
						      4'b0111 :	dec_out = 4'b0001;	// 1
						      4'b1011 :	dec_out = 4'b0100;	// 4
						      4'b1101 :	dec_out = 4'b0111;	// 7
						      4'b1110 :	dec_out = 4'b0000;	// 0
						  endcase
					end
			2'b01 :	begin
					   col = 4'b1011;
					   if(scan_timer == LAG)
						  case(row)    		
						      4'b0111 :	dec_out = 4'b0010;	// 2	
						      4'b1011 :	dec_out = 4'b0101;	// 5	
						      4'b1101 :	dec_out = 4'b1000;	// 8	
					          4'b1110 : dec_out = 4'b1111;	// F
			              endcase
			        end 
			2'b10 :	begin       
					   col = 4'b1101;
					   if(scan_timer == LAG)
						  case(row)    		       
						      4'b0111 :	dec_out = 4'b0011;	// 3 		
						      4'b1011 :	dec_out = 4'b0110;	// 6 		
						      4'b1101 :	dec_out = 4'b1001;	// 9 		
						      4'b1110 : dec_out = 4'b1110;	// E	    
						  endcase      
					end
			2'b11 :	begin
					   col = 4'b1110;
					   if(scan_timer == LAG)
						  case(row)    
						      4'b0111 :	dec_out = 4'b1010;	// A
						      4'b1011 :	dec_out = 4'b1011;	// B
						      4'b1101 :	dec_out = 4'b1100;	// C
						      4'b1110 :	dec_out = 4'b1101;	// D
						  endcase      
					end
		endcase
endmodule

//controls seven segment display with the keypad... testing purposes for now
module seg7_keypad_control(
    input [3:0] dec,        // from decoder
    output [3:0] an,        // anodes
    output reg [7:0] rish    // cathodes
    );

	assign an = 4'b1110;   // only using far right digit for testing

    // segment patterns based on decoder value
	always @(dec) begin
		case (dec)       // gfedcba  <-- segment order
			4'h0 : rish = 7'b1000000;   // 0
			4'h1 : rish = 7'b1111001;   // 1
			4'h2 : rish = 7'b0100100;   // 2
			4'h3 : rish = 7'b0110000;   // 3
			4'h4 : rish = 7'b0011001;   // 4
			4'h5 : rish = 7'b0010010;   // 5
			4'h6 : rish = 7'b0000010;   // 6
			4'h7 : rish = 7'b1111000;   // 7
			4'h8 : rish = 7'b0000000;   // 8
			4'h9 : rish = 7'b0010000;   // 9
			4'hA : rish = 7'b0001000;   // A
			4'hB : rish = 7'b0000011;   // B
			4'hC : rish = 7'b1000110;   // C
			4'hD : rish = 7'b0100001;   // D
			4'hE : rish = 7'b0000110;   // E
			4'hF : rish = 7'b0001110;   // F	
		endcase
	end

endmodule

//main module
module binary_refinement(
    input clk, 
    input rst, 
    input [7:0] sw, 
    input but_newgame, //these 3 buttons work in score mode
    input but_newplayer,
    input but_score, 
    input but_submit, // this button works in game mode 
    //INPUT : keypad 
    input [3:0] rows,   // 4 buttons per row, Pmod JB pins 10 to 7
    output [3:0] cols,  // 4 buttons per col, Pmod JB pins 4 to 1
    output wire [7:0] rish, 
    output wire [3:0] an 
);

localparam [31:0] game_time = 20; //game time in seconds


//instantiate clocks 
wire clk_1hz;
wire clk_high;
wire clk_mid;
clocks clocks_inst( //init clks
	.clk(clk), .rst(btns), //not best choice of name
	.clk_1hz(clk_1hz), 
	.clk_high(clk_high), 
	.clk_mid(clk_mid)
	);

//debounce buttons
wire dbncd_but_newgame;
wire dbncd_but_newplayer;
wire dbncd_but_score; //toggles to score and leaderboard mode
wire dbncd_but_submit;

//reg newgame_mode = 0;
//reg newplayer_mode = 1;
//reg score_mode = 0;
//reg is_correct_mode = 0;

debouncer debounce_newgame(clk, but_newplayer, dbncd_but_newplayer);
debouncer debounce_newgame(clk, but_newgame, dbncd_but_newgame);
debouncer debounce_newgame(clk, but_score, dbncd_but_score);
debouncer debounce_newgame(clk, but_submit, dbncd_but_submit);


// 000: your score  : they will display (name:) Cxxx , Sxxx (display both at once -- we will have 2 seven segment displays)
// 001: leaderboard : they will display (name:) Lxxx , Sxxx

// 010: game        : there's a random challenge displaying on the 7-seg, and you turn the switches to match the binary number, and then press but_submit
                        //automatically, you go into correct/incorrect mode, which displays if you were correct or incorrect (and how many points you got from that single game), and then after a certain amoutn of time, changes into score mode
// 011: Correct/incorrect : explained above. Shows {1,0} for like 2 seconds, then goes into your score mode
// 100: newplayer         : you tap on the keypad your name (which is 3 numbers) which show on the display, and once you click submit, you go into your score mode.
reg [2:0] mode; 

// clocks
wire clk_1hz;
wire clk_2hz;
wire clk_high;
wire clk_mid;
wire count_clk;

//your score mode variables 
reg [31:0] your_score; // maybe this shouldbe an int 

wire [3:0] your_name_0;
wire [3:0] your_name_1;
wire [3:0] your_name_2;

//have rish registers


//leaderboard mode variables
reg [31:0] leader_score; // maybe this shouldbe an int 
wire [3:0] leader_name_0;
wire [3:0] leader_name_1;
wire [3:0] leader_name_2;
wire [3:0] leader_name_3;


//game mode 
reg [8:0] rand_chal ; // allow also negative numbers 
wire [3:0] rand_chal_dig0;
wire [3:0] rand_chal_dig1;
wire [3:0] rand_chal_dig2;
wire [3:0] rand_chal_dig3;
reg [5:0] time_since_start;

num_to_digits num_to_digits_game_mode_inst(
    .num(rand_chal), 
    .dig0(rand_chal_dig0),
    .dig1(rand_chal_dig1),
    .dig2(rand_chal_dig2),
    .dig3(rand_chal_dig3)
);

//sevensig sevensig_();

//correct_incorrect mode
reg is_correct; 
//these will always be 0 -- we use 0 and 1 on the display to indicate correctness

sevensig sevensig_is_correct(.disp(is_correct), .rish(rand_chal_dig0));



//handle button presses 
always @ (posedge clk and (dbncd_but_newgame or dbncd_but_newplayer or dbncd_but_score or dbncd_but_submit)) begin 
//do depending on the mode
    if ((mode == 3'b000 or mode == 3'b001) and dbncd_but_score) begin
        mode <= mode ^ 2'b001;
    end if ((mode == 3'b000 or mode == 3'b001) and dbncd_but_newgame) begin
        //get new random number and assign 
        rand_chal = 'd4; 
        mode <= 2'b010;
        time_since_start <= 'd0;
    end if (dbncd_but_newplayer) begin
        mode <= 3'100;
    end else if (mode == 3'b010 and dbncd_but_submit) begin
        if (sw == rand_chal) begin // if correct 
            is_correct <= 'd1;
            your_score <= your_score + ('d20 - time_since_start); //max score for each challenge is 20    
        end else begin 
            is_correct <= 'd0;
            your_score <= your_score - 'd5; //minus 5 points for incorrect
        end 
        mode <= 3'b011; 
end

//game mode
//increments time by 1 when in game mode
//is the posedge 1 sec?
always @ (posedge clk) begin
	if (mode == 3'010) begin
        time_since_start <= time_since_start + 'd1;
    end
end

demux_display_based_on_mode demux_display_based_on_mode_inst(
	.clk(count_clk),
	.rst(btns),
	//DO MORE STUFF 
	.m1(m1),
	.m0(m0),
	.s1(s1),
	.s0(s0)
	);

//this should only display in newplayer mode
wire [3:0] w_dec; //output of button value

keyoad_decoder d(
    .clk(clk),
    .row(rows),
	.col(cols), 
    .dec_out(w_dec)
    );

seg7_keypad_control s(
    .dec(w_dec),
    .an(an), 
    .rish(rish));

endmodule