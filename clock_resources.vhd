library IEEE;

use IEEE.std_logic_1164.all;

entity clock_distribution is
generic (
	DIST_TYPE : string := "REGION" ;
	)
port (
	clk_in : in std_logic;
	clk_out : out std_logic;
)
end entity clock_distribution;

signal feedback_loop : std_logic;
signal rst , locked , clkfb_buf : Std_logic;

architecture rtl of clock_distribution is

regional : if DIST_TYPE = "REGION" generate
begin
BUFR_inst : BUFR 
generic map (
BUFR_DIVIDE => "BYPASS",
SIM_DEVICE => "7SERIES"
)
port map (
O => clk_out,
I => clk_in, -- buffer input driven by IBUF , MMCM but also hrow or global 			buffer , CMT Backbone
clr => '0', -- async clear for the counter used to divide , but we are 	ussing divide so conencted to ground
CE => '1'
)

end generate BUFR_inst;
multi_region : if DIST_TYPE = "MRCC" generate --direction bufmr to a bufr never viceversa , to bufmr only a mrcc pin or gt clock
BUFMR_inst : BUFMR 
port map (
	O => clk_out,
	I => clk_in
);	
end generate multi_region;
signal cmt_clk : std_logic;
mmcm : if DIST_TYPE = "CMT" generate
BUFR_inst : BUFR 
generic map (
BUFR_DIVIDE => "BYPASS",
SIM_DEVICE => "7SERIES"
)
port map (
O => cmt_clk,
I => clk_in, -- buffer input driven by IBUF , MMCM but also hrow or global 			buffer , CMT Backbone
clr => '0', -- async clear for the counter used to divide , but we are 	ussing divide so conencted to ground
CE => '1'
)

s
MMCM_inst : MMCME2_BASE
generic map ( 
BANDWIDHT => "OPTIMIZED",
CLKFBOUT_MULT_F => 3.000,
CLKIN1_PERIOD => 21,
CLKOUT1_DIVIDE => 2,
CLKOUT0_DUTY _CYCLE => 0.45,
DIVCLK_DIVIDE       => 1 --also other features like phase offset etc , didn't add all of them since I want really use this one , just as an example
)
port map (
CLKOUT0 => clk_out,
CLKFBOUT => feedback_loop,
LOCKED => locked,
CLKIN1 => cmt_clk,
CLKFBIN => clkfb_buf -- it needs to be driven by buffer
);

  -- Feedback buffer for MMCM feedback path
    BUFR_fb : BUFR --use default generics
    port map (
      I => feedback_loop,
      O => clkfb_buf
    );

end generate mmcm ;

end architecture rtl;
