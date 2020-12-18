transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -2008 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/hdl/fft_window.vhd}
vcom -2008 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/simulation/modelsim/fft_window.vht}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L fiftyfivenm -L rtl_work -L work -voptargs="+acc"  fft_window_vhd_tst

add wave sim:/fft_window_vhd_tst/clk
add wave -divider "Input"
add wave -format analog-step -height 74 -max 32837 -min -32837 -radix signed sim:/fft_window_vhd_tst/i1/sample_in
add wave sim:/fft_window_vhd_tst/sample_in_valid
add wave -radix unsigned sim:/fft_window_vhd_tst/sample_in_idx

add wave -divider "Output"
add wave -format analog-step -height 74 -max 32837 -min -32837 -radix signed sim:/fft_window_vhd_tst/i1/sample_out
add wave sim:/fft_window_vhd_tst/sample_out_valid

view structure
view signals
run 100 us

wave zoom full
