-----------------------------------------
-- 7 bits asynchronous Johnson Counter --
-----------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;     

entity JohnsonCounter_7bits is
    port (
        rst         : in std_logic;
        inc         : in std_logic; -- Increments the counter at each transition (0->1 or 1->0)
        q           : out std_logic_vector(6 downto 0)
    );
end JohnsonCounter_7bits;

architecture structural of JohnsonCounter_7bits is 
    signal q_s: std_logic_vector(6 downto 0);
begin
    
    q <= q_s;
       
    q_s(0) <= (not rst and not q_s(6) and inc) or (not rst and q_s(4) and not q_s(6)) or (not rst and q_s(0) and not q_s(5)) or (not rst and q_s(0) and inc);
    q_s(1) <= (not rst and q_s(1) and not inc) or (not rst and q_s(0) and not inc) or (not rst and q_s(0) and q_s(1));
    q_s(2) <= (not rst and q_s(2) and inc) or (not rst and q_s(1) and inc) or (not rst and q_s(1) and q_s(2));
    q_s(3) <= (not rst and q_s(3) and not inc) or (not rst and q_s(2) and not inc) or (not rst and q_s(2) and q_s(3));
    q_s(4) <= (not rst and q_s(4) and inc) or (not rst and q_s(3) and inc) or (not rst and q_s(3) and q_s(4));
    q_s(5) <= (not rst and q_s(5) and not inc) or (not rst and q_s(4) and not inc) or (not rst and q_s(4) and q_s(5));
    q_s(6) <= (not rst and q_s(6) and inc) or (not rst and q_s(5) and inc) or (not rst and q_s(5) and q_s(6));
    
end structural;

