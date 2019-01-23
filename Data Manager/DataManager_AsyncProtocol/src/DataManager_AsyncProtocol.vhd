--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Data Manager                                                      --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Everton Alceu Carara, Iaçanã Ianiski Weber & Michel Duarte        --
-- CREATED      : Jul 9th, 2015                                                     --
-- VERSION      : v1.0                                                             --
-- HISTORY      : Version 0.1 - Jul 9th, 2015                                       --
--              : Version 0.2.1 - Set 18th, 2015                                    --
--------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.Text_Package.all;
use work.Arke_pkg.all;


entity DataManager_AsyncProtocol is 
    generic(
            fileNameIn  : string;
            fileNameOut : string
    );
    port(
        clk                 : in std_logic;
        rst                 : in std_logic;
        
        data_in             : in std_logic_vector(DATA_WIDTH-1 downto 0);
        eop_in              : in std_logic;
        req_rx              : in std_logic;
        ack_rx              : out std_logic;
        fifo_slot_free_rx   : in std_logic_vector(6 downto 0);
                
        data_out            : out std_logic_vector(DATA_WIDTH-1 downto 0);
        eop_out             : out std_logic;
        req_tx              : out std_logic;
        ack_tx              : in std_logic;
        fifo_slot_free_tx   : in std_logic_vector(6 downto 0)        
    );
end DataManager_AsyncProtocol;

architecture behavioral of DataManager_AsyncProtocol is
begin
    SEND: block
        type state is (S0, S1);
        signal currentState : state;
        signal words : std_logic_vector(DATA_WIDTH+3 downto 0); --  eop + word 
        file flitFile : text open read_mode is fileNameIn;
        signal fifo_wr_pos : integer;
        signal req: std_logic;
        signal fifo_slot_free_tx_sync1, fifo_slot_free_tx_sync2 : std_logic_vector(6 downto 0);
        signal ack_1, ack_2 : std_logic;
    begin
        process(clk, rst)
            begin
                if rst = '1' then 
                    ack_1 <= '0';
                    ack_2 <= '0';
                elsif rising_edge(clk) then
                    ack_1 <= ack_tx;
                    ack_2 <= ack_1;
                end if;
        end process;
        
        
        process(clk, rst)
            variable flitLine   : line;
            variable str        : string(1 to 5);
            begin 
                if rst = '1' then
                    words <= (OTHERS=>'0');
                elsif rising_edge(clk) then
                                        
                    -- Write to FIFO
                    if ack_2 = '1' AND words(DATA_WIDTH) = '1' then
                        words(DATA_WIDTH) <= '0';
                    elsif not(endfile(flitFile)) AND fifo_slot_free_tx_sync2(fifo_wr_pos) = '1' AND words(DATA_WIDTH) = '0' then
                        readline(flitFile, flitLine);
                        read(flitLine, str);
                        words <= StringToStdLogicVector(str);
                    end if;
                end if;
            end process;
        
        process(clk,rst)
            begin
                if rst = '1' then
                    req <= '0';
                    fifo_wr_pos <= 0;
                    fifo_slot_free_tx_sync1 <= (OTHERS=>'0');
                    fifo_slot_free_tx_sync2 <= (OTHERS=>'0');
                elsif rising_edge(clk) then
                    -- fifo_slot_free input synchronization
                    fifo_slot_free_tx_sync1 <= fifo_slot_free_tx;
                    fifo_slot_free_tx_sync2 <= fifo_slot_free_tx_sync1;
                    
                    if ack_2 = '1' AND words(DATA_WIDTH) = '1' then 
                        req <= '0';
                        fifo_wr_pos <= 0;
                    elsif not(endfile(flitFile)) AND fifo_slot_free_tx_sync2(fifo_wr_pos) = '1' AND words(DATA_WIDTH) = '0' then
                        req <= not req;
                        if fifo_wr_pos = 6 then
                            fifo_wr_pos <= 0;
                        else
                            fifo_wr_pos <= fifo_wr_pos + 1;
                        end if;
                    end if;
                end if;
            end process;
        
        data_out <= words(DATA_WIDTH-1 downto 0);
        eop_out <= words(DATA_WIDTH);
        req_tx <= req;
    end block SEND;
    
    RECIEVE: block
        type state is (Recieving, Reseting, Wait1, Wait2);
        signal currentState : state;
        signal completeLine : std_logic_vector(DATA_WIDTH+3 downto 0);
        file flitFile : text open write_mode is fileNameOut;
        signal fifo_slot_free_rx_sync1, fifo_slot_free_rx_sync2: std_logic_vector(6 downto 0);
        signal fifo_rd_pos: integer;
        signal ack: std_logic;
    begin
        completeLine <= b"000" & eop_in & data_in;
        ack_rx <= ack;
        process(clk, rst)
            variable flitLine   : line;
            variable str        : string (1 to 9);
            begin
                if rst = '1' then
                    ack <= '0';
                    fifo_rd_pos <= 0;
                    fifo_slot_free_rx_sync2 <= (OTHERS=>'1');
                    fifo_slot_free_rx_sync1 <= (OTHERS=>'1');
                    currentState <= Recieving;
                        
                elsif rising_edge(clk) then
                    -- fifo_slot_free input synchonization
                    fifo_slot_free_rx_sync1 <= fifo_slot_free_rx;
                    fifo_slot_free_rx_sync2 <= fifo_slot_free_rx_sync1;
                    
                    case currentState is
                        when Recieving =>
                            if fifo_slot_free_rx_sync2(fifo_rd_pos) = '0' then
                                write(flitLine, StdLogicVectorToString(completeLine));
                                writeline(flitFile, flitLine);
                                ack <= not ack;
                                
                                if eop_in = '1' then
                                    currentState <= Reseting;
                                    
                                else
                                    currentState <= Recieving;  
                                    
                                    if fifo_rd_pos = 6 then
                                        fifo_rd_pos <= 0;
                                    else
                                        fifo_rd_pos <= fifo_rd_pos + 1;
                                    end if;
                                    
                                end if;
                                
                            end if;
                            
                        when Reseting =>
                            if fifo_slot_free_rx_sync2 = "1111111" AND req_rx = '1' then
                                ack <= '0';
                                fifo_rd_pos <= 0;
                                currentState <= Wait1;
                            else 
                                currentState <= Reseting;
                            end if;
                        
                        when Wait1 =>
                            currentState <= Wait2;
                         
                        when Wait2 =>
                            currentState <= Recieving;
                        
                        when others =>
                            currentState <= Recieving;
                        
                    end case;        
                end if;
            end process;
    end block RECIEVE;
    
end architecture;