--------------------------------------------------------------------------------
-- File:             top.vht
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
-- Description:      Test bench for FFT spectrum analyzer
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.ALL;
    use IEEE.numeric_std.ALL;
    use IEEE.math_real.ALL;

library modelsim_lib;
    use modelsim_lib.util.all;

entity top_vhd_tst is
end entity top_vhd_tst;

architecture top_arch of top_vhd_tst is

    -- constants
    constant c_clk_period    : time := 20 ns;
    constant c_sclk_ws_ratio : natural := 64;
    -- Period time of input.
    constant c_period_time : time := 1 ms;

    -- signals
    signal clk_50     : std_logic;
    signal i2s_d_in   : std_logic;
    signal i2s_lr_clk : std_logic;
    signal i2s_m_clk  : std_logic;
    signal i2s_s_clk  : std_logic;
    signal reset_n    : std_logic;

    signal func_gen     : std_logic_vector(((c_sclk_ws_ratio /2) - 1) downto 0);
    signal sample       : std_logic_vector((c_sclk_ws_ratio /2) - 1 downto 0);
    signal sample_count : natural;

    component top is
        port (
            clk_50     : in    std_logic;
            i2s_d_in   : in    std_logic;
            i2s_lr_clk : out   std_logic;
            i2s_m_clk  : out   std_logic;
            i2s_s_clk  : out   std_logic;
            reset_n    : in    std_logic
        );
    end component;

begin

    i1 : top
        port map (
            -- list connections between master ports and signals
            clk_50     => clk_50,
            i2s_d_in   => i2s_d_in,
            i2s_lr_clk => i2s_lr_clk,
            i2s_m_clk  => i2s_m_clk,
            i2s_s_clk  => i2s_s_clk,
            reset_n    => reset_n
        );

    -- clock setup
    proc_clock : process
    begin

        clk_50 <= '0';
        WAIT FOR c_clk_period / 2;
        clk_50 <= '1';
        WAIT FOR c_clk_period / 2;

    end process proc_clock;

    proc_reset : process
    begin

        reset_n <= '0', '1' after c_clk_period * 5;
        wait;

    end process proc_reset;

    proc_sig_gen : process (i2s_m_clk) is

        variable delta_time : real;
        variable output     : real;

    begin

        if (rising_edge (i2s_m_clk)) then
            delta_time := (to_real(now) mod to_real(c_period_time));

            -- No output
            -- output := 0.0;

            -- Sine generator
            output := sin(2.0 * math_pi * delta_time / to_real(c_period_time));

            -- Square generator
            -- output := 0.99 when delta_time < 0.5 * to_real(c_period_time) else (- 0.99);

            -- Scaling
            output := output * (2.0 ** real(func_gen'length)) * 0.5;
            func_gen <= std_logic_vector(to_signed(integer(trunc(output)), func_gen'length));
        end if;

    end process proc_sig_gen;

    -- Set 'sample' to 'func_gen' on Left word
    -- with a leading 0 since i2s data lags one cyckle
    proc_output : process (i2s_lr_clk, reset_n) is
    begin

        if (reset_n = '0') then
            sample <= (others => '0');
        elsif (rising_edge(i2s_lr_clk)) then
            sample <= (others => '0');
        elsif (falling_edge(i2s_lr_clk)) then
            sample <= func_gen;
        end if;

    end process proc_output;

    -- Counter for the number of cycles
    -- in the current word
    proc_sample_gen : process (i2s_s_clk, i2s_lr_clk, reset_n) is
    begin

        if (reset_n = '0') then
            sample_count <= 0;
            i2s_d_in     <= '0';
        elsif (rising_edge(i2s_lr_clk) or falling_edge(i2s_lr_clk)) then
            sample_count <= 0;
            i2s_d_in     <= '0';
        elsif (falling_edge(i2s_s_clk)) then
            sample_count <= sample_count + 1;
            i2s_d_in     <= sample((c_sclk_ws_ratio/2 - 1) - sample_count);
        end if;

    end process proc_sample_gen;

end architecture top_arch;
