--------------------------------------------------------------------------------
-- File:             fft_window.vhd
--
-- Company:          Meck AB
-- Engineer:         Johan Eklund
-- Created:          12/02/20
--
--
-- Target Devices:   Intel MAX10
-- Testbench file:   fft_window.vht
-- Tool versions:    Quartus v18.1 and ModelSim
--
--
-- Description:      Window a signal using a repeating Hann window, coefficients
--                   are calculated at synthesizes time.
--
--
-- Generic:
--                  g_sample_width               : The word width of the samples
--                  g_n_bins                     : The numbers of samples in a bin/frame
--                                                 (pow 2^x, 10 => 1024)
--
-- In Signals:
--                   clk                         : clock output domain
--                   reset_n                     : reset output domain
--                   sample_in_idx               : input data index
--                   sample_in_valid             : input valid when high
--                   sample_in                   : input data
--
-- Out Signals:
--
--                   sample_out_valid            : output valid when high
--                   sample_out                  : output data
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.ALL;
    use IEEE.numeric_std.ALL;
    use ieee.math_real.all;
    use ieee.fixed_pkg.all;

entity fft_window is
    generic (
        g_sample_width : natural := 4;
        -- pow(2,x)
        g_n_bins : natural := 4
    );
    port (
        clk     : in    std_logic;
        reset_n : in    std_logic;

        sample_in_valid : in    std_logic;
        sample_in       : in    std_logic_vector((g_sample_width -1) downto 0);
        sample_in_idx   : in    std_logic_vector((g_n_bins - 1) downto 0);

        sample_out_valid : out   std_logic;
        sample_out       : out   std_logic_vector((g_sample_width -1) downto 0)
    );
end entity fft_window;

architecture behav of fft_window is

    -- ROM with cofs
    subtype samp_t is sfixed(0 downto - g_sample_width + 1);

    type t_rom is array(2 ** g_n_bins - 1 downto 0) of samp_t;

    -- Creates the window coefficents at compiletime
    -- using straight VHDL `real` lib

    function init_cofs
      return t_rom is
        variable tmp : t_rom := (others => (others => '0'));
        variable c   : real;
    begin
        for addr_pos in 0 to 2**g_n_bins - 1 loop

            -- Window function
            -- Hann window
            c := 0.5 * (1.0 - cos(2.0*math_pi*real(addr_pos)/real(2**g_n_bins)));

            -- Square Window
            -- c := 1.0;

            tmp(addr_pos) := to_sfixed(c, 0, - g_sample_width + 1);

        end loop;
        return tmp;
    end init_cofs;

    constant c_cof_rom : t_rom := init_cofs;

    signal result             : sfixed(1 downto - 2*g_sample_width + 2);
    signal sample_in_valid_t1 : std_logic;

begin

    proc_win : process (clk, reset_n) is

        variable scale_fac : samp_t;

    begin

        if (reset_n = '0') then
            sample_out         <= (others => '0');
            sample_out_valid   <= '0';
            sample_in_valid_t1 <= '0';
            result             <= (others => '0');
        elsif (rising_edge(clk)) then
            scale_fac := c_cof_rom(to_integer(unsigned(sample_in_idx)));
            -- TODO Investigate output rounding in `resize`
            -- a full scale number rounds down:
            -- currently ie: 323767 * 1.0 = 32766
            --
            -- The result need to be registered
            -- for correct timing.
            result     <= to_sfixed(sample_in, scale_fac) * scale_fac;
            sample_out <= to_slv(resize(result, scale_fac));

            sample_in_valid_t1 <= sample_in_valid;
            sample_out_valid   <= sample_in_valid_t1;
        end if;

    end process proc_win;

end architecture behav;

