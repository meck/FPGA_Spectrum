--------------------------------------------------------------------------------
-- File:             vga_sync.vhd
--
-- Company:          Meck AB
-- Engineer:         Johan Eklund
-- Created:          09/25/20
-- Modifed:          2020-12-02
--
--
-- Target Devices:   Intel MAX10
-- Testbench file:   no file
-- Tool versions:    Quartus v18.1 and ModelSim
--
--
-- Description:      VGA Display from RAM
--
--
-- In Signals:
--        clock_25        : clock 25 Mhz
--        reset_n         : reset active low
--        vga_ram_q       : memory input (3bit rgb)
--
-- Out Signals:
--        vga_ram_addr : memory addreess
--        vga_frame_blank_n  : low beetween frames ie,
--                             vertical blank
--        vga_hs : vga hor sync
--        vga_vs : vga ver sync
--        vga_r  : red data
--        vga_g  : blue data
--        vga_b  : green data
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.ALL;
    use IEEE.numeric_std.ALL;
    use IEEE.fixed_pkg.ALL;

entity vga_sync is
    port (
        clock_25          : in    std_logic;
        reset_n           : in    std_logic;
        vga_ram_q         : in    std_logic_vector(8 downto 0);
        vga_ram_addr      : out   std_logic_vector(9 downto 0);
        vga_frame_blank_n : out   std_logic;

        vga_hs : out   std_logic;
        vga_vs : out   std_logic;
        vga_r  : out   std_logic_vector(3 downto 0);
        vga_g  : out   std_logic_vector(3 downto 0);
        vga_b  : out   std_logic_vector(3 downto 0)
    );
end entity vga_sync;

architecture rtl of vga_sync is

    type t_hv is record
        H : integer range 0 to 799;
        V : integer range 0 to 524;
    end record;

    signal counter    : t_hv;
    signal counter_t1 : t_hv;
    signal counter_t2 : t_hv;

    signal vga_blank_n : std_logic;

    signal in_bar : boolean;

    -- The scale factor is 480/512 ie, display height/memory width
    constant c_v_scale_factor     : ufixed(0 downto - 8) := to_ufixed(0.9375, 0, - 8);
    signal   v_unscaled, v_scaled : ufixed(0 downto - 8);

begin

    proc_counters : process (clock_25, reset_n) is
    begin

        if (reset_n = '0') then
            counter.H <= 0;
            counter.V <= 0;
        elsif (rising_edge(clock_25)) then
            -- Horizontal counter
            if (counter.H >= 799) then
                counter.H <= 0;
            else
                counter.H <= counter.H + 1;
            end if;

            -- Vertical counter
            if (counter.H = 707) then
                if (counter.V >= 524) then
                    counter.V <= 0;
                else
                    counter.V <= counter.V + 1;
                end if;
            end if;
        end if;

    end process proc_counters;

    -- Since the memory is registered
    -- we delay the sync signals
    proc_counter_reg : process (clock_25, reset_n) is
    begin

        if (reset_n = '0') then
            counter_t1.V <= 0;
            counter_t1.H <= 0;
            counter_t2.V <= 0;
            counter_t2.H <= 0;
        elsif (rising_edge(clock_25)) then
            counter_t1 <= counter;
            counter_t2 <= counter_t1;
        end if;

    end process proc_counter_reg;

    --------------------
    --  Sync signals  --
    --------------------

    vga_hs <= '0' when counter_t2.H > 659 and counter_t2.H < 756 else
              '1';
    vga_vs <= '0' when counter_t2.V = 494 else
              '1';

    vga_blank_n <= '1' when ((counter_t2.H < 640) and (counter_t2.V  < 480)) else
                   '0';

    vga_frame_blank_n <= '1' when (counter_t2.V  < 480) else
                         '0';

    -----------
    --  RGB  --
    -----------

    -- Need to clamp this value for simulation
    vga_ram_addr <= (std_logic_vector(to_unsigned(counter.H, vga_ram_addr'length)))
                    when ((counter.H < 640) and (counter.V  < 480))
                    else (others => '0');

    -- scale input vertical values 512 => 480
    v_unscaled <= to_ufixed(vga_ram_q, v_unscaled);
    v_scaled   <= resize(c_v_scale_factor * v_unscaled, v_scaled);
    in_bar     <= 480 - to_integer(unsigned(to_slv(v_scaled))) <= counter.V;

    -- Bg color x"57A"
    -- Fg color x"9B8"
    vga_r <= (others => '0') when (vga_blank_n = '0') else
             x"9" when (in_bar) else
             x"5";

    vga_g <= (others => '0') when (vga_blank_n = '0') else
             x"B" when (in_bar) else
             x"7";

    vga_b <= (others => '0') when (vga_blank_n = '0') else
             x"8" when (in_bar) else
             x"A";

end architecture rtl;
