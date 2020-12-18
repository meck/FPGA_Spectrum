transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/hdl/fft_post.vhd}

vcom -93 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/simulation/modelsim/fft_post.vht}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L fiftyfivenm -L rtl_work -L work -voptargs="+acc"  fft_post_vhd_tst

add wave   sim:/fft_post_vhd_tst/clk
add wave   sim:/fft_post_vhd_tst/reset_n

add wave -divider "Input"
add wave sim:/fft_post_vhd_tst/input_valid
add wave -radix unsigned sim:/fft_post_vhd_tst/input_idx
add wave -radix signed sim:/fft_post_vhd_tst/input_img
add wave -radix signed sim:/fft_post_vhd_tst/input_real

add wave -divider "Internal"
add wave -radix sfixed /fft_post_vhd_tst/i1/proc_mult_add/p_r
add wave -radix sfixed /fft_post_vhd_tst/i1/proc_mult_add/p_i
add wave -radix sfixed /fft_post_vhd_tst/i1/proc_mult_add/sum

add wave -divider "Output"
add wave  sim:/fft_post_vhd_tst/output_valid
add wave  -radix unsigned sim:/fft_post_vhd_tst/output_idx
add wave  -radix unsigned sim:/fft_post_vhd_tst/output

view structure
view signals
run 1 us

wave zoom full
