--------------------------------------------------------------------------------
-- File:             fft_post.vht
--
-- Company:          Meck AB
-- Engineer:         Johan Eklund
-- Created:          12/02/20
--
--
-- Target Devices:   Intel MAX10
-- Tool versions:    Quartus v18.1 and ModelSim
--
--
-- Description:      Testbench for fft_post.vhd stimuli is min, max
--
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.ALL;
    use IEEE.numeric_std.ALL;

entity fft_post_vhd_tst is
end entity fft_post_vhd_tst;

architecture fft_post_arch of fft_post_vhd_tst is

    -- constants

    constant c_sys_clk_period : time := 20 ns;

    constant c_width : natural := 24;
    constant c_bins  : natural := 10;

    -- signals
    signal clk         : std_logic;
    signal input_idx   : std_logic_vector((c_bins - 1) downto 0);
    signal input_img   : std_logic_vector((c_width - 1) downto 0);
    signal input_real  : std_logic_vector((c_width - 1) downto 0);
    signal input_valid : std_logic;
    signal output      : std_logic_vector(c_width - 1 downto 0);

    signal output_idx   : std_logic_vector((c_bins -1) downto 0);
    signal output_valid : std_logic;
    signal reset_n      : std_logic;

begin

  i1 : entity work.fft_post
        generic map (
            g_sample_width => c_width,
            g_n_bins       => c_bins
        )
        port map (
            -- list connections between master ports and signals
            clk         => clk,
            input_idx   => input_idx,
            input_img   => input_img,
            input_real  => input_real,
            input_valid => input_valid,
            output      => output,
            reset_n     => reset_n,
            output_idx  => output_idx,
            output_valid => output_valid
        );

    -- clock setup
    proc_clock : process
    begin

        clk <= '0';
        WAIT FOR c_sys_clk_period / 2;
        clk <= '1';
        WAIT FOR c_sys_clk_period / 2;

    end process proc_clock;

    proc_reset : process
    begin

        reset_n <= '0', '1' after c_sys_clk_period * 5;
        wait;

    end process proc_reset;

    proc_test : process
    begin

        -- zero val
        wait for c_sys_clk_period * 10;
        input_idx   <= std_logic_vector(to_unsigned(1, input_idx'length));
        input_valid <= '1';
        input_real  <= (others => '0');
        input_img   <= (others => '0');

        -- Max val
        wait for c_sys_clk_period * 10;
        input_idx   <= std_logic_vector(to_unsigned(2, input_idx'length));
        input_valid <= '0';
        input_real  <= '0' & (input_real'length - 2 downto 0 => '1');
        input_img   <= '0' & (input_img'length - 2 downto 0 => '1');

        wait for c_sys_clk_period * 10;
        input_idx   <= std_logic_vector(to_unsigned(3, input_idx'length));
        input_valid <= '1';
        input_real  <= "111100100100000100001100";
        input_img   <= "110000011000011100100101";

        wait for c_sys_clk_period * 5;
        input_idx   <= std_logic_vector(to_unsigned(511, input_idx'length));
        wait for c_sys_clk_period * 2;
        input_idx   <= std_logic_vector(to_unsigned(512, input_idx'length));
        wait;

    end process proc_test;

end architecture fft_post_arch;
