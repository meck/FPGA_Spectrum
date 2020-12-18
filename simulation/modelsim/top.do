transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

# Copy the fft hex files to the running directory
set hexFiles [glob ../../fft-core/*.hex]
set destDir "./"
foreach file $hexFiles {
   file copy -force $file $destDir
}


vlog -vlog01compat -work work +incdir+C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/fft-core {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/fft-core/qtrstage.v}
vlog -vlog01compat -work work +incdir+C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/fft-core {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/fft-core/laststage.v}
vlog -vlog01compat -work work +incdir+C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/fft-core {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/fft-core/hwbfly.v}
vlog -vlog01compat -work work +incdir+C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/fft-core {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/fft-core/fftstage.v}
vlog -vlog01compat -work work +incdir+C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/fft-core {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/fft-core/fftmain.v}
vlog -vlog01compat -work work +incdir+C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/fft-core {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/fft-core/convround.v}
vlog -vlog01compat -work work +incdir+C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/fft-core {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/fft-core/bitreverse.v}
vlog -vlog01compat -work work +incdir+C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/db {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/db/pll_altpll.v}
vcom -2008 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/hdl/sample_framer_ram.vhd}
vcom -2008 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/hdl/vga_sync.vhd}
vcom -2008 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/hdl/fft.vhd}
vcom -2008 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/hdl/fft_window.vhd}
vcom -2008 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/hdl/fft_post.vhd}
vcom -2008 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/pll.vhd}
vcom -2008 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/hdl/i2s_transceiver.vhd}
vcom -2008 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/hdl/sample_framer.vhd}
vcom -2008 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/result_ram.vhd}
vcom -2008 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/hdl/vga.vhd}
vcom -2008 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/hdl/top.vhd}
vcom -2008 -work work {C:/Users/Johan/Utbildning/TEIS/code/vhdl2/eng/simulation/modelsim/top.vht}


vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L fiftyfivenm -L rtl_work -L work -voptargs="+acc"  top_vhd_tst

add wave sim:/top_vhd_tst/reset_n
add wave sim:/top_vhd_tst/clk_50
add wave sim:/top_vhd_tst/i1/clk_audio
add wave sim:/top_vhd_tst/i1/clk_vga

add wave -divider "I2S"
add wave sim:/top_vhd_tst/i2s_m_clk
add wave sim:/top_vhd_tst/i2s_s_clk
add wave sim:/top_vhd_tst/i2s_lr_clk
add wave sim:/top_vhd_tst/i2s_d_in

add wave -format analog-step -height 74 -max 2.14748e+009 -min -2.14748e+009 -radix signed sim:/top_vhd_tst/func_gen

add wave -divider "I2S Tranceiver Output"
add wave -format analog-step -height 74 -max 8.3886e+006 -min -8.3886e+006 -radix signed  sim:/top_vhd_tst/i1/sample
add wave sim:/top_vhd_tst/i1/ws_audio

add wave -divider "Framer Output"
add wave -format analog-step -height 74 -max 8.3886e+006 -min -8.3886e+006 -radix signed sim:/top_vhd_tst/i1/framed_sample
add wave sim:/top_vhd_tst/i1/framed_sample_valid
add wave -radix unsigned sim:/top_vhd_tst/i1/framed_sample_idx

add wave -divider "Windower Output"
add wave -format analog-step -height 74 -max 8.3886e+006 -min -8.3886e+006 -radix signed sim:/top_vhd_tst/i1/windowed_sample
add wave sim:/top_vhd_tst/i1/windowed_sample_valid

add wave -divider "FFT"
add wave -format analog-step -height 74 -max 8.3886e+006 -min -8.3886e+006 -radix signed sim:/top_vhd_tst/i1/fft/result_real
add wave -format analog-step -height 74 -max 8.3886e+006 -min -8.3886e+006 -radix signed sim:/top_vhd_tst/i1/fft/result_img
add wave -radix unsigned sim:/top_vhd_tst/i1/fft/result_idx
add wave sim:/top_vhd_tst/i1/fft/result_valid

add wave -divider "FFT Post"
add wave sim:/top_vhd_tst/i1/fft_post/output_valid
add wave -radix unsigned sim:/top_vhd_tst/i1/fft_post/output_idx
add wave -format analog-step -height 74 -max 8.3886e+006 -min -8.3886e+006 -radix signed sim:/top_vhd_tst/i1/fft_post/output

add wave -divider "Result RAM"
add wave sim:/top_vhd_tst/i1/vga/result_ram/wren
add wave -radix unsigned sim:/top_vhd_tst/i1/vga/result_ram/wraddress
add wave sim:/top_vhd_tst/i1/vga/result_ram/data
add wave sim:/top_vhd_tst/i1/vga/result_ram/q
add wave sim:/top_vhd_tst/i1/vga/result_ram/rdaddress

add wave -divider "Framebuffer RAM"
add wave sim:/top_vhd_tst/i1/vga/frambuff_ram/wren
add wave -radix unsigned sim:/top_vhd_tst/i1/vga/frambuff_ram/wraddress
add wave -radix unsigned sim:/top_vhd_tst/i1/vga/frambuff_ram/data
add wave -radix unsigned sim:/top_vhd_tst/i1/vga/frambuff_ram/q
add wave -radix unsigned sim:/top_vhd_tst/i1/vga/frambuff_ram/rdaddress

add wave -divider "VGA Sync"
add wave sim:/top_vhd_tst/i1/vga/vga/vga_blank_n
add wave sim:/top_vhd_tst/i1/vga/vga/vga_frame_blank_n
add wave -radix ufixed sim:/top_vhd_tst/i1/vga/vga/c_v_scale_factor
add wave -radix ufixed sim:/top_vhd_tst/i1/vga/vga/v_unscaled
add wave -radix ufixed sim:/top_vhd_tst/i1/vga/vga/v_scaled
add wave sim:/top_vhd_tst/i1/vga/vga/vga_r
add wave sim:/top_vhd_tst/i1/vga/vga/vga_b
add wave sim:/top_vhd_tst/i1/vga/vga/vga_g
add wave sim:/top_vhd_tst/i1/vga/vga/vga_hs
add wave sim:/top_vhd_tst/i1/vga/vga/vga_vs

view structure
view signals
run 150 ms

wave zoom full

