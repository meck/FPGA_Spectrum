--------------------------------------------------------------------------------
-- File:             top.vhd
--
-- Company:          Meck AB
-- Engineer:         Johan Eklund
-- Created:          12/02/20
--
--
-- Target Devices:   Intel MAX10
-- Testbench file:   top.vht
-- Tool versions:    Quartus v18.1 and ModelSim
--
--
-- Description:      Top level for a FFT spectrum analyzer
--                   part of a TEIS project. Tested with a I2S2 Pmod module
--                   and DE-10 Lite card.
--
--
-- In Signals:
--                   clk_50   : clock 50 Mhz
--                   reset_n  : reset
--                   i2s_d_in : i2s data in
--
-- Out Signals:
--
--                  i2s_m_clk  : I2S2 master clock
--                  i2s_lr_clk : I2S2 word clock
--                  i2s_s_clk  : I2S2 bit clock
--
--                  vga_hs     : vga horizontal sync
--                  vga_vs     : vga vertical sync
--                  vga_r      : vga red data
--                  vga_g      : vga blue data
--                  vga_b      : vga green data
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.ALL;
    use IEEE.numeric_std.ALL;

entity top is
    port (
        clk_50  : in    std_logic;
        reset_n : in    std_logic;

        -- i2s module
        i2s_m_clk  : out   std_logic;
        i2s_lr_clk : out   std_logic;
        i2s_s_clk  : out   std_logic;
        i2s_d_in   : in    std_logic;

        -- Vga output
        vga_hs : out   std_logic;
        vga_vs : out   std_logic;
        vga_r  : out   std_logic_vector(3 downto 0);
        vga_g  : out   std_logic_vector(3 downto 0);
        vga_b  : out   std_logic_vector(3 downto 0)
    );
end entity top;

architecture behav of top is

    -- The number of fft bin, pow(2,x)
    constant c_n_bins       : natural := 10;
    -- Audio bit depth
    constant c_sample_width : natural := 16;

    -- Offset where in the output from the fft
    -- the signal to the vga is sliced i.e left shift
    constant c_out_gain : integer := 7;

    signal clk_main  : std_logic;
    signal clk_audio : std_logic;
    signal clk_vga   : std_logic;

    signal ws_audio : std_logic;
    signal sample   : std_logic_vector(c_sample_width - 1 downto 0);

    signal reset_n_t1,   reset_n_t2   : std_logic;
    signal reset_a_n_t1, reset_a_n_t2 : std_logic;
    signal reset_v_n_t1, reset_v_n_t2 : std_logic;

    signal framed_sample       : std_logic_vector(c_sample_width - 1 downto 0);
    signal framed_sample_valid : std_logic;
    signal framed_sample_idx   : std_logic_vector((c_n_bins - 1) downto 0);

    -- After preprocessing
    signal windowed_sample       : std_logic_vector(c_sample_width - 1 downto 0);
    signal windowed_sample_valid : std_logic;

    -- FFT output
    signal fft_out_real  : std_logic_vector(c_sample_width - 1 downto 0);
    signal fft_out_img   : std_logic_vector(c_sample_width - 1 downto 0);
    signal fft_out_idx   : std_logic_vector((c_n_bins - 1) downto 0);
    signal fft_out_valid : std_logic;

    -- Post processing output
    signal post_out        : std_logic_vector(c_sample_width - 1 downto 0);
    signal post_out_idx    : std_logic_vector((c_n_bins - 1) downto 0);
    signal post_out_valid  : std_logic;
    signal post_out_gained : std_logic_vector(8 downto 0);

