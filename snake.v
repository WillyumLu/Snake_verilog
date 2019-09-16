module snake
	(
		CLOCK_50,						//	On Board 50 MHz
		
		// Your inputs and outputs here
      KEY,
      SW,
		  
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		HEX0
	);

	input	  CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;			//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	output [6:0] HEX0;
	
	wire resetn;
	// change this later
	assign HEX0[6] = 1;
	assign HEX0[5] = 0;
	assign HEX0[4] = 0;
	assign HEX0[3] = 0;
	assign HEX0[2] = 0;
	assign HEX0[1] = 0;
	assign HEX0[0] = 0;
	assign resetn = SW[9];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
		
	datapath d0(
	         .clk(CLOCK_50),
	         .direction(direction),
				.direction_two(direction_two),
				.inmenu(SW[0]),
				.ingame(SW[1]),
		      .RGB(colour),
				.x_pointer(x),
				.y_pointer(y),
				.inital_head(SW[2])
	 );
	 
	 
	 //direction wire
	 wire [4:0] direction;
	 wire [4:0] direction_two;

	 swInput swIn(CLOCK_50, SW, direction_two);
	 kbInput kbIn(CLOCK_50, KEY, direction);
	 
endmodule


module datapath(clk, direction, direction_two, inmenu, ingame, RGB, x_pointer, y_pointer ,inital_head );
   input clk;
	
	output [7:0] x_pointer;
	output [6:0] y_pointer;
	input [4:0] direction;
	input [4:0] direction_two;

	
	//delete later
	input inital_head;
	
	//status of game
   input inmenu;
	input ingame;
	
	
	wire R, G, B; // Will be used for concatenation for output "RGB".
	wire frame_update; // signal for frame update
	wire delayed_clk;
	
	output [2:0] RGB; // the colour used for output
	
	reg border;
	//registers for snake 1
	reg [6:0] size;
	reg [7:0] snakeX[0:640];
	reg [6:0] snakeY[0:640];
	reg found;
	reg snakeHead;
	reg snakeBody;
	reg [1:0]currentDirect;
	integer bodycounter, bodycounter2, bodycounter3;
	reg up,down,left,right;
	// snake 2
	reg [6:0] size_two;
	reg [7:0] snakeX_two[0:640];
	reg [6:0] snakeY_two[0:640];
	reg found_two;
	reg snakeHead_two;
	reg snakeBody_two;
	reg [1:0]currentDirect_two;
	integer bodycounter_two, bodycounter2_two, bodycounter3_two;
	reg up_two,down_two,left_two,right_two;

	
	//apple
	reg edible1;
	reg [7:0] edible1X;
	reg [6:0] edible1Y;
	wire [7:0] edible1_randX;
	wire [6:0] edible1_randY;
	randomGrid rand1(clk, edible1_randX, edible1_randY);
	//collision
	reg edible1_collision, game_over;
	
	refresher ref0(clk, x_pointer, y_pointer);
	frame_updater upd0(clk, 1'b1, frame_update);
	delay_counter dc0(clk, 1'b1, frame_update,delayed_clk);
	
	
	
	always@(posedge clk)
	begin
		if (inmenu)begin
			 //reset position for snake body position holders	
			 for(bodycounter3 = 1; bodycounter3 < 641; bodycounter3 = bodycounter3+1)begin
					snakeX[bodycounter3] = 160;
					snakeY[bodycounter3] = 120;
			 end
			 
			 for(bodycounter3_two = 1; bodycounter3_two < 641; bodycounter3_two = bodycounter3_two+1)begin
					snakeX_two[bodycounter3_two] = 160;
					snakeY_two[bodycounter3_two] = 120;
			 end

			 //snake's size
			 size = 1;
			 size_two = 1;
			 
			 //First apple will have fix position
			 edible1X = 80;
			 edible1Y = 80;


			 //start game
			 game_over=0;
		end
		else if(ingame)begin
		
				//Add Snake 1 body
				found = 0;
				for(bodycounter = 1; bodycounter <= size; bodycounter = bodycounter + 1)begin
					if(~found)begin				
						snakeBody = ((x_pointer >= snakeX[bodycounter] && x_pointer <= snakeX[bodycounter]+2) 
								  && (y_pointer >= snakeY[bodycounter] && y_pointer <= snakeY[bodycounter]+2));
						found = snakeBody;
					end
				end
				//snake 2
				found_two = 0;
				for(bodycounter_two = 1; bodycounter_two <= size_two; bodycounter_two = bodycounter_two + 1)begin
					if(~found_two)begin				
						snakeBody_two = ((x_pointer >= snakeX_two[bodycounter_two] && x_pointer <= snakeX_two[bodycounter_two]+2) 
								  && (y_pointer >= snakeY_two[bodycounter_two] && y_pointer <= snakeY_two[bodycounter_two]+2));
						found_two = snakeBody_two;
					end
				end
				
				//Add Snake head
				snakeHead = (x_pointer >= snakeX[0] && x_pointer <= (snakeX[0]+2))
								&& (y_pointer >= snakeY[0] && y_pointer <= (snakeY[0]+2));
				//snake 2
				snakeHead_two = (x_pointer >= snakeX_two[0] && x_pointer <= (snakeX_two[0]+2))
								&& (y_pointer >= snakeY_two[0] && y_pointer <= (snakeY_two[0]+2));
				
				//Initial Snake's head
				if(!inital_head) begin
					snakeX[0] = 30;
					snakeY[0] = 30;
				end
				// snake 2
				if(!inital_head) begin
					snakeX_two[0] = 80;
					snakeY_two[0] = 80;
				end
				
				
				//update snake's position
				if(delayed_clk)begin
					for(bodycounter2 = 640; bodycounter2 > 0; bodycounter2 = bodycounter2 - 1)begin
							if(bodycounter2 <= size - 1)begin
								snakeX[bodycounter2] = snakeX[bodycounter2 - 1];
								snakeY[bodycounter2] = snakeY[bodycounter2 - 1];
							end	
					end
				//snake 2
					for(bodycounter2_two = 640; bodycounter2_two > 0; bodycounter2_two = bodycounter2_two - 1)begin
							if(bodycounter2_two <= size_two - 1)begin
								snakeX_two[bodycounter2_two] = snakeX_two[bodycounter2_two - 1];
								snakeY_two[bodycounter2_two] = snakeY_two[bodycounter2_two - 1];
							end	
					end	
						
					//update snake's direction
					case(direction)
						//UP
						5'b00010: if(!down)begin
											up = 1;
											down = 0;
											left = 0;
											right = 0;
									 end 
						//LEFT
						5'b00100:if(!right)begin
											up = 0;
											down = 0;
											left = 1;
											right = 0;
									 end 
						//DOWN
						5'b01000:if(!up)begin
											up = 0;
											down = 1;
											left = 0;
											right = 0;
									end 
						//RIGHT
						5'b10000: if(!left)begin
											up = 0;
											down = 0;
											left = 0;
											right = 1;
									end 
					endcase	
					//snake 2
					case(direction_two)
						//UP
						5'b00010: if(!down_two)begin
											up_two = 1;
											down_two = 0;
											left_two = 0;
											right_two = 0;
									 end 
						//LEFT
						5'b00100:if(!right_two)begin
											up_two = 0;
											down_two = 0;
											left_two = 1;
											right_two = 0;
									 end 
						//DOWN
						5'b01000:if(!up_two)begin
											up_two = 0;
											down_two = 1;
											left_two = 0;
											right_two = 0;
									end 
						//RIGHT
						5'b10000: if(!left_two)begin
											up_two = 0;
											down_two = 0;
											left_two = 0;
											right_two = 1;
									end 
					endcase
					
					if(up_two)
						 snakeY_two[0] <= (snakeY_two[0] - 1);
					else if(left_two)
						 snakeX_two[0] <= (snakeX_two[0] - 1);
					else if(down_two)
						 snakeY_two[0] <= (snakeY_two[0] + 1);
					else if(right_two)
						 snakeX_two[0] <= (snakeX_two[0] + 1);
					if(up)
						 snakeY[0] <= (snakeY[0] - 1);
					else if(left)
						 snakeX[0] <= (snakeX[0] - 1);
					else if(down)
						 snakeY[0] <= (snakeY[0] + 1);
					else if(right)
						 snakeX[0] <= (snakeX[0] + 1);
				end	
				
				//display border
				border = ~((x_pointer >= 3 && y_pointer >= 5) && (x_pointer <= 154 && y_pointer <= 115));
				
				//display apple
				edible1 = ((x_pointer >= edible1X && x_pointer <= (edible1X+2))
								&& (y_pointer >= edible1Y && y_pointer <= (edible1Y+2)));
				
				//check collision
					//if apple and snake head overlap
				if (snakeHead && edible1)begin
					edible1_collision <= 1;
					size = size+1;
				end
				if (snakeHead_two && edible1)begin
					edible1_collision <= 1;
					size_two = size_two + 1;
				end
				else begin
					edible1_collision <= 0;
				end
				//set new apple cooridinates
				if (edible1_collision)begin
					edible1X <= edible1_randX;
					edible1Y <= edible1_randY;
				end
				
					//if snake head and body overlap	
				if ((snakeHead && border)||(snakeHead_two && border)||(snakeHead && snakeHead_two)||(snakeHead && snakeBody_two)||(snakeHead_two && snakeBody))begin
					game_over <= 1;
				end
				
		end
	end
	
	assign R = edible1 || border || game_over;
	assign G = (snakeHead || snakeBody || snakeHead_two || snakeBody_two) && ~game_over;
	assign B = ~game_over;
   assign RGB = {R, G, B};
endmodule
	
	
module randomGrid(clk, rand_X, rand_Y);
	input clk;
	output reg [7:0] rand_X = 6;
	output reg [6:0] rand_Y = 6;
	
	// x and y will stop at random pixel.
	integer max_height = 108;
	integer max_width = 154;
	
	always@(posedge clk)
	begin
		if(rand_X === max_width)
			rand_X <= 6;
		else
			rand_X <= rand_X + 1;
	end

	always@(posedge clk)
	begin
		if(rand_X === max_width)
		begin
			if(rand_Y === max_height)
				rand_Y <= 6;
			else
				rand_Y <= rand_Y + 1;
		end
	end
endmodule	

	
module kbInput(CLOCK_50, KEY, direction);
	input CLOCK_50;
	input [3:0]KEY;
	output reg [4:0] direction;
	
	always@(*)
	begin
		if(~KEY[2])
			direction = 5'b00010;
		else if(~KEY[3])
			direction = 5'b00100;
		else if(~KEY[1])
			direction = 5'b01000;
		else if(~KEY[0])
			direction = 5'b10000;
		else direction <= direction;
	end	
endmodule

module swInput(CLOCK_50, SW, direction);
	input CLOCK_50;
	input [9:0]SW;
	output reg [4:0] direction;
	
	always@(*)
	begin
		if(SW[5])
			direction = 5'b00010;
		else if(SW[7])
			direction = 5'b00100;
		else if(SW[6])
			direction = 5'b01000;
		else if(SW[4])
			direction = 5'b10000;
		else direction <= direction;
	end	
endmodule




module refresher(clk, x_counter, y_counter);
	input clk;
	output reg [7:0] x_counter;
	output reg [6:0] y_counter;
	
	// set the maximum height and width of the game interface.
	// x and y will scan over every pixel.
	integer max_height = 120;
	integer max_width = 160;
	
	always@(posedge clk)
	begin
		if(x_counter === max_width)
			x_counter <= 0;
		else
			x_counter <= x_counter + 1;
	end

	always@(posedge clk)
	begin
		if(x_counter === max_width)
		begin
			if(y_counter === max_height)
				y_counter <= 0;
			else
			y_counter <= y_counter + 1;
		end
	end
endmodule

module frame_updater(clk, reset_n, frame_update);
	input clk;
	input reset_n;
	output frame_update;
	reg[19:0] delay;
	// Register for the delay counter
	
	always @(posedge clk)
	begin: delay_counter
		if (delay == 0)
			delay <= 20'd840000;
	   else
		begin
			    delay <= delay - 1'b1;
		end
	end
	
	assign frame_update = (delay == 20'd0)? 1: 0;
endmodule



module delay_counter(clk, reset_n, en_delay,delayed_clk);
	input clk;
	input reset_n;
	input en_delay;
	output delayed_clk;
	
	reg[3:0] delay;
	
	always @(posedge clk)begin
		if(delay == 2)
				delay <= 0;
		else if (en_delay)begin
			   delay <= delay + 1'b1;
		end	
	end
	
	assign delayed_clk = (delay == 2)? 1: 0;
endmodule
