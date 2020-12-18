--------------------------------------------------------------------------------
-- File:             vga.vhd
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
-- Description:      VGA component for to show vertical bars
--                   Uses a double buffer to avoid screen tearing.
--
--
-- In Signals:
--                   clk_main   : clock main domain
--                   clk_vga    : clock vga domain
--                   reset_n    : reset async active low
--                   data       : input data
--                   data_idx   : input index
--                   data_valid : input valid when high
--
-- Out Signals:
--                    vga_hs    : vga horizontal sync
--                    vga_vs    : vga vertical sync
--                    vga_r     : vga red data
--                    vga_g     : vga green data
--                    vga_b     : vga blue data
--------------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.ALL;
    use IEEE.numeric_std.ALL;

entity vga is
    port (
        clk_main : in    std_logic;
        clk_vga  : in    std_logic;
        reset_n  : in    std_logic;

        data       : in    std_logic_vector(8 downto 0);
        data_idx   : in    std_logic_vector(9 downto 0);
        data_valid : in    std_logic;

        vga_hs : out   std_logic;
        vga_vs : out   std_logic;
        vga_r  : out   std_logic_vector(3 downto 0);
        vga_g  : out   std_logic_vector(3 downto 0);
        vga_b  : out   std_logic_vector(3 downto 0)
    );
end entity vga;

architecture behav of vga is

    -- Result ram signals
    signal res_rdaddress : std_logic_vector(9 downto 0);
    signal res_q         : std_logic_vector(8 downto 0);

    -- Framebuffer ram signals
    signal fb_wraddress : std_logic_vector(9 downto 0);
    signal fb_wren      : std_logic;
    signal fb_rdaddress : std_logic_vector(9 downto 0);
    signal fb_q         : std_logic_vector(8 downto 0);

    -- vga
    signal vga_blank_n : std_logic;

begin

    -- copy from buffer ram to Framebuffer
    -- only between frames
    proc_sync_rams : process (clk_main, reset_n) is

        variable c : natural range 0 to 511;

    begin

        if (reset_n = '0') then
            c := 0;
            res_rdaddress <= (others => '0');
            fb_wraddress  <= (others => '0');
        elsif (rising_edge(clk_main)) then
            if (c = 511) then
                c := 0;
            end if;

            if (vga_blank_n = '0') then
                fb_wren <= '1';
            else
                fb_wren <= '0';
            end if;

            res_rdaddress <= std_logic_vector(to_unsigned(c, res_rdaddress'length));
            fb_wraddress  <= std_logic_vector(to_unsigned(c, fb_wraddress'length));

            c := c + 1;
        end if;

    end process proc_sync_rams;

    ---------------
    --  Res RAM  --
    ---------------

    result_ram : entity work.result_ram(syn)
        port map (
            wrclock => clk_main,
            wraddress => data_idx,
            wren => data_valid,
            data => data,

            rdclock => clk_main,
            rdaddress => res_rdaddress,
            q => res_q

        );

    -----------------------
    --  Framebuffer RAM  --
    -----------------------

    frambuff_ram : entity work.result_ram(syn)
        port map (
            wrclock => clk_main,
            wraddress => fb_wraddress,
            wren => fb_wren,
            data => res_q,

            rdclock => clk_vga,
            rdaddress => fb_rdaddress,
            q => fb_q

        );

    -----------
    --  VGA  --
    -----------

    vga : entity work.vga_sync(rtl)
        port map (
            clock_25 => clk_vga,
            reset_n  => reset_n,
            vga_ram_q => fb_q,
            vga_ram_addr => fb_rdaddress,

            vga_frame_blank_n  => vga_blank_n,
            vga_hs => vga_hs,
            vga_vs => vga_vs,
            vga_r  => vga_r,
            vga_g  => vga_g,
            vga_b  => vga_b
        );

end architecture behav;

