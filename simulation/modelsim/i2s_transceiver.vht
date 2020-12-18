--------------------------------------------------------------------------------
-- File:             i2s_transceiver.vht
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
-- Description:      I2S2 Pmod Module testbench, testbench for the manufacturer supplied
--                   component.
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.ALL;
    use IEEE.numeric_std.ALL;
    use IEEE.math_real.ALL;

library modelsim_lib;
    use modelsim_lib.util.all;

entity i2s_transceiver_vhd_tst is
end entity i2s_transceiver_vhd_tst;

architecture i2s_transceiver_arch of i2s_transceiver_vhd_tst is

    -- constants
    constant c_clk_period    : time := 41.666666 ns;
    constant c_width         : natural := 16;
    constant c_sclk_ws_ratio : natural := 64;

    -- Period time of a the output in 'ws' samples
    -- constant c_period    : Natural := 46875 / 1000 ;
    constant c_period_time : time := 1 ms;

    -- signals
    signal l_data_rx : std_logic_vector((c_width -1) downto 0);
    signal l_data_tx : std_logic_vector((c_width -1) downto 0);
    signal mclk      : std_logic;
    signal r_data_rx : std_logic_vector((c_width -1) downto 0);
    signal r_data_tx : std_logic_vector((c_width -1) downto 0);
    signal reset_n   : std_logic;
    signal sclk      : std_logic;
    signal sd_rx     : std_logic;
    signal sd_tx     : std_logic;
    signal ws        : std_logic;

    -- Generated sine
    signal func_gen     : std_logic_vector(((c_sclk_ws_ratio /2) - 2) downto 0);
    signal sample       : std_logic_vector((c_sclk_ws_ratio /2) - 1 downto 0);
    signal sample_count : natural := 0;

begin

  i1 : entity  work.i2s_transceiver
        generic map (
            mclk_sclk_ratio => 4,
            sclk_ws_ratio   => c_sclk_ws_ratio,
            d_width         => c_width
        )
        port map (
            -- list connections between master ports and signals
            l_data_rx => l_data_rx,
            l_data_tx => l_data_tx,
            mclk      => mclk,
            r_data_rx => r_data_rx,
            r_data_tx => r_data_tx,
            reset_n   => reset_n,
            sclk      => sclk,
            sd_rx     => sd_rx,
            sd_tx     => sd_tx,
            ws        => ws
        );

    -- clock setup
    proc_clock : process
    begin

        mclk <= '0';
        WAIT FOR c_clk_period / 2;
        mclk <= '1';
        WAIT FOR c_clk_period / 2;

    end process proc_clock;

    proc_reset : process
    begin

        reset_n <= '0', '1' after c_clk_period * 5;
        wait;

    end process proc_reset;

    proc_sig_gen : process (mclk) is

        variable sin_delta_time : real;
        variable output         : real;

    begin

        if (rising_edge (mclk)) then
            sin_delta_time := (to_real(now) mod to_real(c_period_time));
            -- Sine generator
            output := sin(2.0 * math_pi * sin_delta_time / to_real(c_period_time));
            -- Scaling
            output := output * (2.0 ** real(func_gen'length)) * 0.5;
            func_gen <= std_logic_vector(to_signed(integer(trunc(output)), func_gen'length));
        end if;

    end process proc_sig_gen;

    -- Set 'sample' to 'func_gen' on Left word
    -- with a leading 0 since i2s data lags one cyckle
    output : process (ws, reset_n) is
    begin

        if (reset_n = '0') then
        elsif (rising_edge(ws)) then
            sample <= (others => '0');
        elsif (falling_edge(ws)) then
            sample <= '0' & func_gen;
        end if;

    end process output;

    -- Counter for the number of cycles
    -- in the current word
    proc_sample_gen : process (sclk, ws, reset_n) is
    begin

        if (reset_n = '0') then
            sample_count <= 0;
        elsif (rising_edge(ws) or falling_edge(ws)) then
            sample_count <= 0;
        elsif (falling_edge(sclk)) then
            sample_count <= sample_count + 1;
        end if;

    end process proc_sample_gen;

    sd_rx <= sample((c_sclk_ws_ratio/2 - 1) - sample_count);

end architecture i2s_transceiver_arch;
