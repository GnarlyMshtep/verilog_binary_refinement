
module binary_refinement(
    input clk, 
    input rst, 
    input [7:0] sw, 
    input but_newgame, //these 3 buttons work in score mode
    input but_newplayer,
    input but_score, 
    input but_submit, // this button works in game mode 
    //INPUT : keypad 
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

sevensig sevensig_();

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
        rand_chal = ; 
        mode <= 2'b010;
        time_since_start <= 0;
    end if (dbncd_but_newplayer) begin
        mode <= 3'100;
    end else if (mode == 3'b010 and dbncd_but_submit) begin
        if (sw == rand_chal) begin // if correct 
            is_correct <= 1;    
        end else begin 
            is_correct <= 0;
        end 
        mode <= 3'b011; 

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

endmodule