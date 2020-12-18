--------------------------------------------------------------------------------
-- File:             sample_framer.vhd
--
-- Company:          Meck AB
-- Engineer:         Johan Eklund
-- Created:          12/02/20
--
--
-- Target Devices:   Intel MAX10
-- Testbench file:   sample_framer.vht
-- Tool versions:    Quartus v18.1 and ModelSim
--
--
-- Description:      Take input samples and buffer them in a ram and output into
--                   another domain when full, also output frames with a 50 percent
--                   overlap:
--
--                   [--Frame 1--][--Frame 2--][--Frame 3--]
--                   [   Out 1   ][   Out 3   ][   Out 5   ]
--                          [   Out 2   ][   Out 4   ][   Out 6   ]
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
--                   clk_audio                   : clock audio domain
--                   reset_a_n                   : reset audio domain
--                   sample_in_valid             : input valid when high
--                   sample_in                   : input data
--
-- Out Signals:
--
--                   sample_out_valid            : output valid when high
--                   sample_out                  : output data
--                   sample_out_idx              : output data index
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.ALL;
    use IEEE.numeric_std.ALL;

entity sample_framer is
    generic (
        g_sample_width : natural := 4;
        g_n_bins       : natural := 4
    );
    port (
        -- main clock and  reset
        clk     : in    std_logic;
        reset_n : in    std_logic;

        -- audio clock and reset
        clk_audio : in    std_logic;
        reset_a_n : in    std_logic;

        sample_in_valid : in    std_logic;
        sample_in       : in    std_logic_vector(g_sample_width - 1 downto 0);

        sample_out_valid : out   std_logic;
        sample_out       : out   std_logic_vector((g_sample_width -1) downto 0);
        sample_out_idx   : out   std_logic_vector((g_n_bins - 1) downto 0)
    );
end entity sample_framer;

architecture behav of sample_framer is

    -- The ram is twice the size to fit overlapping samples
    -- its used as a circular buffer
    constant c_ram_addr_size : natural := 2 ** (g_n_bins + 1);

    -- These define the start and endpoints in memory of the overlapping
    -- windows, the coresponing startpoint is `g_n_bins` behind
    constant c_start_idx_0 : natural := 0; -- OK
    constant c_start_idx_1 : natural := (2 ** g_n_bins / 2);
    constant c_start_idx_2 : natural := (2 ** g_n_bins);
    constant c_start_idx_3 : natural := (2 ** g_n_bins) + (2 ** g_n_bins / 2);
    constant c_end_idx_0   : natural := c_start_idx_2 - 1;
    constant c_end_idx_1   : natural := c_start_idx_3 - 1;
    constant c_end_idx_2   : natural := 2**g_n_bins * 2 - 1;
    constant c_end_idx_3   : natural := c_start_idx_1 - 1;

    -- A type for to indicate to the ram reading process
    -- when and where to start in the ram

    type t_starting_idx is (no_start, start_idx0, start_idx1, start_idx2, start_idx3);

    signal start_read    : t_starting_idx;
    signal start_read_t1 : t_starting_idx;
    signal start_read_t2 : t_starting_idx;
    signal start_read_t3 : t_starting_idx;

    -- For the reading FSM
    signal read_state : t_starting_idx;
    signal read_idx   : natural range 0 to c_ram_addr_size - 1;

    -- For tracking the output bin index
    signal out_idx, out_idx_t1 : natural range 0 to 2 ** g_n_bins - 1;

    signal sample_in_valid_t1 : std_logic;

    -- RAM
    -- Need a default to silence quartus warning
    signal ram_waddr : natural range 0 to c_ram_addr_size - 1 := c_ram_addr_size - 1;
    signal ram_data  : std_logic_vector((g_sample_width - 1) downto 0);
    signal ram_we    : std_logic;
    signal ram_raddr : natural range 0 to c_ram_addr_size - 1;

