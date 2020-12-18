--------------------------------------------------------------------------------
-- File:             sample_framer_ram.vhd
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
-- Description:      RAM from Quartus template
--------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;

entity sample_framer_ram is
    generic (
        g_data_width : natural := 8;
        g_addr_width : natural := 6
    );
    port (
        rclk  : in    std_logic;
        wclk  : in    std_logic;
        raddr : in    natural range 0 to 2**g_addr_width - 1;
        waddr : in    natural range 0 to 2**g_addr_width - 1;
        data  : in    std_logic_vector((g_data_width - 1) downto 0);
        we    : in    std_logic;
        q     : out   std_logic_vector((g_data_width -1) downto 0)
    );
end entity sample_framer_ram;

architecture rtl of sample_framer_ram is

    -- Build a 2-D array type for the RAM
    subtype t_word is std_logic_vector((g_data_width - 1) downto 0);

    type t_memory is array(2 ** g_addr_width - 1 downto 0) of t_word;

    -- Declare the RAM signal.
    signal ram : t_memory;

    -- Quartus warns that read during write is undefined
    -- as this shouldent happen we ignore this check.
    attribute ramstyle : string;
    attribute ramstyle of ram : signal is "no_rw_check";

begin

    proc_w : process (wclk) is
    begin

        if (rising_edge(wclk)) then
            if (we = '1') then
                ram(waddr) <= data;
            end if;
        end if;

    end process proc_w;

    proc_r : process (rclk) is
    begin

        if (rising_edge(rclk)) then
            q <= ram(raddr);
        end if;

    end process proc_r;

end architecture rtl;
