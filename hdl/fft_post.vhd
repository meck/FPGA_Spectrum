--------------------------------------------------------------------------------
-- File:             fft_post.vhd
--
-- Company:          Meck AB
-- Engineer:         Johan Eklund
-- Created:          12/02/20
--
--
-- Target Devices:   Intel MAX10
-- Testbench file:   fft_post.vht
-- Tool versions:    Quartus v18.1 and ModelSim
--
--
-- Description:      Calculate power of a complex input and normalize
--                   according to a
--
-- Generic:
--                  g_sample_width : The word width of the samples
--                  g_n_bins       : The numbers of samples in a bin/frame
--                                   (pow 2^x, 10 => 1024)
--
-- In Signals:
--                   clk         : clock input
--                   reset_n     : reset async active low
--                   input_real  : input real part
--                   input_img   : input img part
--                   input_idx   : input data index
--                   input_valid : input valid when high
--
-- Out Signals:
--                   output       : output
--                   output_idx   : output idx
--                   output_valid : output valid when high
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.ALL;
    use IEEE.numeric_std.ALL;
    use ieee.math_real.all;
    use ieee.fixed_pkg.all;

entity fft_post is
    generic (
        g_sample_width : natural := 24;
        g_n_bins : natural := 10
    );
    port (
        clk     : in    std_logic;
        reset_n : in    std_logic;

        -- From the FFT
        input_real  : in    std_logic_vector((g_sample_width -1) downto 0);
        input_img   : in    std_logic_vector((g_sample_width -1) downto 0);
        input_idx   : in    std_logic_vector((g_n_bins -1) downto 0);
        input_valid : in    std_logic;

        -- result
        output       : out   std_logic_vector(g_sample_width - 1 downto 0);
        output_idx   : out   std_logic_vector((g_n_bins -1) downto 0);
        output_valid : out   std_logic
    );
end entity fft_post;

architecture behav of fft_post is

    subtype val_t is sfixed(0 downto - g_sample_width + 1);
    subtype d_val_t is sfixed(0 downto - 2*g_sample_width + 1);

    -- Scale factor includes the number of bins in the fft and the
    -- gain factor for the window, hann ~= 0.5
    constant c_scale_fac_real : real := 1.0 / (2.0 ** g_n_bins) ** 2 * 2.0 ** 2 / 0.5 ** 2;
    constant c_scale_fac      : val_t := to_sfixed(c_scale_fac_real, 0, - g_sample_width + 1);

begin

    -- Calculate the power (re^2 + im^2)
    -- Then normalize according to window gain

    proc_mult_add : process (clk, reset_n) is

        variable p_r, p_i : d_val_t;
        variable sum      : val_t;

    begin

        if (reset_n = '0') then
            p_r := (others => '0');
            p_i := (others => '0');
            output <= (others => '0');
        elsif (rising_edge(clk)) then
            p_r := to_sfixed(input_real, c_scale_fac) * to_sfixed(input_real, c_scale_fac);
            p_i := to_sfixed(input_img, c_scale_fac) * to_sfixed(input_img, c_scale_fac);

            sum := resize(p_r + p_i, sum);

            output <= to_slv(sum);
        end if;

    end process proc_mult_add;

    -- register index and
    -- valid outputs
    proc_idx_v_reg : process (clk, reset_n) is
    begin

        if (reset_n = '0') then
            output_idx   <= (others => '0');
            output_valid <= '0';
        elsif (rising_edge(clk)) then
            output_idx <= input_idx;
            -- Only use the first half of the fft output
            if (input_valid = '1' and unsigned(input_idx) < (2 ** g_n_bins / 2)) then
                output_valid <= '1';
            else
                output_valid <= '0';
            end if;
        end if;

    end process proc_idx_v_reg;

end architecture behav;

