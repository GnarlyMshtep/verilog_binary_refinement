### Modules

- clocks
- debouncer
- sevenseg_table
  - (which can do negative numbers)
- random (imported)


```verilog 

module binary_refinement(
    input clk, 
    input rst, 
    input [7:0] sw, 
    input but_newgame, //these 3 buttons work in score mode
    input but_newplayer,
    input but_score, 
    input but_submit, // this button works in game mode 
    output wire [7:0] rish, 
    output wire [3:0] an 
);

localparam [31:0] game_time = 20; //game time in seconds


//debounce buttons
wire dbncd_but_newgame;
wire dbncd_but_newplayer;
wire dbncd_but_score;
wire dbncd_but_submit;

reg newgame_mode = 0;
reg newplayer_mode = 1;
reg score_mode = 0;
reg is_correct_mode = 0;

debouncer debounce_newgame(clk, but_newplayer, dbncd_but_newplayer);




// 00: your score
// 01: leaderboard 
// 10: game 
// 11: Correct/incorrect 
reg [1:0] mode; 

// clocks
wire clk_1hz;
wire clk_2hz;
wire clk_high;
wire clk_mid;
wire count_clk;

//your score mode variables 
reg [31:0] your_score; // maybe this shouldbe an int 
reg [3:0] your_name_0;
reg [3:0] your_name_1;
reg [3:0] your_name_2;
reg [3:0] your_name_3;

//leaderboard mode variables
reg [31:0] leader_score; // maybe this shouldbe an int 
reg [3:0] leader_name_0;
reg [3:0] leader_name_1;
reg [3:0] leader_name_2;
reg [3:0] leader_name_3;



```