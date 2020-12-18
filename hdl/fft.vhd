--------------------------------------------------------------------------------
-- File:             fft.vhd
--
-- Company:          Meck AB
-- Engineer:         Johan Eklund
-- Created:          12/02/20
--
--
-- Target Devices:   Intel MAX10
-- Testbench file:   No file
-- Tool versions:    Quartus v18.1 and ModelSim
--
--
-- Description:      A wrapper for the generated FFT IP from zipCPU
--                   https://github.com/ZipCPU/dblclockfft
--                   any change in size and width requires the core
--                   to be regenerated
--
-- Generic:
--                  g_sample_width               : The word width of the samples
--                  g_n_bins                     : The numbers of samples in a bin/frame
--                                                 (pow 2^x, 10 => 1024)
--
-- In Signals:
--                   clk                         : clock
--                   reset_n                     : reset async active low
--                   clk_audio                   : clock audio domain
--                   reset_a_n                   : reset audio domain
--                   sample_in_valid             : input valid when high
--                   sample_in                   : input data
--
-- Out Signals:
--                   result_real                 : real data
--                   result_img                  : img data
--                   sample_idx                  : output data index
--                   result_valid                : output valid when high
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.ALL;
    use IEEE.numeric_std.ALL;

entity fft is
    generic (
        g_sample_width : natural := 4;
        g_n_bins : natural := 4
    );
    port (
        clk             : in    std_logic;
        reset_n         : in    std_logic;
        sample_in_valid : in    std_logic;
        sample_in       : in    std_logic_vector((g_sample_width -1) downto 0);

        result_real  : out   std_logic_vector((g_sample_width -1) downto 0);
        result_img   : out   std_logic_vector((g_sample_width -1) downto 0);
        result_idx   : out   std_logic_vector((g_n_bins -1) downto 0);
        result_valid : out   std_logic
    );
end entity fft;

architecture behav of fft is

    component fftmain is
        port (
            i_clk    : in    std_logic;
            i_reset  : in    std_logic;
            i_ce     : in    std_logic;
            i_sample : in    std_logic_vector((2*g_sample_width) - 1 downto 0);
            o_result : out   std_logic_vector((2*g_sample_width) - 1 downto 0);
            o_sync   : out   std_logic
        );
    end component;

    signal o_sync       : std_logic;
    signal o_result     : std_logic_vector((2*g_sample_width) - 1 downto 0);
    signal result_r_int : std_logic_vector(g_sample_width - 1 downto 0);
    signal result_i_int : std_logic_vector(g_sample_width - 1 downto 0);

    signal result_idx_int : natural range 0 to 2**g_n_bins - 1;

    signal sync_rst, sync_rst_t1 : std_logic;

begin

    -- The IP for the FFT uses active
    -- high sync reset, this should
    -- make it compatible as the result
    -- will be high for at least one
    -- cycle?
    proc_sync_reset : process (clk, reset_n) is
    begin

        if (reset_n = '0') then
            sync_rst    <= '1';
            sync_rst_t1 <= '1';
        elsif (rising_edge(clk)) then
            sync_rst    <= '0';
            sync_rst_t1 <= sync_rst;
        end if;

    end process proc_sync_reset;

    fft : fftmain
        port map (
            i_clk   => clk,
            i_reset => sync_rst_t1,
            i_ce    => sample_in_valid,
            -- Img part is always zero
            i_sample => sample_in & ((g_sample_width - 1) downto 0 => '0'),
            o_result => o_result,
            o_sync   => o_sync

        );

    -- Parts of the complex result
    result_r_int <= o_result(2*g_sample_width - 1 downto g_sample_width);
    result_i_int <= o_result(g_sample_width - 1 downto 0);

    -- Sync output with the counter
    proc_output : process (clk, reset_n) is
    begin

        if (reset_n = '0') then
            result_real <= (others => '0');
            result_img  <= (others => '0');
        elsif (rising_edge(clk)) then
            result_real <= result_r_int;
            result_img  <= result_i_int;
        end if;

    end process proc_output;

    -- A counter for the output index
    -- Waits for the first valid output
    -- then increments with the input
    -- as the fft outputs on every input cycle
    proc_idx_count : process (clk, reset_n) is

        variable first_out : boolean :=  false;

    begin

        if (reset_n = '0') then
            first_out := false;
            result_idx_int <= 0;
            result_valid   <= '0';
        elsif (rising_edge(clk)) then
            if (o_sync = '1') then
                first_out := true;
                result_valid   <= '1';
                result_idx_int <= 0;
            elsif (first_out and sample_in_valid = '1') then
                result_idx_int <= result_idx_int + 1;
                result_valid   <= '1';
            else
                result_idx_int <= result_idx_int;
                result_valid   <= '0';
            end if;
        end if;

    end process proc_idx_count;

    result_idx <= std_logic_vector(to_unsigned(result_idx_int, result_idx'length));

end architecture behav;

