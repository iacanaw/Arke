library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Arke_pkg.all;

entity NetworkInterface_AsyncFIFO is 
    port(
        clk                 : in std_logic;
        rst                 : in std_logic;
        
        data_in_IP          : in std_logic_vector(DATA_WIDTH-1 downto 0);
        control_in_IP       : in std_logic_vector(CONTROL_WIDTH-1 downto 0);
        data_out_IP         : out std_logic_vector(DATA_WIDTH-1 downto 0);
        control_out_IP      : out std_logic_vector(CONTROL_WIDTH-1 downto 0);
        FIFO_slot_free_tx   : out std_logic_vector(6 downto 0);
        FIFO_slot_free_rx   : out std_logic_vector(6 downto 0);
        
        data_in_NoC         : in std_logic_vector(DATA_WIDTH-1 downto 0);
        control_in_NoC      : in std_logic_vector(CONTROL_WIDTH-1 downto 0);
        data_out_NoC        : out std_logic_vector(DATA_WIDTH-1 downto 0);
        control_out_NoC     : out std_logic_vector(CONTROL_WIDTH-1 downto 0)
    );
end NetworkInterface_AsyncFIFO;

architecture structural of NetworkInterface_AsyncFIFO is
    -- States for the TX and the RX state machines
    --type stateTx is (waiting, asyncTransmission, waitAck, sendEOP, closeConnection_sendIP_ack, holdOn);
	--signal currentTxState : stateTx;
	signal currentTxState : std_logic_vector(2 downto 0);
	
	constant waiting: std_logic_vector(2 downto 0)				      := "000";
	constant waitAck: std_logic_vector(2 downto 0)					  := "001";
	constant asyncTransmission: std_logic_vector(2 downto 0)		  := "011";
	constant sendEOP: std_logic_vector(2 downto 0)					  := "010";
	constant holdOn: std_logic_vector(2 downto 0) 				      := "110";
	constant closeConnection_sendIP_ack: std_logic_vector(2 downto 0) := "100";
	
	
    --type stateRx is (waiting_rx, asyncReicieving, DataDisponibilization, BufferWrite, finishRX, waitIP_Reicieving, doNothing);
    --signal currentRxState : stateRx;
	signal currentRxState : std_logic_vector(2 downto 0);
	
	constant waiting_rx: std_logic_vector(2 downto 0)		    := "000";
	constant asyncReicieving: std_logic_vector(2 downto 0)		:= "001";
	constant DataDisponibilization: std_logic_vector(2 downto 0):= "011";
	constant BufferWrite: std_logic_vector(2 downto 0)			:= "010";
	constant doNothing: std_logic_vector(2 downto 0) 			:= "111";
	constant waitIP_Reicieving: std_logic_vector(2 downto 0) 	:= "110";
	constant finishRX: std_logic_vector(2 downto 0)			:= "100";
	
    -- Sincronization signals for TX
    signal control_in_IP_TX_sync1, control_in_IP_TX_sync2               : std_logic;
    signal control_in_IP_EOP_sync1, control_in_IP_EOP_sync2             : std_logic;
    signal control_in_NoC_STALLGO_sync1, control_in_NoC_STALLGO_sync2   : std_logic;
    --signal control_in_NoC_EOP_sync2, control_in_NoC_EOP_sync1           : std_logic;
    signal snd_fifo_slot_free_sync1, snd_fifo_slot_free_sync2           : std_logic_vector(6 downto 0);
    signal fifo_slots_rx_sync1, fifo_slots_rx_sync2                     : std_logic_vector(6 downto 0);
    
    -- Sincronization signals for RX
    signal control_in_IP_STALL_sync1, control_in_IP_STALL_sync2 : std_logic;
    
    -- Registers to save the current ACK state to detect an future change 
    signal ack_tx_reg, ack_rx_reg : std_logic;
    
    -- Signals to control the write in the RX Buffer
    signal write_s : std_logic;
    
    -- Register the synchroned eop flit that comes from NoC
    signal data_reg : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    -- Signal that merge the FLIT and the EOP bit
    signal data_out, data_in: std_logic_vector(DATA_WIDTH downto 0);
    
    -- Signal to control the RX buffer simulation in the TX side
    signal snd_req, rcv_ack: std_logic;
    
    -- Signals used by the RX Buffer Simulation and the RX Buffer to inform if there is something to be readed or space to be write in 
    signal snd_FIFO_rd, snd_FIFO_wr, snd_fifo_slot_free, fifo_slots_rx : std_logic_vector(6 downto 0);
    
    -- Signals used to reset the RX Buffer Simulation and the RX Buffer
    signal restartBuffSimulation, rstORrestart_RX, rstORrestart_TX, restartFIFO: std_logic;
    
    -- Signals to generate an fake REQ (tx) to the RXBuffer 
    signal tx_reg: std_logic;
    
	-- Anti-Hazard mux control 
	signal ctrl_snd_req_mux: std_logic;
	signal not_tx_reg: std_logic;
	signal ctrl_write_mux: std_logic_vector(1 downto 0);
	signal ctrl_tx_out_mux : std_logic_vector(1 downto 0);
	signal not_stallgo_in : std_logic;
	signal stallgo_out : std_logic;
	signal ctrl_stallgo_out_mux : std_logic;
