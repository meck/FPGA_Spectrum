--------------------------------------------------------------------------------
-- File:             fft_window.vht
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
-- Description:      Testbench for fft_window.vhd, stimuli is alternating
--                   min/max values.
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.ALL;
    use IEEE.numeric_std.ALL;

entity fft_window_vhd_tst is
end entity fft_window_vhd_tst;

architecture fft_window_arch of fft_window_vhd_tst is

    -- constants

    constant c_sys_clk_period : time := 20 ns;

    constant c_width : natural := 16;
    constant c_bins  : natural := 8;

    -- signals
    signal clk              : std_logic;
    signal reset_n          : std_logic;
    signal sample_in        : std_logic_vector((c_width - 1) downto 0);
    signal sample_in_idx    : std_logic_vector((c_bins - 1) downto 0);
    signal sample_in_valid  : std_logic;
    signal sample_out       : std_logic_vector ((c_width - 1) downto 0);
    signal sample_out_valid : std_logic;

    component fft_window is
        generic (
            g_sample_width : natural;
            g_n_bins       : natural
        );
        port (
            clk              : in    std_logic;
            reset_n          : in    std_logic;
            sample_in        : in    std_logic_vector((c_width - 1) downto 0);
            sample_in_idx    : in    std_logic_vector((c_bins - 1) downto 0);
            sample_in_valid  : in    std_logic;
            sample_out       : out   std_logic_vector ((c_width - 1) downto 0);
            sample_out_valid : out   std_logic
        );
    end component;

begin

    i1 : fft_window
        generic map (
            g_sample_width => c_width,
            g_n_bins       => c_bins
        )
        port map (
            -- list connections between master ports and signals
            clk              => clk,
            reset_n          => reset_n,
            sample_in        => sample_in,
            sample_in_idx    => sample_in_idx,
            sample_in_valid  => sample_in_valid,
            sample_out       => sample_out,
            sample_out_valid => sample_out_valid
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

        variable idx : natural := 0;

    begin

        wait until (reset_n = '1' and rising_edge(clk));

        if (idx >= (2**c_bins - 1)) then
            wait for c_sys_clk_period * 1000;
            idx := 0;
        end if;

        sample_in_valid <= '1';

        -- Alternate beteewn min max value
        if (idx mod 2 = 0) then
            sample_in <= '0' & (c_width - 2 downto 0 => '1');
        else
            sample_in <= '1' & (c_width - 2 downto 0 => '0');
        end if;

        sample_in_idx <= std_logic_vector(to_unsigned(idx, sample_in_idx'length));

        wait for c_sys_clk_period * 2;
        sample_in_valid <= '0';

        wait for c_sys_clk_period * 4;

        idx := idx + 1;

    end process proc_test;

end architecture fft_window_arch;