begin

    proc_reg_valid_in : process (clk_audio, reset_a_n) is
    begin

        if (reset_a_n = '0') then
            sample_in_valid_t1 <= '0';
        elsif (rising_edge(clk_audio)) then
            sample_in_valid_t1 <= sample_in_valid;
        end if;

    end process proc_reg_valid_in;

    -----------
    --  RAM  --
    -----------

    samp_ram : entity work.sample_framer_ram(rtl)
        generic map (
            g_data_width => g_sample_width,
            g_addr_width => g_n_bins + 1
        )

        port map (
            wclk => clk_audio,
            waddr => ram_waddr,
            data => sample_in,
            we => ram_we,
            rclk => clk,
            raddr => ram_raddr,
            q => sample_out
        );

    ----------------------------
    --  Write samples to ram  --
    ----------------------------

    proc_write_sample : process (clk_audio, reset_a_n) is

        variable local_waddr : natural range 0 to c_ram_addr_size;

    begin

        if (reset_a_n = '0') then
            ram_we    <= '0';
            ram_waddr <= c_ram_addr_size - 1;
        elsif (rising_edge(clk_audio)) then
            -- WS rising means the transciver
            -- is reading to right channel
            -- ie. Left channel should have a complete
            -- sample
            if ((sample_in_valid = '1') and (sample_in_valid_t1 = '0')) then
                ram_we <= '1';

                -- Signal if there is a full
                -- window
                case ram_waddr is

                    when c_end_idx_0 =>
                        start_read <= start_idx0;
                    when c_end_idx_1 =>
                        start_read <= start_idx1;
                    when c_end_idx_2 =>
                        start_read <= start_idx2;
                    when c_end_idx_3 =>
                        start_read <= start_idx3;
                    when others =>
                        start_read <= no_start;

                end case;

                if (ram_waddr >= c_ram_addr_size - 1) then
                    ram_waddr <= 0;
                else
                    ram_waddr <= ram_waddr + 1;
                end if;
            else
                ram_we     <= '0';
                start_read <= no_start;
            end if;
        end if;

    end process proc_write_sample;

    ----------------------------
    --  Read frames from ram  --
    ----------------------------

    -- Sync to domin crossing
    proc_sync_start_idx : process (clk, reset_n) is
    begin

        if (reset_n = '0') then
            start_read_t1 <= no_start;
            start_read_t2 <= no_start;
            start_read_t3 <= no_start;
        elsif (rising_edge(clk)) then
            start_read_t1 <= start_read;
            start_read_t2 <= start_read_t1;
            start_read_t3 <= start_read_t2;
        end if;

    end process proc_sync_start_idx;

    proc_read_frame : process (clk, reset_n) is

        -- TODO Could these be a pure generic function
        -- look into VHDL generic functions support

        impure function inc_read_counter return natural is
        begin

            if (read_idx = (c_ram_addr_size - 1)) then
                return 0;
            else
                return (read_idx + 1);
            end if;

        end;

        impure function inc_out_counter return natural is
        begin

            if (out_idx = (2**g_n_bins - 1)) then
                return 0;
            else
                return (out_idx + 1);
            end if;

        end;

        variable ignore_first : std_logic := '1';

    begin

        -- This takes a state type
        -- from start_read_t2 to
        -- indicte the start of new
        -- frame, the same type is used
        -- in the fsm for state
        if (reset_n = '0') then
            read_state       <= no_start;
            read_idx         <= 0;
            out_idx          <= 0;
            sample_out_valid <= '0';
            ignore_first := '1';
        elsif (rising_edge(clk)) then
            -- Default assignments
            read_state       <= no_start;
            read_idx         <= 0;
            out_idx          <= 0;
            sample_out_valid <= '0';

            case read_state is

                when no_start =>
                    -- start a new read on a transition from
                    -- no_start to other
                    if (start_read_t3 = no_start and start_read_t2 /= no_start) then
                        read_state <= start_read_t2;
                        -- Set the starting index
                        case start_read_t2 is

                            when start_idx0 =>
                                read_idx <= c_start_idx_0;
                            when start_idx1 =>
                                read_idx <= c_start_idx_1;
                            when start_idx2 =>
                                read_idx <= c_start_idx_2;
                            when start_idx3 =>
                                read_idx <= c_start_idx_3;
                            -- Should not happen
                            when others =>
                                read_idx <= 0;

                        end case;

                    end if;

              when start_idx0 =>

                    sample_out_valid <= '1';

                    if (read_idx /= c_end_idx_0) then
                        read_state <= read_state;
                    end if;
                    read_idx <= inc_read_counter;
                    out_idx  <= inc_out_counter;

              when start_idx1 =>

                    sample_out_valid <= '1';

                    if (read_idx /= c_end_idx_1) then
                        read_state <= read_state;
                    end if;
                    read_idx <= inc_read_counter;
                    out_idx  <= inc_out_counter;

              when start_idx2 =>

                    -- This is a special case,
                    -- its not full on the first run.
                    if (ignore_first = '0') then
                        sample_out_valid <= '1';

                        if (read_idx /= c_end_idx_2) then
                            read_state <= read_state;
                        end if;
                    end if;
                    read_idx <= inc_read_counter;
                    out_idx  <= inc_out_counter;

              when start_idx3 =>

                    -- This is a special case,
                    -- its not full on the first run.
                    if (ignore_first = '0') then
                        sample_out_valid <= '1';

                        if (read_idx /= c_end_idx_3) then
                            read_state <= read_state;
                        end if;
                    else
                        ignore_first := '0';
                    end if;
                    read_idx <= inc_read_counter;
                    out_idx  <= inc_out_counter;

            end case;

        end if;

    end process proc_read_frame;

    -- Hardwire the output to ram
    -- and use `sample_out_valid`
    -- to indicate valid
    ram_raddr <= read_idx;

    -- The out index needs to be registerd
    proc_reg_out_idx : process (clk, reset_n) is
    begin

        if (reset_n = '0') then
            out_idx_t1 <= 0;
        elsif (rising_edge(clk)) then
            out_idx_t1 <= out_idx;
        end if;

    end process proc_reg_out_idx;

    sample_out_idx <= std_logic_vector(to_unsigned(out_idx_t1, sample_out_idx'length));

end architecture behav;