begin
    
    -- Syncronization from the IP clk to the NoC clk
    process(rst, clk)
        begin
            if rst = '1' then
                control_in_IP_TX_sync1 <= '0';
                control_in_IP_TX_sync2 <= '0';
                control_in_IP_EOP_sync1 <= '0';
                control_in_IP_EOP_sync2 <= '0';
                control_in_IP_STALL_sync1 <= '0';
                control_in_IP_STALL_sync2 <= '0';
                --control_in_NoC_EOP_sync1 <= '0';
                --control_in_NoC_EOP_sync2 <= '0';
                snd_fifo_slot_free_sync1 <= (OTHERS=>'0');
                snd_fifo_slot_free_sync2 <= (OTHERS=>'0');
                control_in_NoC_STALLGO_sync1 <= '0';
                control_in_NoC_STALLGO_sync2 <= '0';
                fifo_slots_rx_sync1 <= (OTHERS=>'0');
                fifo_slots_rx_sync2 <= (OTHERS=>'0');
            elsif rising_edge(clk) then
                control_in_IP_TX_sync1 <= control_in_IP(TX);
                control_in_IP_TX_sync2 <= control_in_IP_TX_sync1;
                
                control_in_IP_EOP_sync1 <= control_in_IP(EOP);
                control_in_IP_EOP_sync2 <= control_in_IP_EOP_sync1;
                
                control_in_IP_STALL_sync1 <= control_in_IP(STALL_GO);
                control_in_IP_STALL_sync2 <= control_in_IP_STALL_sync1;
                
                snd_fifo_slot_free_sync1 <= snd_fifo_slot_free;
                snd_fifo_slot_free_sync2 <= snd_fifo_slot_free_sync1;
                
                fifo_slots_rx_sync1 <= fifo_slots_rx;
                fifo_slots_rx_sync2 <= fifo_slots_rx_sync1;
                
                --control_in_NoC_EOP_sync1 <= control_in_NoC(EOP);
                --control_in_NoC_EOP_sync2 <= control_in_NoC_EOP_sync1;
                
                control_in_NoC_STALLGO_sync1 <= control_in_NoC(STALL_GO);
                control_in_NoC_STALLGO_sync2 <= control_in_NoC_STALLGO_sync1;
            end if;
        end process;
    
    -- NI Transmission Process
    process(rst, clk)
        begin
            if rst = '1' then
                currentTxState <= waiting;
                ack_tx_reg <= '0';
            elsif rising_edge(clk) then
                case currentTxState is
                    -- Default state - waiting for a header to move on
                    when waiting =>
                        if control_in_IP_TX_sync2 = '1' then
                            -- When the header sign that the communication will be Point-Point (asynchronous)
                            --if data_in_IP(DATA_WIDTH-1) = '1' then 
                            currentTxState <= waitAck;
                            -- When the header sign that the communication will use the synchronous packet-switching method
                            --else 
                            --    currentTxState <= syncTransmission;
                            --end if;
                        else
                            currentTxState <= waiting;
                        end if;
                        
                    when waitAck =>
                        -- Waits here until the asynchronous path is stablished
                        if control_in_NoC_STALLGO_sync2 = '0' then
                            currentTxState <= asyncTransmission;
                        else
                            currentTxState <= waitAck;
                        end if;
                        
                    when asyncTransmission =>
                        -- Stay here until the EOP flit arrive 
                        -- AND waits that the reiciever IP send all ACKs for previously submitted flits
                        -- This last part is needed because the NOC must "see" the EOP transmission to de-set the asynchronous path
                        if control_in_IP_EOP_sync2 = '1' AND snd_fifo_slot_free_sync2 = "1111111" then
                            -- Once that those conditions are satisfied we can move ahead to the state that we will send the REQUEST for the EOP flit
                            currentTxState <= sendEOP;
                            -- AND we save the current value of the ACK for future comparisons 
                            --ack_tx_reg <= control_in_NoC(STALL_GO);
                        else
                            currentTxState <= asyncTransmission;
                        end if;
                    
                    when sendEOP =>
                        currentTxState <= holdOn;
                    
                    when holdOn =>
                        currentTxState <= closeConnection_sendIP_ack;
                    
                    when closeConnection_sendIP_ack =>
                        -- Once we send the EOP to the NoC, we can communicate the LocalIP (ACK -> control_out_IP(STALL_GO)) that the communication is closed
                        -- To confirm that the LocalIP has finished his communication we just wait until the EOP signal return to zero
                        if control_in_IP_EOP_sync2 = '0' then
                            currentTxState <= waiting;
                        else
                            currentTxState <= closeConnection_sendIP_ack;
                        end if;
                    
                    when others =>
                        currentTxState <= waiting;
                        
                end case;
            end if;
        end process;
    
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- Asynchronous Simulation of the Reiciever Buffer State --
    -----------------------------------------------------------
    -----------------------------------------------------------
    --      It reicieves the REQUEST signal generated by the 
    -- local IP and the ACK signal that is generated by the 
    -- reiciever IP and travels through the NoC.  
    --      This way the simulator generates a map of the free 
    -- slots in the reiciever buffer.
    -----------------------------------------------------------
    SND_WRITE_CTRL: entity work.JohnsonCounter_7bits
        port map(
            rst     => rstORrestart_TX,
            inc     => snd_req,
            q       => snd_FIFO_wr
        );
        
    SND_READ_CTRL: entity work.JohnsonCounter_7bits
        port map(
            rst     => rstORrestart_TX,
            inc     => rcv_ack,
            q       => snd_FIFO_rd
        );

    snd_fifo_slot_free <= snd_FIFO_wr xnor snd_FIFO_rd;
    rstORrestart_TX <= rst OR restartBuffSimulation;
    restartBuffSimulation <= '1' when currentTxState = closeConnection_sendIP_ack else '0';
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- TX/REQ - output to the NoC
    -- 1 when WAIT_ACK (waiting until the connection is established)
    -- control_in_IP(TX) when ASYNC_TRANSMISSION (bypassing the NI, connecting IP to CQ)
    -- control_in_IP_TX_sync2 when finish_TX (to keep the REQ last sended and do not write nothing wrong in the RXBuffer)
    -- control_out_NoC(TX)      <= '1' when currentTxState = waitAck else
                                -- control_in_IP(TX) when currentTxState = asyncTransmission else
                                -- control_in_IP_TX_sync2 when currentTxState = sendEOP or currentTxState = holdOn else 
                                -- '0';
	
	--constant waiting: std_logic_vector(2 downto 0)				      := "000";
	--constant waitAck: std_logic_vector(2 downto 0)					  := "001";
	--constant asyncTransmission: std_logic_vector(2 downto 0)		      := "011";
	--constant sendEOP: std_logic_vector(2 downto 0)					  := "010";
	--constant holdOn: std_logic_vector(2 downto 0) 				      := "110";
	--constant closeConnection_sendIP_ack: std_logic_vector(2 downto 0)   := "100";
	
	
	ctrl_tx_out_mux <= "00" when currentTxState = waitAck else -- 001
					   "01" when currentTxState = asyncTransmission else -- 011
					   "11" when currentTxState = sendEOP or currentTxState = holdOn else -- 010 OR 110
					   "10";
	
	TX_OUT_MUX: entity work.MUX4x1_hazard_free_ni                             
        port map (
            i0  => '1',
            i1  => control_in_IP(TX),
            i2  => '0',
            i3  => control_in_IP_TX_sync2,
            sel => ctrl_tx_out_mux,
            y   => control_out_NoC(TX)
        );
								
                                
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- EOP - output to the NoC              
    -- following the protocol of the InputBuffer, the transmission of EOP Flit seal the end of communication.
    -- this transmission must be done in the NoC clock domain.
    control_out_NoC(EOP)     <= '1' when currentTxState = sendEOP or currentTxState = holdOn else '0';
    
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- STALL_GO/ACK - output to the IP
    -- Used as a signal to end the transmission
    control_out_IP(STALL_GO) <= '1' when currentTxState = closeConnection_sendIP_ack else '0';
    
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- FIFO_SLOT_FREE_TX - output to the IP
    -- SND_FIFO_SLOT_FREE when ASYNC_TRANSMISSION because it is used by the IP as an map of free slots in the reiciever buffer
    -- "0000001" when WAITING because the NI dont sends confirmation to the IP. So the IP need to think that there is only one 
    --      position to be write, while the connection is stablished.
    FIFO_slot_free_tx        <= snd_fifo_slot_free when currentTxState = asyncTransmission else
                                "0000001" when currentTxState = waiting else
                                "0000000";
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- ACK - input from NoC
    -- RCV_ACK is ACK signal generated by the reiciever IP, it's used by the simulator to determine the free slots map.
    rcv_ack                  <= not control_in_NoC(STALL_GO);
    
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- REQ - input from IP
    -- SND_REQ is the REQ signal generated by the transiever IP, it's used by the simulator to determine the free slots map.
    --snd_req                  <= control_in_IP_TX_sync2 when currentTxState = waiting else
    --                            control_in_IP(TX);
	ctrl_snd_req_mux <= '1' when currentTxState = waiting else '0';
	SND_REQ_MUX: entity work.MUX2x1_hazard_free_ni
        port map (
            i0  => control_in_IP(TX),
            i1  => control_in_IP_TX_sync2,
            sel => ctrl_snd_req_mux,
            y   => snd_req
        );
    
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- Data come from IP and goes on to the NoC
	data_out_NoC             <= data_in_IP;
    
    -----------------------------------------------------------
    -----------------------------------------------------------
    -----------------------------------------------------------
    ---REICIEVER-----------------------------------------------
    -----------------------------------------------------------
    -- NI Reiciever Process
    process(rst, clk)
        begin
            if rst = '1' then
                data_reg <= (OTHERS=>'0');
                currentRxState <= waiting_rx;
				tx_reg <= '0';
            elsif rising_edge(clk) then
                
                case currentRxState is
                    -- Default state - waiting for a header to move on
                    when waiting_rx =>
                        if control_in_NoC(TX) = '1' then
                            -- When the header sign that the communication will be Point-Point (asynchronous)
                            --if data_in_NoC(DATA_WIDTH-1) = '1' then
                            currentRxState <= asyncReicieving;
                            -- When the header sign that the communication will use the synchronous packet-switching method
                            --else
                            --    currentRxState <= syncReicieving;
                            --end if;
                        else
                            currentRxState <= waiting_rx;
                        end if;
                        
                    when asyncReicieving =>
                        -- Once in this state, the communication will make it through
                        -- When the EOP bit come as an ONE then the last flit must be reicieved
                        if control_in_NoC(EOP) = '1' then
                            currentRxState <= DataDisponibilization;
                            -- save the DATA to be write in the queue
                            data_reg <= data_in_NoC;
                            -- save the REQ (tx) to generate an write in the queue
                            tx_reg <= control_in_NoC(TX);
                        else
                            currentRxState <= asyncReicieving;
                        end if;
                    
                    when DataDisponibilization =>
                        currentRxState <= BufferWrite;
                    
                    when BufferWrite =>
                        currentRxState <= doNothing;
                    
                    when doNothing =>
                        -- this is needed to give time to "fifo_slots_rx_sync2" synchronize
                        currentRxState <= waitIP_Reicieving;
                        
                    when waitIP_Reicieving => 
                        -- Wait until the IP has readed the EOP flit and left the buffer empty
                        if fifo_slots_rx_sync2 = "1111111" then
                            currentRxState <= finishRX;
                        else 
                            currentRxState <= waitIP_Reicieving;
                        end if;
                        
                    when finishRX =>
                        -- In this state we just wait to the STALL_GO return to its natural state: ZERO
                        -- During this time reset the RX Buffer
                        if control_in_IP_STALL_sync2 = '0' then
                            currentRxState <= waiting_rx;
                        else 
                            currentRxState <= finishRX;
                        end if;
                        
                    when OTHERS =>
                        currentRxState <= waiting_rx;
                end case;
            end if;
        end process;
    
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- Asynchronous FIFO a.k.a. RX Buffer                    --
    -----------------------------------------------------------
    -----------------------------------------------------------
    --      It reicieves the REQUEST signal generated by the 
    -- transmissor IP and travels through the NoC to here
    -- and the ACK signal that is generated by the Local IP.
    -----------------------------------------------------------
    FIFO: entity work.Asynchronous_FIFO
        generic map (
            DATA_WIDTH  => DATA_WIDTH
        )
        port map (
            rst         => rstORrestart_RX,
            
            wr          => write_s,
            data_in     => data_in,
            slot_free   => fifo_slots_rx,
            
            data_out    => data_out,
            rd          => control_in_IP(STALL_GO)
        );
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- WRITE_S - input in the RX Buffer
    -- not FAKE_TX when sendOP_ACK or waitIP_Reicieving to generate a fake write signaling, to write the EOP in the buffer
    -- else it reicieves the control_in_noc(TX) directly
    --write_s <= tx_reg when currentRxState = DataDisponibilization else
    --          not tx_reg when currentRxState = BufferWrite OR currentRxState = waitIP_Reicieving or currentRxState = doNothing else 
    --          control_in_NoC(TX);
	
