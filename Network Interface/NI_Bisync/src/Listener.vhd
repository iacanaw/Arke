library ieee;
use ieee.std_logic_1164.all;
use work.Arke_pkg.all;


entity Listener is 
    port(
        clk:        in std_logic;
        rst:        in std_logic;
        
        writeCrtl:  out std_logic;
        tx_req:     in std_logic;
        stall_ack:  out std_logic;
        full:       in std_logic;
        
        data_in:    in std_logic_vector(DATA_WIDTH-1 downto 0);
        eop_in:     in std_logic;
        data_out:   out std_logic_vector(DATA_WIDTH-1 downto 0);
        eop_out:    out std_logic
    );
end Listener;

architecture listener_behav of Listener is
    type state is (waiting, syncComunication, asyncCommunication, holdAck, finnish);
    signal currentListState: state;
    signal txReq_reg: std_logic;
    signal ack: std_logic;
    signal reqTransition: std_logic;
    signal reqTransition_reg: std_logic;
begin
    
    reqTransition <= tx_req xor txReq_reg; 
    
    process(clk, rst)
    begin
        if(rst='1')then
            reqTransition_reg <= '0';
            txReq_reg <= tx_req;
            ack <= '0';
        elsif(rising_edge(clk))then
            -- register the REQ edge for posterior use
            reqTransition_reg <= reqTransition or reqTransition_reg;
            
            txReq_reg <= tx_req;
            
            case currentListState is
                when waiting => -- Waits here until a header flit comes. Then select the type of the operation, Normal or Async
                    reqTransition_reg <= '0';
                    if tx_req = '1' and full = '0' then
                        if data_in(DATA_WIDTH-1) = '1' then
                            currentListState <= asyncCommunication;
                            ack <= '0';
                        else 
                            currentListState <= syncComunication;
                        end if;
                    else 
                        currentListState <= waiting;
                    end if;
                
                when syncComunication =>
                    if eop_in = '1' and tx_req = '1' and full = '0' then
                        currentListState <= waiting;
                    else
                        currentListState <= syncComunication;
                    end if;
                    
                when asyncCommunication =>
					if (reqTransition = '1' or reqTransition_reg = '1') then
						ack <= not ack;
						reqTransition_reg <= '0';
						if full = '0' then
							currentListState <= asyncCommunication;
						else
							currentListState <= holdAck;
						end if;
					elsif eop_in = '1' then
                        currentListState <= waiting;
                        ack <= '1';
					end if;
                    --if (reqTransition = '1' or reqTransition_reg = '1') and full = '0' then 
                    --    currentListState <= holdAck;
					--	ack <= not ack;
                    --    reqTransition_reg <= '0';
                    --elsif eop_in = '1' then
                    --    currentListState <= waiting;
                    --    ack <= '1';
                    --else
                    --    currentListState <= asyncCommunication;
                    --end if;
                
                when holdAck =>
                    if full = '1' then -- holds until there is space in the output queue for the next flit 
                        currentListState <= holdAck;
                    else
                        currentListState <= asyncCommunication;
                    end if;
                
                when finnish =>
                    -- comunicate that the last flit was saved
                    ack <= '1';
                    currentListState <= waiting;
                    
                when others =>
                    currentListState <= waiting;
                    
            end case;
        end if;
    end process;
    --writeCrtl <= '1' when (((currentListState = waiting and data_in(DATA_WIDTH-1) = '0') or currentListState = syncComunication) and tx_req = '1') or
    writeCrtl <= '1' when ((currentListState = waiting or currentListState = syncComunication) and tx_req = '1') or
                          (currentListState = asyncCommunication and (reqTransition = '1' or reqTransition_reg = '1' or eop_in = '1')) else '0';
    stall_ack <= not full when currentListState = waiting or currentListState = syncComunication else
                 ack when currentListState = asyncCommunication or currentListState = holdAck or currentListState = finnish else
                 '0';
    data_out <= data_in;
    eop_out <= eop_in;

end listener_behav;