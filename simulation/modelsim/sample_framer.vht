--------------------------------------------------------------------------------
-- File:             sample_framer.vht
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
-- Description:      Testbench for sample_framer.vhd, stimuli is a counter that
--                   corresponds to a length of a frame
--
--------------------------------------------------------------------------------


library IEEE;
    use IEEE.std_logic_1164.ALL;
    use IEEE.numeric_std.ALL;
    use IEEE.math_real.ALL;

entity sample_framer_vhd_tst is
end entity sample_framer_vhd_tst;

architecture sample_framer_arch of sample_framer_vhd_tst is

    -- constants
    constant c_sys_clk_period   : time := 20 ns;
    constant c_audio_clk_period : time := 41.666666 ns;

    constant c_width : natural := 16;
    constant c_bins  : natural := 8;

    -- Wait between audio samples input
    -- with i2s this is (2 * word read)
    constant c_time_beewen_samples : time := c_audio_clk_period * 2;

    -- signals
    signal clk              : std_logic;
    signal clk_audio        : std_logic;
    signal reset_a_n        : std_logic;
    signal reset_n          : std_logic;
    signal sample_in        : std_logic_vector((c_width - 1) downto 0);
    signal sample_in_valid  : std_logic := '0';
    signal sample_out       : std_logic_vector((c_width - 1) downto 0);
    signal sample_out_valid : std_logic;

    component sample_framer is
        generic (
            g_sample_width : natural;
            g_n_bins       : natural
        );
        port (
            clk              : in    std_logic;
            clk_audio        : in    std_logic;
            reset_a_n        : in    std_logic;
            reset_n          : in    std_logic;
            sample_in        : in    std_logic_vector((c_width -1) downto 0);
            sample_in_valid  : in    std_logic;
            sample_out       : out   std_logic_vector((c_width -1) downto 0);
            sample_out_valid : out   std_logic
        );
    end component;

begin

    i1 : sample_framer
        generic map (
            g_sample_width => c_width,
            g_n_bins       => c_bins
        )
        port map (

            -- list connections between master ports and signals
            clk              => clk,
            clk_audio        => clk_audio,
            reset_a_n        => reset_a_n,
            reset_n          => reset_n,
            sample_in        => sample_in,
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

    proc_clock_audio : process
    begin

        clk_audio <= '0';
        WAIT FOR c_audio_clk_period / 2;
        clk_audio <= '1';
        WAIT FOR c_audio_clk_period / 2;

    end process proc_clock_audio;

    proc_reset : process

    begin

        reset_a_n <= '0', '1' after c_audio_clk_period * 5;
        reset_n   <= '0', '1' after c_sys_clk_period * 5;

        wait;

    end process proc_reset;

    proc_load_data : process
        -- Use the length == num bins for testing
            constant c_low : integer := (-1) * ((2 ** c_bins) /2);
            constant c_high : integer := ((2 ** c_bins) /2) - 1;
            variable count  : integer := c_low;

    begin

            wait until (reset_a_n = '1' and rising_edge(clk_audio));

            if (count > c_high or reset_a_n = '0') then
                count := c_low;
            end if;

            sample_in       <= std_logic_vector(to_signed(count, sample_in'length));
            sample_in_valid <= '1';

            wait for c_audio_clk_period * 2;
            sample_in_valid <= '0';
            count := count + 1;

            wait for c_time_beewen_samples;

    end process proc_load_data;

end architecture sample_framer_arch;
