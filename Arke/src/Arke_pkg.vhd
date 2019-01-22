--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Arke Package                                                      --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Everton Alceu Carara, Iaçanã Ianiski Weber & Michel Duarte        --
-- CREATED      : Apr 8th, 2015                                                     --
-- VERSION      : v1.0                                                              --
-- HISTORY      : Version 1.0 - Jan 22th, 2019                                      --
--------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package Arke_pkg is
    
    ---------------
    -- Constants --
    ---------------
                                        ---------------------
                                        -- Parameterizable --
                                        ---------------------
    
    -- Dimension X and Y need to be greater than 1, for 2D NoCs use Z = 1
    -- X grows from left to right, Y grows from front to back, Z grows from bottom to top
    constant DIM_X    : integer := 4;
    constant DIM_Y    : integer := 4;
    constant DIM_Z    : integer := 1;
    
    -- Input buffers depth 
    constant BUFFER_DEPTH : integer := 8; -- Buffer depth must be greater than 1 and a power of 2
    
    -- Data and control buses 
    constant DATA_WIDTH     : integer := 16;                                                            
    constant CONTROL_WIDTH  : integer := 3;  
   
                                      -------------------------
                                      -- Not parameterizable --
                                      -------------------------
    
    -- Control signals identification
    constant EOP        : integer := 0;
    constant RX         : integer := 1;
    constant TX         : integer := 1;
    constant STALL_GO   : integer := 2;
    constant BYPASS     : integer := 3;
    
    -- Router ports identification
    constant LOCAL      : integer := 0;
    constant EAST       : integer := 1;
    constant SOUTH      : integer := 2;
    constant WEST       : integer := 3;
    constant NORTH      : integer := 4;
    constant UP         : integer := 5;
    constant DOWN       : integer := 6;
    
    -- Number of router ports
    -- The function returns 5 to 2D mesh and 7 for 3D mesh
    constant PORTS      : integer := (7 - 2*(1/DIM_Z));
        
    -- 
    constant NOT_ROUTED : std_logic_vector(2 downto 0) := "111";
    constant FREE       : std_logic := '0';
    constant BUSY       : std_logic := '1';
    
    -- Network Interface BUFFER_DEPTH
    constant NI_DEPTH      : natural := 4;
    constant NI_INDEX_COUNT: natural := 4; --log2(NI_DEPTH)
    
    -----------------
    -- Array types --
    -----------------
    type Array3D_slotFree is array(natural range <>, natural range <>, natural range<>) of std_logic_vector(6 downto 0);
    -- Types used at Router (Router.vhd) and Switch Control (SwitchControl.vhd) interfaces.
    -- Each element indicates a port (LOCAL, EAST, WEST, NORTH, SOUTH, UP or DOWN).
    type Array1D_data is array (natural range <>) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type Array1D_control is array (natural range <>) of std_logic_vector(CONTROL_WIDTH-1 downto 0);
    type Array1D_ports is array (natural range<>) of std_logic_vector(PORTS-1 downto 0);
    type Array1D_3bits is array (natural range<>) of std_logic_vector(2 downto 0);
    
    -- Types used at NoC interface. 
    -- In case of 3D NoCs, each element (x,y,z) indicates a router local port. 
    -- In case of 2D NoCs z=1. Each element (x,y,1) indicates a router local port. 
    type Array3D_data is array (natural range <>, natural range <>, natural range<>) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type Array3D_control is array (natural range <>, natural range <>, natural range<>) of std_logic_vector(CONTROL_WIDTH-1 downto 0);
    
    -- Types used to interconnect routers when generating a NoC instance (NoC.vhd).
    type Array4D_data is array (natural range <>, natural range <>, natural range <>, natural range<>) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type Array4D_control is array (natural range <>, natural range <>, natural range <>, natural range<>) of std_logic_vector(CONTROL_WIDTH-1 downto 0);

    -- Type used to generate the routing table to config the cossbar.
    type Array2D_crossbarConfig is array(natural range <>, natural range <>) of std_logic;
    
    -- Buffer to store flits instantiated at port (InputBuffer.vhd)
    type DataBuff is array(0 to BUFFER_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    
    function Log2(temp : natural) return natural;
    function Address(x,y,z : natural) return std_logic_vector;
    function XYZ(target,current: std_logic_vector(DATA_WIDTH-1 downto 0)) return integer;
    function XY(target,current: std_logic_vector(DATA_WIDTH-1 downto 0)) return integer;    
    
    --------------------------------
    -- NoC components declaration --
    --------------------------------
    component InputBuffer is
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
    end component;
    
    component Crossbar is
    port(   
        -- Switch Control interface
        routingTable    : in Array2D_crossbarConfig(0 to PORTS-1, 0 to PORTS-1);
        
        -- Input buffers interface
        data_in         : in Array1D_data(0 to PORTS-1);
        control_in      : in Array1D_control(0 to PORTS-1);
        
        -- Router output ports interface
        data_out        : out Array1D_data(0 to PORTS-1);
        control_out     : out Array1D_control(0 to PORTS-1)
    );
    end component;
    
    component ProgramablePriorityEncoder is
    port(
        request         : in std_logic_vector(7 downto 0);
        lowerPriority   : in std_logic_vector(2 downto 0);
        code            : out std_logic_vector(2 downto 0);
        newRequest      : out std_logic
    );
    end component;
    
    component SwitchControl is
    generic(
        address : std_logic_vector(DATA_WIDTH-1 downto 0));
    port(
        clk         :    in    std_logic;
        rst         :    in    std_logic;
        
        -- Input buffers interface
        routingReq  :    in  std_logic_vector(PORTS-1 downto 0);    -- Routing request from input buffers
        routingAck  :    out std_logic_vector(PORTS-1 downto 0);    -- Routing acknowledgement to input buffers
        data        :    in  Array1D_data(0 to PORTS-1);            -- Each array element corresponds to a input buffer data_out
        sending     :    in  std_logic_vector(PORTS-1 downto 0);    -- Each array element signals an input buffer transmiting data
        
        -- Crossbar interface
        table       :    out Array2D_crossbarConfig(0 to PORTS-1, 0 to PORTS-1)    -- Routing table to be connected to crossbar. Each array element encodes a direction.
    );
    end component;
    
    component Router is
    generic(address: std_logic_vector(DATA_WIDTH-1 downto 0));
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        
        -- Data and control inputs
        data_in     : in Array1D_data(0 to PORTS-1);
        control_in  : in Array1D_control(0 to PORTS-1);
        
        -- Data and control outputs
        data_out    : out Array1D_data(0 to PORTS-1);
        control_out : out Array1D_control(0 to PORTS-1)
    );
    end component;
    
    component NoC is
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        
        -- LOCAL input and output port for each node
        data_in     : in Array3D_data(0 to DIM_X-1, 0 to DIM_Y-1, 0 to DIM_Z-1);
        control_in  : in Array3D_control(0 to DIM_X-1, 0 to DIM_Y-1, 0 to DIM_Z-1);
        
        data_out    : out Array3D_data(0 to DIM_X-1, 0 to DIM_Y-1, 0 to DIM_Z-1);
        control_out : out Array3D_control(0 to DIM_X-1, 0 to DIM_Y-1, 0 to DIM_Z-1)
    );
    end component;
    