begin

    i2s_lr_clk <= ws_audio;

    ------------------
    --  sync  --
    ------------------

    -- Reset sync for the main domain
    proc_sync_reset : process (clk_main, reset_n) is
    begin

        if (reset_n='0') then
            reset_n_t1 <= '0';
            reset_n_t2 <= '0';
        elsif (rising_edge(clk_main)) then
            reset_n_t1 <= '1';
            reset_n_t2 <= reset_n_t1;
        end if;

    end process proc_sync_reset;

    -- Reset sync for the audio domain
    proc_sync_reset_a : process (clk_audio, reset_n) is
    begin

        if (reset_n='0') then
            reset_a_n_t1 <= '0';
            reset_a_n_t2 <= '0';
        elsif (rising_edge(clk_audio)) then
            reset_a_n_t1 <= '1';
            reset_a_n_t2 <= reset_a_n_t1;
        end if;

    end process proc_sync_reset_a;

    -- Reset sync for the vga domain
    proc_sync_reset_v : process (clk_vga, reset_n) is
    begin

        if (reset_n='0') then
            reset_v_n_t1 <= '0';
            reset_v_n_t2 <= '0';
        elsif (rising_edge(clk_vga)) then
            reset_v_n_t1 <= '1';
            reset_v_n_t2 <= reset_v_n_t1;
        end if;

    end process proc_sync_reset_v;

    -----------
    --  PLL  --
    -----------

    pll : entity work.pll(syn)
        port map (
            inclk0 => clk_50,
            c0 => clk_main,
            c1 => clk_audio,
            c2 => clk_vga
        );

    i2s_m_clk <= clk_audio;

    -----------------------------------------------
    -- Since the free version of modelsim cant handle
    -- the simulation-version of the above pll without
    -- hitting a statment limit uncomment use this divider
    -- for simulation.
    -----------------------------------------------

   -- proc_pll_sim : process (clk_50, reset_n_t2) is

   --      variable c : natural := 0;

   --  begin

   --      if (reset_n_t2 = '0') then
   --          c := 0;
   --          clk_audio <= '0';
   --          clk_vga   <= '0';
   --      elsif (rising_edge(clk_50)) then
   --          if (c = 3) then
   --              c := 0;
   --              clk_vga   <= not clk_vga;
   --              clk_audio <= not clk_audio;
   --          elsif (c = 1) then
   --              clk_vga <= not clk_vga;
   --              c := c + 1;
   --          else
   --              c := c + 1;
   --          end if;
   --      end if;

   --  end process proc_pll_sim;

   --  i2s_m_clk <= clk_audio;
   --  clk_main  <= clk_50;

    --------------------
    --  i2s tranciver --
    --------------------

    -- For the audio clock
    -- 12.5 Mhz / (4 * 64) = 48828,125Hz Sample rate
    i2s : entity work.i2s_transceiver(logic)
        generic map (
            mclk_sclk_ratio => 4,
            sclk_ws_ratio => 64,
            d_width => c_sample_width
        )

        port map (
            reset_n => reset_a_n_t2,
            mclk => clk_audio,
            sclk => i2s_s_clk,
            ws => ws_audio,
            sd_rx => i2s_d_in,
            l_data_rx => sample,
            r_data_rx => open,
            -- Unused no transmit
            sd_tx => open,
            l_data_tx => (others => '0'),
            r_data_tx => (others => '0')
        );

    ---------------------
    --  Audio Sampler  --
    ---------------------

    sample_framer : entity work.sample_framer(behav)

        generic map (
            g_sample_width => c_sample_width,
            g_n_bins => c_n_bins
        )

        port map (
            clk => clk_main,
            reset_n => reset_n_t2,
            clk_audio => clk_audio,
            reset_a_n => reset_a_n_t2,
            sample_in_valid => not ws_audio,
            sample_in => sample,

            sample_out_valid => framed_sample_valid,
            sample_out => framed_sample,
            sample_out_idx => framed_sample_idx

        );

    fft_window : entity work.fft_window(behav)

        generic map (
            g_sample_width => c_sample_width,
            g_n_bins => c_n_bins
        )

        port map (

            clk => clk_main,
            reset_n => reset_n_t2,

            sample_in_valid => framed_sample_valid,
            sample_in => framed_sample,
            sample_in_idx => framed_sample_idx,

            sample_out_valid => windowed_sample_valid,
            sample_out => windowed_sample

        );

    -----------
    --  FFT  --
    -----------

        fft : entity work.fft(behav)

        generic map (
            g_sample_width => c_sample_width,
            g_n_bins => c_n_bins
        )

        port map (

            clk => clk_main,
            reset_n => reset_n_t2,

            sample_in_valid => windowed_sample_valid,
            sample_in => windowed_sample,
            result_real => fft_out_real,
            result_img => fft_out_img,
            result_idx => fft_out_idx,
            result_valid => fft_out_valid

        );

    ----------------
    --  FFT Post  --
    ----------------

       fft_post : entity work.fft_post(behav)

        generic map (
            g_sample_width => c_sample_width,
            g_n_bins => c_n_bins
        )

        port map (

            clk => clk_main,
            reset_n => reset_n_t2,

            input_real => fft_out_real,
            input_img => fft_out_img,
            input_idx => fft_out_idx,
            input_valid => fft_out_valid,

            output => post_out,
            output_idx => post_out_idx,
            output_valid => post_out_valid
        );

    -- "Gain" up the signal
    post_out_gained <= post_out(c_sample_width - 1 - c_out_gain downto c_sample_width - 9 - c_out_gain);

    -----------
    --  VGA  --
    -----------

    vga : entity work.vga(behav)

        port map (
            clk_main   => clk_main,
            clk_vga    => clk_vga,
            reset_n    => reset_v_n_t2,
            data       => post_out_gained,
            data_idx   => post_out_idx,
            data_valid => post_out_valid,

            vga_hs => vga_hs,
            vga_vs => vga_vs,
            vga_r  => vga_r,
            vga_g  => vga_g,
            vga_b  => vga_b

        );

end architecture behav;

