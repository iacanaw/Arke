---------------------------------
-- 2x1 hazard free multiplexer --
---------------------------------

library IEEE;
use IEEE.std_logic_1164.all;     

entity MUX4x1_hazard_free is
    port (
        i0, i1, i2, i3  : in std_logic;
        sel             : in std_logic_vector(1 downto 0);
        y               : out std_logic
    );
end MUX4x1_hazard_free;

architecture structural of MUX4x1_hazard_free is 
    signal y0, y1: std_logic;
begin
    
    MUX0: entity work.MUX2x1_hazard_free
        port map (
            i0  => i0,
            i1  => i1,
            sel => sel(0),
            y   => y0
        );
        
    MUX1: entity work.MUX2x1_hazard_free
    port map (
        i0  => i2,
        i1  => i3,
        sel => sel(0),
        y   => y1
    );
    
    MUX2: entity work.MUX2x1_hazard_free
    port map (
        i0  => y0,
        i1  => y1,
        sel => sel(1),
        y   => y
    );
     
end structural;

