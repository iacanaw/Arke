library ieee;
use ieee.std_logic_1164.all;
use work.Arke_pkg.all;


entity Talker is 
    port(
        clk:        in std_logic;
        rst:        in std_logic;
        
        readCtrl:   out std_logic;
        tx_req:     out std_logic;
        stall_ack:  in std_logic;
        empty:      in std_logic;
        
        data_in:    in std_logic_vector(DATA_WIDTH-1 downto 0);
        eop_in:     in std_logic;
        data_out:   out std_logic_vector(DATA_WIDTH-1 downto 0);
        eop_out:    out std_logic
    );
end Talker;

architecture talker_behav of Talker is
    signal ack_reg: std_logic;
    signal ackTransition_reg, ackTransition: std_logic;
    signal request: std_logic;
    type state is (waiting, syncCommunication, asyncCommunication, holdReq);
    signal currentSendState : state;
begin

    ackTransition <= stall_ack xor ack_reg;
    
    process(clk, rst)
    begin
        if rst='1' then
            currentSendState <= waiting;
            ackTransition_reg <= '0';
            request <= '0';
            ack_reg <= '0';
            
        elsif (rising_edge(clk)) then
            -- register the ACK edge for posterior use
            ackTransition_reg <= ackTransition or ackTransition_reg;
            
            ack_reg <= stall_ack;
            
            case currentSendState is
                when waiting =>
                    ackTransition_reg <= '0';
                    if empty = '0' and stall_ack = '1' then
                       if data_in(DATA_WIDTH-1) = '1' then  
                           currentSendState <= asyncCommunication;
                           request <= '1';
                       else
                           currentSendState <= syncCommunication;
						   request <= '0';
                       end if;
                    else
                       currentSendState <= waiting;
                    end if;
                    
                when syncCommunication =>
                    if (eop_in = '1' and empty = '0' and stall_ack = '1') then
                        currentSendState <= waiting;
                    else
                        currentSendState <= syncCommunication;
                    end if;
                
                when asyncCommunication =>
                    --if eop_in = '1' then
					--	currentSendState <= waiting;
					--elsif(empty = '0') then
					--	if(ackTransition = '1' or ackTransition_reg = '1') then
					--		request <= not request;
					--		ackTransition_reg <= '0';
					--	else 
					--		request <= request;
					--	end if;
					--	currentSendState <= asyncCommunication;
					--end if;
					
					if (empty = '0' and (ackTransition = '1' or ackTransition_reg = '1')) then
                        currentSendState <= holdReq;
                        ackTransition_reg <= '0';
                    else
                        currentSendState <= asyncCommunication;
                    end if;
                
                when holdReq => -- holds until there is something in the input queue
                    if eop_in = '1' then
						currentSendState <= waiting;
					elsif empty = '0' then
                        currentSendState <= asyncCommunication;
                        request <= not request;
                    else
                        currentSendState <= holdReq;
                    end if;
                
                when others =>
                    currentSendState <= waiting;
                
            end case;
        end if;
    end process;
   
    readCtrl    <= '1' when currentSendState = asyncCommunication and (ackTransition = '1' or eop_in = '1') else
                    stall_ack when (currentSendState = waiting and data_in(DATA_WIDTH-1) = '0') or currentSendState = syncCommunication else '0';
    data_out    <= data_in;
    eop_out     <= eop_in;
    tx_req      <= '1' when ((currentSendState = waiting or currentSendState = syncCommunication) and empty = '0') else
                   request when (currentSendState = asyncCommunication or currentSendState = holdReq) else '0';
    
end talker_behav;