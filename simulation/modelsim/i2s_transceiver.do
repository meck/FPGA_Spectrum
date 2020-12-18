transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/hdl/i2s_transceiver.vhd}
vcom -93 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/simulation/modelsim/i2s_transceiver.vht}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L fiftyfivenm -L rtl_work -L work -voptargs="+acc"  i2s_transceiver_vhd_tst

add wave sim:/i2s_transceiver_vhd_tst/reset_n

add wave sim:/i2s_transceiver_vhd_tst/mclk
add wave sim:/i2s_transceiver_vhd_tst/sclk
add wave sim:/i2s_transceiver_vhd_tst/ws
add wave sim:/i2s_transceiver_vhd_tst/sd_rx

add wave -format analog-step -height 74 -max 1.07374e+009 -min -1.07374e+009 -radix signed sim:/i2s_transceiver_vhd_tst/func_gen

add wave -divider "Output"
add wave -format analog-step -height 74 -max 32767 -min -32768 -radix signed sim:/i2s_transceiver_vhd_tst/l_data_rx


view structure
view signals
run 10 ms

wave zoom full
