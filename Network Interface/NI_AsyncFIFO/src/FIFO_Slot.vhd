------------------------------------------------------
-- FIFO Slot based on Mouse Trap pipeline stage     --
--      MOUSETRAP: High-Speed Transition-Signaling  --
--      Asynchronous Pipelines                      --
--        Montek Singh and Steven M. Nowick         --
------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;     

entity FIFO_Slot is
    generic (
        DATA_WIDTH  : integer := 8
    );
    port (
        rst         : in std_logic;
        
        -- Input data interface
        req_in      : in std_logic;
        data_in     : in std_logic_vector(DATA_WIDTH downto 0);
        free        : out std_logic;
        
        -- Output data interface
        data_out    : out std_logic_vector(DATA_WIDTH downto 0);
        ack_in      : in std_logic
    );
end FIFO_Slot;



architecture behavioral of FIFO_Slot is
    
    signal data_latch: std_logic_vector(DATA_WIDTH downto 0);
    signal en : std_logic;
          
begin

    data_out <= data_latch;
    free <= en;
        
    en <= req_in xnor ack_in;
    
    process(rst, en, data_in, req_in)
    begin
        if rst = '1' then
            data_latch <= (others=>'0');
            
        elsif en = '1' then
            data_latch <= data_in;
        end if;        
    end process;  
    
end behavioral;