not_tx_reg <= not tx_reg;
	
	ctrl_write_mux <= "10" when currentRxState = DataDisponibilization else
					  "11" when currentRxState = BufferWrite OR currentRxState = waitIP_Reicieving OR currentRxState = doNothing else
					  "00";
	
	WRITE_MUX: entity work.MUX4x1_hazard_free_ni
        port map (
            i0  => control_in_NoC(TX),
            i1  => control_in_NoC(TX),
            i2  => tx_reg,
            i3  => not_tx_reg,
            sel => ctrl_write_mux,
            y   => write_s
        );
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- rstORrestart_RX // RestartFIFO - input in the RX Buffer
    -- it is used to reset the Buffer, so the next flit will be write in the first position and it will be read in the first position
    -- so the IP do not need to "record" the last state of his buffer.
    restartFIFO <= '1' when currentRxState = finishRX else '0';
    rstORrestart_RX <= rst OR restartFIFO;
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- fifo_slot_free_rx - output to IP
    -- it is used to inform the Local IP if there is something to be read in the buffer
    fifo_slot_free_rx <= fifo_slots_rx;
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- data_in - input to Buffer 
    -- used to colapse the FLIT data and the EOP bit in one signal that will be send to the RX Buffer
    data_in <=  '1' & data_reg when currentRxState = DataDisponibilization OR currentRxState = BufferWrite or currentRxState = doNothing else
                control_in_NoC(EOP) & data_in_NoC;
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- data_out_IP //  control_out_IP(EOP) - output to Local IP 
    -- used to put the flit data and the EOP bit from the rx buffer in the output to the local IP
    data_out_IP <= data_out(DATA_WIDTH-1 downto 0);
    control_out_IP(EOP) <= data_out(DATA_WIDTH);
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- control_out_IP(TX) output to Local IP
    -- this is used by the NI to inform the local IP that the connection must remains intact
    control_out_IP(TX) <= '1' when currentRxState = finishRX OR currentRxState = waiting_rx else '0';
    -----------------------------------------------------------
    -----------------------------------------------------------
    -- control_out_NoC(STALL_GO) output to NoC
    -- this is the ACK Output to the transmissor IP
    -- not control_in_IP(stall_go) when we are in asyncReicieving because the ACK follows the NOT (STALL_GO)
    -- stay in '1' when waiting (informing the NoC that there is space in the buffer
    --control_out_NoC(STALL_GO) <= not control_in_IP(STALL_GO) when currentRxState = asyncReicieving else
    --                             '1' when currentRxState = waiting_rx else 
    --                             '0';
	not_stallgo_in <= not control_in_IP(STALL_GO);
		
	stallgo_out <= '1' when currentRxState = waiting_rx else '0';
	
	ctrl_stallgo_out_mux <= '0' when currentRxState = asyncReicieving else '1';
	
	STALLGO_OUT_MUX: entity work.MUX2x1_hazard_free_ni
        port map (
            i0  => not_stallgo_in,
            i1  => stallgo_out,
            sel => ctrl_stallgo_out_mux,
            y   => control_out_NoC(STALL_GO)
        );				
								 
end structural;
