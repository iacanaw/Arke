------------------------------------------------------------------
-- 7 slots Asynchronous FIFO with parameterizable data width    --
--      Dual-phase read/write controls (wr/rd)                  --
------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.all;    

entity Asynchronous_FIFO is
    generic (
        DATA_WIDTH  : integer := 16
    );
    port (
        rst         : in std_logic;
        
        wr          : in std_logic;
        data_in     : in std_logic_vector(DATA_WIDTH downto 0);
        slot_free   : out std_logic_vector(6 downto 0);
            
        data_out    : out std_logic_vector(DATA_WIDTH downto 0);
        rd          : in std_logic
    );
end Asynchronous_FIFO;

architecture structural of Asynchronous_FIFO is 
    type DataArray is array (natural range <>) of std_logic_vector(DATA_WIDTH downto 0);
    signal slot_data: DataArray(0 to 6);
    signal wr_ctrl, rd_ctrl: std_logic_vector(6 downto 0);
begin
    
    WRITE_CTRL: entity work.JohnsonCounter_7bits
        port map(
            rst     => rst,
            inc     => wr,
            q       => wr_ctrl
        );
        
    FIFO: for i in 0 to 6 generate
        STAGE: entity work.FIFO_Slot
            generic map (
                DATA_WIDTH  => DATA_WIDTH
            )
            port map(
                rst         => rst,
                
                req_in      => wr_ctrl(i),
                data_in     => data_in,
                free        => slot_free(i),
                
                data_out    => slot_data(i),
                ack_in      => rd_ctrl(i)
            ); 
    end generate;
                
    READ_CTRL: entity work.JohnsonCounter_7bits
        port map(
            rst     => rst,
            inc     => rd,
            q       => rd_ctrl
        );
        
    data_out  <=    slot_data(0) when rd_ctrl = "0000000" or rd_ctrl = "1111111" else
                    slot_data(1) when rd_ctrl = "0000001" or rd_ctrl = "1111110" else
                    slot_data(2) when rd_ctrl = "0000011" or rd_ctrl = "1111100" else
                    slot_data(3) when rd_ctrl = "0000111" or rd_ctrl = "1111000" else
                    slot_data(4) when rd_ctrl = "0001111" or rd_ctrl = "1110000" else
                    slot_data(5) when rd_ctrl = "0011111" or rd_ctrl = "1100000" else
                    slot_data(6);
end structural;