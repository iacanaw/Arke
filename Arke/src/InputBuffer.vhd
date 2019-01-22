--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Input Buffer                                                      --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Everton Alceu Carara, Iaçanã Ianiski Weber & Michel Duarte        --
-- CREATED      : Apr 8th, 2015                                                     --
-- VERSION      : v1.0                                                              --
-- HISTORY      : Version 1.0 - Jan 22th, 2019                                      --
--------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.Arke_pkg.all;

entity InputBuffer is
    port(
        clk             : in std_logic;
        rst             : in std_logic;
        
        -- Receiving/Sending Interface
        data_in         : in std_logic_vector(DATA_WIDTH-1 downto 0);
        control_in      : in std_logic_vector(CONTROL_WIDTH-1 downto 0);
        data_out        : out std_logic_vector(DATA_WIDTH-1 downto 0);
        control_out     : out std_logic_vector(CONTROL_WIDTH-1 downto 0);
        
        -- Switch Control Interface
        routingRequest  : out std_logic;
        routingAck      : in  std_logic;
        sending         : out std_logic
    );
end InputBuffer;

-- This architecture implies a 4 cycles pipeline router due to the register used to store the routingRequest output
architecture pipeline_4_cycles of InputBuffer is
    --type state is (IDLE, WAITING_ACK, TRANSMITTING, BYPASS_STATE, FINISH_BYPASS);
    --signal currentState : state;
    
    constant IDLE: std_logic_vector(2 downto 0)             := "011";
    constant WAITING_ACK: std_logic_vector(2 downto 0)      := "111";
    constant TRANSMITTING: std_logic_vector(2 downto 0)     := "010";
    constant BYPASS_STATE: std_logic_vector(2 downto 0)     := "000";
    constant FINISH_BYPASS: std_logic_vector(2 downto 0)    := "001";
    
    signal currentState: std_logic_vector(2 downto 0);
    
    -- "first" and "last" indexes width calculated based on BUFFER_DEPTH
    -- Used to control the circular queue
    signal first,last       : UNSIGNED((log2(BUFFER_DEPTH)-1) downto 0);
    signal available_slot   : std_logic;
    
    -- Buffer works in a circular queue - first in first out
    signal queue            : DataBuff;
    -- Store the EOP signal relative to each flit stored in queue 
    signal eop_buff         : std_logic_vector(BUFFER_DEPTH-1 downto 0);
    
        -- Assynchronous communication
    signal isBypass         : std_logic;
    signal eop_reg, tx_reg  : std_logic;
    signal data_reg         : std_logic_vector(DATA_WIDTH-1 downto 0);
		
    signal isHeader         : std_logic;
    signal asyncQueued, stallGo: std_logic;
    
    signal muxControl_sg : std_logic;
    signal transmitting_tx  : std_logic;
