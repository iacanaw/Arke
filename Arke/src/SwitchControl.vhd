--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Switch Control		                                            --
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

entity SwitchControl is
    generic(
        address : std_logic_vector(DATA_WIDTH-1 downto 0) := (others=>'0')
    );
    port(
        clk         :    in    std_logic;
        rst         :    in    std_logic;
        
        -- Input buffers interface
        routingReq  :    in  std_logic_vector(PORTS-1 downto 0);    -- Routing request from input buffers
        routingAck  :    out std_logic_vector(PORTS-1 downto 0);    -- Routing acknowledgement to input buffers
        data        :    in  Array1D_data(0 to PORTS-1);     -- Each array element corresponds to a input buffer data_out
        sending     :    in  std_logic_vector(PORTS-1 downto 0);  -- Each array element signals an input buffer transmiting data
        
        -- Crossbar interface
        table       :    out Array2D_crossbarConfig(0 to PORTS-1, 0 to PORTS-1)    -- Routing table to be connected to crossbar. Each array element encodes a direction.
    );
end SwitchControl;

architecture behavioral of SwitchControl is
   
    type state is (IDLE,ROUTING_ACK);
    signal currentState: state;
    
    signal freePorts: std_logic_vector(PORTS-1 downto 0);   -- Status of all output ports (0 = free; 1 = busy)
    signal routingTable: Array2D_crossbarConfig(0 to PORTS-1, 0 to PORTS-1); -- routingTable(inPort): value = outPort
    signal selectedInPort: integer range 0 to PORTS-1;  -- Input port selected to routing
    signal nextInPort: integer range 0 to PORTS-1;  -- Next input port to be selected to routing
    signal routedOutPort: integer range 0 to PORTS-1;   -- Output port selected by the routing algorithm
    
    signal req: std_logic_vector(7 downto 0);
    signal lowerPriority, code: std_logic_vector(2 downto 0);
    signal newRequest: std_logic;
    
begin
    
    -- Set the priority encoder input request and routing algorithm for 2D NoCs 
    MESH_2D : if(DIM_X>1 and DIM_Y>1 and DIM_Z=1) generate
        
        req <= ("000" & routingReq);
        
        -- Routing (XY algorithm)
        routedOutPort <= XY(data(nextInPort),address);
        
    end generate;
    
    -- Set the priority encoder input request and routing algorithm for 3D NoCs 
    MESH_3D : if(DIM_X>1 and DIM_Y>1 and DIM_Z>1) generate
        
         req <= ('0' & routingReq);
        
        -- Routing (XYZ algorithm)
        routedOutPort <= XYZ(data(nextInPort),address);
        
    end generate;
    
    lowerPriority <= STD_LOGIC_VECTOR(TO_UNSIGNED(selectedInPort,3));

    -------------------------------------------------------------
    -- Round robin policy to chose the input port to be served --
    -------------------------------------------------------------
    PPE: ProgramablePriorityEncoder
        port map(
            request         => req,
            lowerPriority   => lowerPriority,
            code            => code,
            newRequest      => newRequest
        );
        
    nextInPort <= TO_INTEGER(UNSIGNED(code));
    
    ------------------------------
    -- Routing table management --
    ------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            routingAck      <= (others=>'0');                  
            routingTable    <= (others=>(others=>'0'));
            freePorts       <= (others=>FREE);
            currentState    <= IDLE;
            
        elsif rising_edge(clk) then
            case currentState is
                
                -- Takes the port selected by the round robin
                when IDLE =>
                    selectedInPort <= nextInPort;
                    
                    -- Updates the routing table.
                    -- Frees the output ports released by the input ones 
                    for i in 0 to PORTS-1 loop
                        for j in 0 to PORTS-1 loop
                            if sending(i) = '0' and routingTable(j,i) /= '0' then
                                routingTable(j,i) <= '0';
                                freePorts(j) <= FREE;
                            end if;
                        end loop;
                    end loop;   
                    
                    -- Wait for a port request.
                    -- Sets the routing table if the routed output port is available
                    if newRequest = '1' and freePorts(routedOutPort) = FREE then
                        routingTable(routedOutPort,nextInPort) <= '1';
                        routingAck(nextInPort) <= '1';
                        freePorts(routedOutPort) <= BUSY;
                        currentState <= ROUTING_ACK;
                    else
                        currentState <= IDLE;
                    end if;
                    
                -- Holds the routing acknowledgement active for one cycle
                when ROUTING_ACK =>
                    routingAck(selectedInPort) <= '0'; 
                    currentState <= IDLE;
                    
                when others =>
                    currentState <= IDLE;
                
            end case;   
        end if;

    end process;
    
    table <= routingTable;
    
end architecture;