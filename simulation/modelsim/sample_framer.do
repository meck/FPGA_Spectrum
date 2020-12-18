transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/hdl/sample_framer_ram.vhd}
vcom -93 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/hdl/sample_framer.vhd}
vcom -93 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/simulation/modelsim/sample_framer.vht}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L fiftyfivenm -L rtl_work -L work -voptargs="+acc"  sample_framer_vhd_tst



add wave -divider "Input"
add wave sim:/sample_framer_vhd_tst/i1/clk_audio
add wave sim:/sample_framer_vhd_tst/i1/reset_a_n
add wave -format analog-step -height 74 -max 127 -min -128 -radix signed sim:/sample_framer_vhd_tst/i1/sample_in
add wave sim:/sample_framer_vhd_tst/i1/sample_in_valid
add wave sim:/sample_framer_vhd_tst/i1/sample_in_valid_t1
# add wave sim:/sample_framer_vhd_tst/i1/sample_in_valid_t1
add wave -divider "RAM W"
add wave sim:/sample_framer_vhd_tst/i1/samp_ram/we
add wave sim:/sample_framer_vhd_tst/i1/samp_ram/waddr
add wave sim:/sample_framer_vhd_tst/i1/samp_ram/data

add wave -divider "Output"
add wave sim:/sample_framer_vhd_tst/i1/clk
add wave  -format analog-step -height 74 -max 127 -min -128 -radix signed sim:/sample_framer_vhd_tst/i1/sample_out
add wave sim:/sample_framer_vhd_tst/i1/sample_out_valid
add wave sim:/sample_framer_vhd_tst/i1/sample_out_idx
add wave sim:/sample_framer_vhd_tst/i1/reset_n
add wave sim:/sample_framer_vhd_tst/i1/start_read_t2
add wave -divider "RAM R"
add wave sim:/sample_framer_vhd_tst/i1/samp_ram/raddr
add wave sim:/sample_framer_vhd_tst/i1/samp_ram/q

# add wave -position end  sim:/sample_framer_vhd_tst/i1/read_idx

view structure
view signals
run 1 ms
# run 100000 ns
# run 2000000 ps

wave zoom full
