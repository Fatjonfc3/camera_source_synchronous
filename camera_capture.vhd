library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity camera_capture is
generic (
	RES_WIDTH : integer := 480;
	RES_HEIGHT : integer := 640;
	)
port (
	clk , d0 ,d1 ,d2 ,d3 ,d4 ,d5 ,d6 ,d7 : in std_logic;
	vsync , hsync : in std_logic;
	rst : in std_logic;
	pixel_data : out std_logic_vector ( 15 downto 0); -- supposing a rgb555 pixel format 16 bit so in 2 pclk rising edge
	valid_pixel , last_pixel , last_line : out std_logic
);
end entity camera_capture;
--=======Counters to keep track at which pixel we are , is it the last pixel ,  same for the counter
signal cnt_pixel : unsigned (8 downto 0 ) := 0 ;
signal cnt_line : unsigned ( 9 downto 0 ) := 0;
signal cnt_frame : unsigned (4 downto 0 ) := 0 ; -- just to be sure for the 30 fps , like a helper not necessary
--=======Async Assertion Synchronous Deassertion reset
signal rst_sync1 , rst_sync2 : std_logic := '0';
--=======SIMPLE FSM , we could also not use fsm
type state is ( IDLE , CAPTURE ) := IDLE;

--======Output registers
signal pixel_data_reg : std_logic_Vector ( 15 downto 0 ) := ( others => '0');
signal valid_pixel_reg , last_pixel_reg , last_line_reg : std_logic := '0';
signal curr_state : IDLE ;
--====== Just a signal to write to differentiate the first and second byte
signal byte_order : std_logic := '0'; -- 0 for the first byte , 1 for the next byte , it will be just a clock divided tbh
--===
signal vsync_reg : std_logic:= '0';
architecture rtl of camera_capture is
begin
rst_sync: process ( clk , rst)
begin
	if rst ='1' then
		rst_sync1 <= '1';
		rst_sync2 <= '1';
	elseif rising_edge ( clk ) then
		rst_sync1 <= '0';
		rst_sync2 <= rst_sync1;
	end if;

end process; 
edge_Detection_prepare_vsync : process ( clk )
	if rising_edge ( clk ) then
		vsync_reg <= vsync;
	end if;
end process edge_detection_prepare_vsync;

FSM : process ( clk  , rst_sync2)
begin
	if rst_sync2 = '1' then
		curr_State <= IDLE;
		cnt_pixel <= 0;
		cnt_line <= 0;	
		valid_pixel_reg <= '0';  
		last_pixel_reg <='0'; 
		last_line_reg  <= '0';
		
	elseif rising_edge ( clk ) then
		
		
		valid_pixel_reg <= '0'; 
		last_pixel_reg <='0'; 
		last_line_reg  <= '0'
		case curr_State is
			when IDLE =>
				cnt_pixel <= 0 ;
				curr_state <= IDLE;
				cnt_line <= 0;				
				if vsync_reg = '0' and vsync = '1' then
					curr_state <= process; --we don't sample the input signals, so we don't store into reg, just 								        -- so we could risk metastability , but since the vsync , href are 									-- synced with the pclk , we say we are fine , need to define input	
								-- output timing constraints
					
				end if;
			when PROCESS =>
				if vsync_reg = '0' and vsync = '1' then
					cnt_frame <= cnt_frame + 1;
					if last_line_reg <= '1' then
						cnt_line <= 0 ;
					end if;
					--cnt_pixel <= 0;
					--cnt_line <= 0;
				
				elseif hsync = '1' then
					byte_order <= not byte_order;
					if byte_order = '0' then
						pixel_data_reg(7 downto 0) <= (d7 & d6 & d5 & d4 & d3 & d2 & d1 & d0);
					else
						pixel_data_reg(15 downto 8) <= (d7 & d6 & d5 & d4 & d3 & d2 & d1 & d0);
						valid_pixel_reg <= '1'; 
						cnt_pixel <= cnt_pixel + 1;
						if cnt_pixel = RES_WIDTH - 1 then
							cnt_pixel <= 0;
							cnt_line <= cnt_line + 1;
							last_pixel_reg <= '1';
							
						endif;
					endif;
					if cnt_line = RES_HEIGHT - 1 then
						last_line_reg <= '1';
					end if;
				end if;
						
end process FSM;

valid_pixel <= valid_pixel_reg ;  
last_pixel <= last_pixel_reg ; 
last_line <=	last_line_reg;
pixel_data <= pixel_data_reg ; 

end architecture camera_capture;