end package;

package body Arke_pkg is
    
    -- Function returns the logarithm of 2 from the argument.
    function Log2(temp : natural) return natural is
    begin
        for i in 0 to integer'high loop
            if (2**i >= temp) then
                return i;
            end if;
        end loop;
        return 0;
    end function Log2;
    

    -- Function returns the address of a router in flit header format.
    --
    --                       DATA_WIDTH
    --      |--------------------------------------------|
    --
    --      +--------+-----------+-----------+-----------+
    --      | 00...0 |  X_FIELD  |  Y_FIELD  |  Z_FIELD  |
    --      +--------+-----------+-----------+-----------+
    -- 
    constant X_FIELD    : integer := Log2(DIM_X);
    constant Y_FIELD    : integer := Log2(DIM_Y);
    constant Z_FIELD    : integer := Log2(DIM_Z);
    
    function Address(x,y,z : natural) return std_logic_vector is
        variable address : std_logic_vector(DATA_WIDTH-1 downto 0);
        variable binX : std_logic_vector(X_FIELD-1 downto 0);
        variable binY : std_logic_vector(Y_FIELD-1 downto 0);
        variable binZ : std_logic_vector(Z_FIELD-1 downto 0);
        variable zeros2D: std_logic_vector(DATA_WIDTH-1-(X_FIELD+Y_FIELD) downto 0);
        variable zeros3D: std_logic_vector(DATA_WIDTH-1-(X_FIELD+Y_FIELD+Z_FIELD) downto 0);
    begin
        if(DIM_Z = 1) then -- NoC 2D
            binX := std_logic_vector(TO_UNSIGNED(x,X_FIELD));
            binY := std_logic_vector(TO_UNSIGNED(y,Y_FIELD));
            zeros2D := (others=>'0');
            address := zeros2D & binX & binY;
        else  -- NoC 3D
            binX := std_logic_vector(TO_UNSIGNED(x,X_FIELD));
            binY := std_logic_vector(TO_UNSIGNED(y,Y_FIELD));
            binZ := std_logic_vector(TO_UNSIGNED(z,Z_FIELD));
            zeros3D := (others=>'0');
            address := zeros3D & binX & binY & binZ;
        end if;

        return address;
    end function Address;
    
    --Function returns the port that should be used to send the packet according the XYZ algorithm.
    function XYZ(target,current: std_logic_vector(DATA_WIDTH-1 downto 0)) return integer is
        -- Routed output port
        variable outputPort : integer range 0 to PORTS-1;
        
        -- Current router address
        variable currentX   : std_logic_vector(X_FIELD-1 downto 0) := current(Z_FIELD+Y_FIELD+X_FIELD-1 downto Z_FIELD+Y_FIELD);
        variable currentY   : std_logic_vector(Y_FIELD-1 downto 0) := current(Y_FIELD+Z_FIELD-1 downto Z_FIELD);
        variable currentZ   : std_logic_vector(Z_FIELD-1 downto 0) := current(Z_FIELD-1 downto 0);
        
        -- Target router address
        variable targetX    : std_logic_vector(X_FIELD-1 downto 0) := target(Z_FIELD+Y_FIELD+X_FIELD-1 downto Z_FIELD+Y_FIELD);
        variable targetY    : std_logic_vector(Y_FIELD-1 downto 0) := target(Y_FIELD+Z_FIELD-1 downto Z_FIELD);
        variable targetZ    : std_logic_vector(Z_FIELD-1 downto 0) := target(Z_FIELD-1 downto 0);
    begin
        if(currentX = targetX) then
        
            if(currentY = targetY) then
            
                if(currentZ = targetZ) then
                    outputPort := LOCAL;
                elsif(currentZ < targetZ) then
                    outputPort := UP;
                else --currentZ > targetZ
                    outputPort := DOWN;
                end if;
                
            elsif (currentY < targetY) then
                outputPort := NORTH;
            else --currentY > targetY
                outputPort := SOUTH;
            end if;
            
        elsif (currentX < targetX) then
            outputPort := EAST;
        else --currentX > targetX
            outputPort := WEST;
        end if;
        
        return outputPort;
        
    end XYZ;
    
    -- Function returns the port that should be used to send the packet according the XYZ algorithm.
    function XY(target,current: std_logic_vector(DATA_WIDTH-1 downto 0)) return integer is
        -- Routed output port
        variable outputPort : integer range 0 to PORTS-1;
        
        -- Current router address
        variable currentX   : std_logic_vector(X_FIELD-1 downto 0) := current(Y_FIELD+X_FIELD-1 downto Y_FIELD);
        variable currentY   : std_logic_vector(Y_FIELD-1 downto 0) := current(Y_FIELD-1 downto 0);
        
        -- Target router address
        variable targetX    : std_logic_vector(X_FIELD-1 downto 0) := target(Y_FIELD+X_FIELD-1 downto Y_FIELD);
        variable targetY    : std_logic_vector(Y_FIELD-1 downto 0) := target(Y_FIELD-1 downto 0);
    begin
        if(currentX = targetX) then
        
            if(currentY = targetY) then            
                outputPort := LOCAL;
            elsif (currentY < targetY) then
                outputPort := NORTH;
            else --currentY > targetY
                outputPort := SOUTH;
            end if;
            
        elsif (currentX < targetX) then
            outputPort := EAST;
        else --currentX > targetX
            outputPort := WEST;
        end if;
        
        return outputPort;
        
    end XY;

end Arke_pkg;