begin

    process(rst,clk) -- async reset
    begin
        if rst='1' then
            last <= (others=>'0');
            queue <= (others=>(others=>'0'));
            eop_buff <= (others=>'0');
			asyncQueued <= '0';
            isHeader <= '1';
        elsif rising_edge(clk) then
	------------------------------------------------------
    -- Controls the flit receiving and storing on queue --
    ------------------------------------------------------
            -- If the buffer is receiving data and there is an available slot in the buffer then
            -- store the data flit in the free slot pointed by last
            -- Each buffer slot has an EOP and BYPASS flag assigned to it (eop_buff/bypass_buff)
            if control_in(RX) = '1' and available_slot = '1' and currentState /= BYPASS_STATE and currentState /= FINISH_BYPASS and asyncQueued = '0' then
                queue(TO_INTEGER(last)) <= data_in;
                eop_buff(TO_INTEGER(last)) <= control_in(EOP);
                last <= last + 1;
            end if;
	
	------------------------------------------------------------------
    -- Controls flags for the establishment of async communication  --
    ------------------------------------------------------------------
			-- Reset the isHeader and asyncQueued when the async communication is established
            if currentState = BYPASS_STATE or currentState = FINISH_BYPASS then
                isHeader <= '1';
                asyncQueued <= '0'; 
            elsif control_in(RX) = '1' and available_slot = '1' then
                -- Register if the next flit is a header flit 
                if control_in(EOP) = '1' then
                    isHeader <= '1';
                else --if isHeader = '1' then
                    isHeader <= '0';
                end if;
                -- Register if the new header is an async header
                if (data_in(DATA_WIDTH-1) = '1' and isHeader = '1') then
                    asyncQueued <= '1';
                end if;
            end if;
			
        end if;
    end process;
    
    -- Determine if there is any available slot in the buffer
    available_slot <= '0' when ((TO_INTEGER(first) = 0) and (last = BUFFER_DEPTH-1)) or (first = last+1) else '1';    
    stallGo <= available_slot or asyncQueued;
    
    -- Connect the queue output (next to-be-transmitted flit) to the data output
    data_out <= data_in when currentState = BYPASS_STATE else
                data_reg when currentState = FINISH_BYPASS else
                queue(TO_INTEGER(first));
    
    -- Connect the EOP and BYPASS signal to the control output
    control_out(EOP) <= eop_reg when currentState = BYPASS_STATE OR currentState = FINISH_BYPASS else eop_buff(TO_INTEGER(first));
    
    -- Connect the STALL_GO signal to the control output
    -- control_out(STALL_GO) <= control_in(STALL_GO) when currentState = BYPASS_STATE else 
                             -- stallGo;
    muxControl_sg <= '1' when currentState = BYPASS_STATE else '0';                       
                             
    CONTROL_OUT_SG_MUX: entity work.MUX2x1_hazard_free
        port map (
            i0  => stallGo,
            i1  => control_in(stall_go),--control_in(STALL_GO),
            sel => muxControl_sg,
            y   => control_out(STALL_GO)
        );
	
	--constant IDLE: std_logic_vector(2 downto 0)             := "011";
    --constant WAITING_ACK: std_logic_vector(2 downto 0)      := "111";
    --constant TRANSMITTING: std_logic_vector(2 downto 0)     := "110";
    --constant BYPASS_STATE: std_logic_vector(2 downto 0)     := "000";
    --constant FINISH_BYPASS: std_logic_vector(2 downto 0)   := "001";
    
    transmitting_tx <= '1' when first /= last else '0';
       
    CONTROL_OUT_TX_MUX: entity work.MUX4x1_hazard_free
        port map (
            i0  => control_in(tx),--control_in(RX),
            i1  => tx_reg,
            i2  => transmitting_tx,
            i3  => '0',
            sel => currentState(1 downto 0),
            y   => control_out(TX)
        );
    
    -- Warns the SwitchControl that the routed port is in use
    sending <= '1' when (currentState = TRANSMITTING OR currentState = BYPASS_STATE or currentState = FINISH_BYPASS) else '0';
    
    ------------------------------------------------------------
    -- Controls the flit transmission and removing from queue --
    ------------------------------------------------------------
    process(rst,clk) -- async reset
    begin
        if rst='1' then
            first <= (others=>'0');
            data_reg <= (others=>'0');
            currentState <= IDLE;
            routingRequest <= '0';
            isBypass <= '0';
            eop_reg <= '0';
            tx_reg <= '0';
        elsif rising_edge(clk) then
            case currentState is
            
                -- Request routing for current package
                when IDLE =>
                    if currentState = IDLE and last /= first then
                        routingRequest <= '1';
                        currentState <= WAITING_ACK;
                    else 
                        currentState <= IDLE;
                    end if;
                
                -- Waits the ACK signal from SwitchControl
                when WAITING_ACK =>
                    if routingAck = '1' then
                        routingRequest <= '0';
                        if queue(TO_INTEGER(first))(DATA_WIDTH-1) = '1' then
                            isBypass <= '1';
                            currentState <= TRANSMITTING;
                        else
							isBypass <= '0';
                            currentState <= TRANSMITTING;
                        end if;
                    else
                        currentState <= WAITING_ACK;
                    end if;
                
                -- Hold the connection until the asynchronous communication ends
                when BYPASS_STATE =>
                    if control_in(EOP) = '1' then
                        currentState <= FINISH_BYPASS;
						data_reg     <= data_in;
						eop_reg      <= '1';
						tx_reg       <= control_in(TX);
                    else
                        currentState <= BYPASS_STATE;
                    end if;
                
                when FINISH_BYPASS =>
                    eop_reg      <= '0';
                    tx_reg       <= '0';
                    isBypass     <= '0';
                    currentState <= IDLE;

                -- Send package flits
                when TRANSMITTING =>
                    -- Verifies if receiver has an available slot and there is data to be sent
                    if control_in(STALL_GO)='1' and last /= first then
                        first <= first + 1;     -- Set the next flit to be transmitted
                        -- If the last packet flit was transmitted, finish the transmission
                        if isBypass = '1' then
                            currentState <= BYPASS_STATE;
                        else 
                            if eop_buff(TO_INTEGER(first)) = '1' then
                                currentState <= IDLE;
                            else
                                currentState <= TRANSMITTING;
                            end if;
                        end if;
                    else
                        currentState <= TRANSMITTING;
                    end if;
                    
                when others =>
                    currentState <= IDLE;
                    
            end case;
        end if;
    end process;
    
end architecture;