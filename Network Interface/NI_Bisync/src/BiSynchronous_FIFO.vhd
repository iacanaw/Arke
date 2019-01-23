------------------------------------------------------------------------------
-- Description: Parameterizable Bi-Synchronous FIFO based on                --
--      Bi-Synchronous FIFO for Synchronous Circuit Communication Well      --
--      Suited for Network-on-Chip in GALS Architectures                    --
--          Ivan MIRO PANADES and Alain GREINER                             --
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BiSynchronous_FIFO is
    generic(
        DEPTH       : natural := 8;
        DATA_WIDTH  : natural := 8
    );
    port(
        rst         : std_logic;
            
        clk_wr      : in std_logic;
        wr          : in std_logic;
        full        : out std_logic;
        data_in     : in std_logic_vector(DATA_WIDTH-1 downto 0);
        
        clk_rd      : in std_logic;
        rd          : in std_logic;
        empty       : out std_logic;
        data_out    : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end BiSynchronous_FIFO;

architecture behavioral of BiSynchronous_FIFO is
    
    type StorageBuffer is array(0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal queue: StorageBuffer;
    
    signal writePointer, writePointer_sync1, writePointer_sync2: UNSIGNED(0 to DEPTH-1);
    signal readPointer: UNSIGNED(0 to DEPTH-1);
    
    signal queue_wr_en, queue_rd_en: std_logic_vector(0 to DEPTH-1);
    
    signal full_sync2, full_sync1, empty_sync: std_logic;
        
    signal readPosition : integer := 0;
     
    function OR_REDUCE(slv : in std_logic_vector) return std_logic is
        variable res: std_logic := '0';
    begin
        for i in slv'range loop
            res := res or slv(i);
        end loop;
        
        return res;
    end function;
        
    begin
                    
        queue_rd_en <= STD_LOGIC_VECTOR(readPointer and ROTATE_RIGHT(readPointer,1));
        
        queue_wr_en <= STD_LOGIC_VECTOR(writePointer and ROTATE_RIGHT(writePointer,1));
                        
        empty_sync <= OR_REDUCE(STD_LOGIC_VECTOR(not writePointer_sync2 and ROTATE_LEFT(writePointer_sync2, 1) and UNSIGNED(queue_rd_en)));
        
        empty <= empty_sync;
        
        full <= full_sync2;
        
        data_out <= queue(readPosition);
        
        -- Convert the one-hot representation of 'queue_rd_en' 
        process(queue_rd_en)
        begin
            readPosition <= 0;
            for i in 0 to DEPTH-1 loop
                if ROTATE_RIGHT(UNSIGNED(queue_rd_en),2)(i) = '1' then
                    readPosition <= i;
                end if;
            end loop;
        end process;
            
                        
        -- Write position on buffer: first token '1' (from left to right) of writePointer
        WRITE: process(clk_wr, rst)
        begin
            if rst = '1' then
				full_sync1 <= '0';
				full_sync2 <= '0';
                for i in 0 to DEPTH-1 loop  -- Set bits 0 and 1 as '1'
                    queue(i) <= (others=>'0');
                    if i = 0 or i = 1 then  -- and the remaining as '0'
                        writePointer(i) <= '1';
                    else
                        writePointer(i) <= '0';
                    end if;
                end loop;
            
            elsif rising_edge(clk_wr) then
                
                -- Points the next available slot on successful write
                if wr = '1' and full_sync2 = '0' then
                    writePointer <= ROTATE_RIGHT(writePointer,1);
                end if;
            
                -- Queue storing
                for i in 0 to DEPTH-1 loop
                    if queue_wr_en(i) = '1' then
                        queue(i) <= data_in;
                    end if;
                end loop;
                
                -- Full detector synchronized
                full_sync1 <= OR_REDUCE(STD_LOGIC_VECTOR(writePointer and readPointer));
                full_sync2 <= full_sync1;
            
            end if;     
        end process;
                
                
        -- Read position on buffer: first '0' after token (from left to right) of readPointer
        READ: process(clk_rd, rst)
        begin
            if rst = '1' then
                readPointer <= TO_UNSIGNED(3,DEPTH);    -- Set the two most right 
                                                        -- bits as '1'
            elsif rising_edge(clk_rd) then
                
                -- Points the next slot to read on successful read
                if rd = '1' and empty_sync = '0' then
                    readPointer <= ROTATE_RIGHT(readPointer,1);
                end if;
            end if;
            
            -- Synchronize writePointer
            writePointer_sync1 <= writePointer;
            writePointer_sync2 <= writePointer_sync1;
            
        end process;        
        
end behavioral;