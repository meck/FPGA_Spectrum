
set_time_format -unit ns -decimal_places 3

create_clock -name {clk_50} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk_50}]

derive_pll_clocks -create_base_clocks -use_net_name

derive_clock_uncertainty

set_false_path -from [get_ports {reset_n}] 
set_false_path -to [get_ports {vga_*}]
set_false_path -from [get_ports {i2s_*}] 
set_false_path -to [get_ports {i2s_*}] 
