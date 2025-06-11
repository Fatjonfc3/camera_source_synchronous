create_clk -name PCLK -period 21 -waveform {0.0 9.45 } [get_ports PCLK] -- the pclk should be defined at the port of entity
set_input_delay -clock PCLK -max 8.0 [ get_ports d0 d1 d2 d3 d4 d5 d6 d7 vsync hsync ]
set_input_delay -clock PCLK -min 6.0 [ get_ports d0 d1 d2 d3 d4 d5 d6 d7 vsync hsync ]

--explanation of the values in the blog 
