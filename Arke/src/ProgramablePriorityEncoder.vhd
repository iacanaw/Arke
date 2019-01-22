--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Dynamic Priority Encoder                                          --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Everton Alceu Carara, Iaçanã Ianiski Weber & Michel Duarte        --
-- CREATED      : Apr 8th, 2015                                                     --
-- VERSION      : v1.0                                                              --
-- HISTORY      : Version 1.0 - Jan 22th, 2019                                      --
--------------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Arke_pkg.all;

entity ProgramablePriorityEncoder is
    port(
        request         : in std_logic_vector(7 downto 0);
        lowerPriority   : in std_logic_vector(2 downto 0);
        code            : out std_logic_vector(2 downto 0);
        newRequest      : out std_logic
    );
end ProgramablePriorityEncoder;

architecture behavioral of ProgramablePriorityEncoder is
    
    signal mask, lowerRequest, upperRequest: std_logic_vector(7 downto 0);
    signal lowerPriorityEncoder, upperPriorityEncoder: std_logic_vector(2 downto 0);
    signal lower_newRequest: std_logic;

begin
    
    mask <= "01111111" when lowerPriority = "111" else 
            "00111111" when lowerPriority = "110" else
            "00011111" when lowerPriority = "101" else
            "00001111" when lowerPriority = "100" else
            "00000111" when lowerPriority = "011" else
            "00000011" when lowerPriority = "010" else
            "00000001" when lowerPriority = "001" else
            "11111111";
     
   lowerRequest <= request and mask;
   
   upperRequest <= request and (not mask);
   
   lowerPriorityEncoder <=  "111"  when lowerRequest(7)='1' else
                            "110"  when lowerRequest(6)='1' else
                            "101"  when lowerRequest(5)='1' else
                            "100"  when lowerRequest(4)='1' else
                            "011"  when lowerRequest(3)='1' else
                            "010"  when lowerRequest(2)='1' else
                            "001"  when lowerRequest(1)='1' else
                            "000";
   
   upperPriorityEncoder <=  "111"  when upperRequest(7)='1' else
                            "110"  when upperRequest(6)='1' else
                            "101"  when upperRequest(5)='1' else
                            "100"  when upperRequest(4)='1' else
                            "011"  when upperRequest(3)='1' else
                            "010"  when upperRequest(2)='1' else
                            "001"  when upperRequest(1)='1' else
                            "000";
   
   lower_newRequest <= lowerRequest(7) or lowerRequest(6) or lowerRequest(5) or
                   lowerRequest(4) or lowerRequest(3) or lowerRequest(2) or
                   lowerRequest(1) or lowerRequest(0);
   
   code <= lowerPriorityEncoder when lower_newRequest='1' else
           upperPriorityEncoder;
   
   newRequest <= request(7) or request(6) or request(5) or request(4) or
             request(3) or request(2) or request(1) or request(0);

end architecture;