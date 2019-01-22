---------------------------------
-- 2x1 hazard free multiplexer --
---------------------------------

library IEEE;
use IEEE.std_logic_1164.all;     

entity MUX2x1_hazard_free is
    port (
        i0, i1      : in std_logic;
        sel         : in std_logic;
        y           : out std_logic
    );
end MUX2x1_hazard_free;

architecture structural of MUX2x1_hazard_free is 
begin
    y <= (not sel and i0) or (sel and i1) or (i0 and i1);
end structural;
