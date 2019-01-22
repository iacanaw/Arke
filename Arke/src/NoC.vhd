--------------------------------------------------------------------------------------
-- DESIGN UNIT  : NoC Arke 		                                                    --
-- DESCRIPTION  :                                                                   --
-- AUTHOR       : Everton Alceu Carara, Iaçanã Ianiski Weber & Michel Duarte        --
-- CREATED      : Apr 8th, 2015                                                     --
-- VERSION      : v1.0                                                              --
-- HISTORY      : Version 1.0 - Jan 22th, 2019                                      --
--------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.Arke_pkg.all;

entity NoC is
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        
        -- LOCAL input and output port for each node
        data_in     : in Array3D_data(0 to DIM_X-1, 0 to DIM_Y-1, 0 to DIM_Z-1);
        control_in  : in Array3D_control(0 to DIM_X-1, 0 to DIM_Y-1, 0 to DIM_Z-1);
        
        data_out    : out Array3D_data(0 to DIM_X-1, 0 to DIM_Y-1, 0 to DIM_Z-1);
        control_out : out Array3D_control(0 to DIM_X-1, 0 to DIM_Y-1, 0 to DIM_Z-1)
    );
end NoC;

architecture structural of NoC is
    
    -- Router component declaration
    component Router is
    generic(address: std_logic_vector(DATA_WIDTH-1 downto 0));
        port(
            clk            : in std_logic;
            rst            : in std_logic;
            data_in        : in Array1D_data(0 to PORTS-1);
            control_in     : in Array1D_control(0 to PORTS-1);
            data_out       : out Array1D_data(0 to PORTS-1);
            control_out    : out Array1D_control(0 to PORTS-1)
        );
    end component;
    
    -- Connections between routers inputs/outputs
    signal data : Array4D_data(0 to DIM_X-1, 0 to DIM_Y-1, 0 to DIM_Z-1, 0 to 6);
    signal control : array4D_control(0 to DIM_X-1, 0 to DIM_Y-1, 0 to DIM_Z-1, 0 to 6);
    
    -- Signals for unused ports
    signal data_dump : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal control_dump : std_logic_vector(CONTROL_WIDTH-1 downto 0);
    
begin
    data_dump <= (others => '0');
    control_dump <= (others => '0');
    
    assert (DIM_X > 1)
    report "DIM_X in NoC_Package must be greater than one"
    severity FAILURE;
    
    assert (DIM_Y > 1)
    report "DIM_Y in NoC_Package must be greater than one"
    severity FAILURE;
    
    -- Loop to generate a 2D mesh NoC
    MESH_2D: if (DIM_X>1 AND DIM_Y>1 AND DIM_Z=1) generate
        Z_COORD: for z in 0 to (DIM_Z-1) generate
            Y_COORD: for y in 0 to (DIM_Y-1) generate
                X_COORD: for x in 0 to (DIM_X-1) generate
                    CENTRAL_ROUTER: if ((x-1>=0) AND (x+1<DIM_X) AND (y-1>=0) AND (y+1<DIM_Y)) generate
                        ROUTER_XYZ: Router 
                            generic map(address => Address(x,y,z))
                            port map(
                            clk                 => clk,
                            rst                 => rst,
                            data_in(LOCAL)      => data_in(x,y,z),
                            data_in(EAST)       => data(x+1,y,z,WEST),
                            data_in(SOUTH)      => data(x,y-1,z,NORTH),
                            data_in(WEST)       => data(x-1,y,z,EAST),
                            data_in(NORTH)      => data(x,y+1,z,SOUTH),
                            control_in(LOCAL)   => control_in(x,y,z),
                            control_in(EAST)    => control(x+1,y,z,WEST),
                            control_in(SOUTH)   => control(x,y-1,z,NORTH),
                            control_in(WEST)    => control(x-1,y,z,EAST),
                            control_in(NORTH)   => control(x,y+1,z,SOUTH),
                            data_out(LOCAL)     => data_out(x,y,z),
                            data_out(EAST)      => data(x,y,z,EAST),
                            data_out(SOUTH)     => data(x,y,z,SOUTH),
                            data_out(WEST)      => data(x,y,z,WEST),
                            data_out(NORTH)     => data(x,y,z,NORTH),
                            control_out(LOCAL)  => control_out(x,y,z),
                            control_out(EAST)   => control(x,y,z,EAST),
                            control_out(SOUTH)  => control(x,y,z,SOUTH),
                            control_out(WEST)   => control(x,y,z,WEST),
                            control_out(NORTH)  => control(x,y,z,NORTH)
                        );
                    end generate CENTRAL_ROUTER;
                    
                    BOTTON_LEFT_CORNER: if ((x=0) AND (y=0)) generate
                        ROUTER_XYZ: Router
                            generic map(address => Address(x,y,z))
                            port map(
                            clk                 => clk,
                            rst                 => rst,
                            data_in(LOCAL)      => data_in(x,y,z),
                            data_in(EAST)       => data(x+1,y,z,WEST),
                            data_in(SOUTH)      => data_dump,
                            data_in(WEST)       => data_dump,
                            data_in(NORTH)      => data(x,y+1,z,SOUTH),
                            control_in(LOCAL)   => control_in(x,y,z),
                            control_in(EAST)    => control(x+1,y,z,WEST),
                            control_in(SOUTH)   => control_dump,
                            control_in(WEST)    => control_dump,
                            control_in(NORTH)   => control(x,y+1,z,SOUTH),
                            data_out(LOCAL)     => data_out(x,y,z),
                            data_out(EAST)      => data(x,y,z,EAST),
                            data_out(SOUTH)     => data(x,y,z,SOUTH),
                            data_out(WEST)      => data(x,y,z,WEST),
                            data_out(NORTH)     => data(x,y,z,NORTH),
                            control_out(LOCAL)  => control_out(x,y,z),
                            control_out(EAST)   => control(x,y,z,EAST),
                            control_out(SOUTH)  => control(x,y,z,SOUTH),
                            control_out(WEST)   => control(x,y,z,WEST),
                            control_out(NORTH)  => control(x,y,z,NORTH)
                        );
                    end generate BOTTON_LEFT_CORNER;
                    
                    BOTTON_RIGHT_CORNER: if ((x=DIM_X-1) AND (y=0)) generate
                        ROUTER_XYZ: Router
                            generic map(address => Address(x,y,z))
                            port map(
                            clk                 => clk,
                            rst                 => rst,
                            data_in(LOCAL)      => data_in(x,y,z),
                            data_in(EAST)       => data_dump,
                            data_in(SOUTH)      => data_dump,
                            data_in(WEST)       => data(x-1,y,z,EAST),
                            data_in(NORTH)      => data(x,y+1,z,SOUTH),
                            control_in(LOCAL)   => control_in(x,y,z),
                            control_in(EAST)    => control_dump,
                            control_in(SOUTH)   => control_dump,
                            control_in(WEST)    => control(x-1,y,z,EAST),
                            control_in(NORTH)   => control(x,y+1,z,SOUTH),
                            data_out(LOCAL)     => data_out(x,y,z),
                            data_out(EAST)      => data(x,y,z,EAST),
                            data_out(SOUTH)     => data(x,y,z,SOUTH),
                            data_out(WEST)      => data(x,y,z,WEST),
                            data_out(NORTH)     => data(x,y,z,NORTH),
                            control_out(LOCAL)  => control_out(x,y,z),
                            control_out(EAST)   => control(x,y,z,EAST),
                            control_out(SOUTH)  => control(x,y,z,SOUTH),
                            control_out(WEST)   => control(x,y,z,WEST),
                            control_out(NORTH)  => control(x,y,z,NORTH)
                        );
                    end generate BOTTON_RIGHT_CORNER;
                    
                    TOP_LEFT_CORNER: if ((x=0) AND (y=DIM_Y-1)) generate
                        ROUTER_XYZ: Router
                            generic map(address => Address(x,y,z))
                            port map(
                            clk                 => clk,
                            rst                 => rst,
                            data_in(LOCAL)      => data_in(x,y,z),
                            data_in(EAST)       => data(x+1,y,z,WEST),
                            data_in(SOUTH)      => data(x,y-1,z,NORTH),
                            data_in(WEST)       => data_dump,
                            data_in(NORTH)      => data_dump,
                            control_in(LOCAL)   => control_in(x,y,z),
                            control_in(EAST)    => control(x+1,y,z,WEST),
                            control_in(SOUTH)   => control(x,y-1,z,NORTH),
                            control_in(WEST)    => control_dump,
                            control_in(NORTH)   => control_dump,
                            data_out(LOCAL)     => data_out(x,y,z),
                            data_out(EAST)      => data(x,y,z,EAST),
                            data_out(SOUTH)     => data(x,y,z,SOUTH),
                            data_out(WEST)      => data(x,y,z,WEST),
                            data_out(NORTH)     => data(x,y,z,NORTH),
                            control_out(LOCAL)  => control_out(x,y,z),
                            control_out(EAST)   => control(x,y,z,EAST),
                            control_out(SOUTH)  => control(x,y,z,SOUTH),
                            control_out(WEST)   => control(x,y,z,WEST),
                            control_out(NORTH)  => control(x,y,z,NORTH)
                        );
                    end generate TOP_LEFT_CORNER;
                    
                    TOP_RIGHT_CORNER: if ((x=DIM_X-1) AND (y=DIM_Y-1)) generate
                        ROUTER_XYZ: Router
                            generic map(address => Address(x,y,z))
                            port map(
                            clk                 => clk,
                            rst                 => rst,
                            data_in(LOCAL)      => data_in(x,y,z),
                            data_in(EAST)       => data_dump,
                            data_in(SOUTH)      => data(x,y-1,z,NORTH),
                            data_in(WEST)       => data(x-1,y,z,EAST),
                            data_in(NORTH)      => data_dump,
                            control_in(LOCAL)   => control_in(x,y,z),
                            control_in(EAST)    => control_dump,
                            control_in(SOUTH)   => control(x,y-1,z,NORTH),
                            control_in(WEST)    => control(x-1,y,z,EAST),
                            control_in(NORTH)   => control_dump,
                            data_out(LOCAL)     => data_out(x,y,z),
                            data_out(EAST)      => data(x,y,z,EAST),
                            data_out(SOUTH)     => data(x,y,z,SOUTH),
                            data_out(WEST)      => data(x,y,z,WEST),
                            data_out(NORTH)     => data(x,y,z,NORTH),
                            control_out(LOCAL)  => control_out(x,y,z),
                            control_out(EAST)   => control(x,y,z,EAST),
                            control_out(SOUTH)  => control(x,y,z,SOUTH),
                            control_out(WEST)   => control(x,y,z,WEST),
                            control_out(NORTH)  => control(x,y,z,NORTH)
                        );
                    end generate TOP_RIGHT_CORNER;
                    
                    BOTTON_BORDER: if ((x>0) AND (x<DIM_X-1) AND (y=0)) generate
                        ROUTER_XYZ: Router
                            generic map(address => Address(x,y,z))
                            port map(
                            clk                 => clk,
                            rst                 => rst,
                            data_in(LOCAL)      => data_in(x,y,z),
                            data_in(EAST)       => data(x+1,y,z,WEST),
                            data_in(SOUTH)      => data_dump,
                            data_in(WEST)       => data(x-1,y,z,EAST),
                            data_in(NORTH)      => data(x,y+1,z,SOUTH),
                            control_in(LOCAL)   => control_in(x,y,z),
                            control_in(EAST)    => control(x+1,y,z,WEST),
                            control_in(SOUTH)   => control_dump,
                            control_in(WEST)    => control(x-1,y,z,EAST),
                            control_in(NORTH)   => control(x,y+1,z,SOUTH),
                            data_out(LOCAL)     => data_out(x,y,z),
                            data_out(EAST)      => data(x,y,z,EAST),
                            data_out(SOUTH)     => data(x,y,z,SOUTH),
                            data_out(WEST)      => data(x,y,z,WEST),
                            data_out(NORTH)     => data(x,y,z,NORTH),
                            control_out(LOCAL)  => control_out(x,y,z),
                            control_out(EAST)   => control(x,y,z,EAST),
                            control_out(SOUTH)  => control(x,y,z,SOUTH),
                            control_out(WEST)   => control(x,y,z,WEST),
                            control_out(NORTH)  => control(x,y,z,NORTH)
                        );
                    end generate BOTTON_BORDER;
                    
                    LEFT_BORDER: if ((x=0) AND (y>0) AND (y<DIM_Y-1)) generate
                        ROUTER_XYZ: Router
                            generic map(address => Address(x,y,z))
                            port map(
                            clk                 => clk,
                            rst                 => rst,
                            data_in(LOCAL)      => data_in(x,y,z),
                            data_in(EAST)       => data(x+1,y,z,WEST),
                            data_in(SOUTH)      => data(x,y-1,z,NORTH),
                            data_in(WEST)       => data_dump,
                            data_in(NORTH)      => data(x,y+1,z,SOUTH),
                            control_in(LOCAL)   => control_in(x,y,z),
                            control_in(EAST)    => control(x+1,y,z,WEST),
                            control_in(SOUTH)   => control(x,y-1,z,NORTH),
                            control_in(WEST)    => control_dump,
                            control_in(NORTH)   => control(x,y+1,z,SOUTH),
                            data_out(LOCAL)     => data_out(x,y,z),
                            data_out(EAST)      => data(x,y,z,EAST),
                            data_out(SOUTH)     => data(x,y,z,SOUTH),
                            data_out(WEST)      => data(x,y,z,WEST),
                            data_out(NORTH)     => data(x,y,z,NORTH),
                            control_out(LOCAL)  => control_out(x,y,z),
                            control_out(EAST)   => control(x,y,z,EAST),
                            control_out(SOUTH)  => control(x,y,z,SOUTH),
                            control_out(WEST)   => control(x,y,z,WEST),
                            control_out(NORTH)  => control(x,y,z,NORTH)
                        );
                    end generate LEFT_BORDER;
                    
                    TOP_BORDER: if ((x>0) AND (x<DIM_X-1) AND (y=DIM_Y-1)) generate
                        ROUTER_XYZ: Router
                            generic map(address => Address(x,y,z))
                            port map(
                            clk                 => clk,
                            rst                 => rst,
                            data_in(LOCAL)      => data_in(x,y,z),
                            data_in(EAST)       => data(x+1,y,z,WEST),
                            data_in(SOUTH)      => data(x,y-1,z,NORTH),
                            data_in(WEST)       => data(x-1,y,z,EAST),
                            data_in(NORTH)      => data_dump,
                            control_in(LOCAL)   => control_in(x,y,z),
                            control_in(EAST)    => control(x+1,y,z,WEST),
                            control_in(SOUTH)   => control(x,y-1,z,NORTH),
                            control_in(WEST)    => control(x-1,y,z,EAST),
                            control_in(NORTH)   => control_dump,
                            data_out(LOCAL)     => data_out(x,y,z),
                            data_out(EAST)      => data(x,y,z,EAST),
                            data_out(SOUTH)     => data(x,y,z,SOUTH),
                            data_out(WEST)      => data(x,y,z,WEST),
                            data_out(NORTH)     => data(x,y,z,NORTH),
                            control_out(LOCAL)  => control_out(x,y,z),
                            control_out(EAST)   => control(x,y,z,EAST),
                            control_out(SOUTH)  => control(x,y,z,SOUTH),
                            control_out(WEST)   => control(x,y,z,WEST),
                            control_out(NORTH)  => control(x,y,z,NORTH)
                        );
                    end generate TOP_BORDER;
                    
                    RIGHT_BORDER: if ((x=DIM_X-1) AND (y>0) AND (y<DIM_Y-1)) generate
                        ROUTER_XYZ: Router
                            generic map(address => Address(x,y,z))
                            port map(
                            clk                 => clk,
                            rst                 => rst,
                            data_in(LOCAL)      => data_in(x,y,z),
                            data_in(EAST)       => data_dump,
                            data_in(SOUTH)      => data(x,y-1,z,NORTH),
                            data_in(WEST)       => data(x-1,y,z,EAST),
                            data_in(NORTH)      => data(x,y+1,z,SOUTH),
                            control_in(LOCAL)   => control_in(x,y,z),
                            control_in(EAST)    => control_dump,
                            control_in(SOUTH)   => control(x,y-1,z,NORTH),
                            control_in(WEST)    => control(x-1,y,z,EAST),
                            control_in(NORTH)   => control(x,y+1,z,SOUTH),
                            data_out(LOCAL)     => data_out(x,y,z),
                            data_out(EAST)      => data(x,y,z,EAST),
                            data_out(SOUTH)     => data(x,y,z,SOUTH),
                            data_out(WEST)      => data(x,y,z,WEST),
                            data_out(NORTH)     => data(x,y,z,NORTH),
                            control_out(LOCAL)  => control_out(x,y,z),
                            control_out(EAST)   => control(x,y,z,EAST),
                            control_out(SOUTH)  => control(x,y,z,SOUTH),
                            control_out(WEST)   => control(x,y,z,WEST),
                            control_out(NORTH)  => control(x,y,z,NORTH)
                        );
                    end generate RIGHT_BORDER;

                end generate X_COORD;
            end generate Y_COORD;
        end generate Z_COORD;
    end generate MESH_2D;
    
    
    
    
    ---- Loop to generate a 3D mesh NoC
    --MESH_3D: if (DIM_X>1 AND DIM_Y>1 AND DIM_Z>1) generate
    --    Z_COORD: for z in 0 to (DIM_Z-1) generate
    --        Y_COORD: for y in 0 to (DIM_Y-1) generate
    --            X_COORD: for x in 0 to (DIM_X-1) generate
    --        
    --                -- Nodes connections according to their position inside the cube-shaped NoC            
    --                CENTRAL_ROUTER: if ((x-1>=0) AND (x+1<DIM_X) AND (y-1>=0) AND (y+1<DIM_Y) AND (z-1>=0) AND (z+1<DIM_Z)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate CENTRAL_ROUTER;
    --                
    --                LEFT_FRONT_BOTTOM_CORNER: if ((x=0) AND (y=0) AND (z=0)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data_dump,
    --                        data_in(WEST)       => data_dump,
    --                        --data_in(WEST)       => x"1234",
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data_dump,
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control_dump,
    --                        control_in(WEST)    => control_dump,
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control_dump,
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate LEFT_FRONT_BOTTOM_CORNER;
    --                
    --                RIGHT_FRONT_BOTTOM_CORNER: if ((x=DIM_X-1) AND (y=0) AND (z=0)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data_dump,
    --                        data_in(SOUTH)      => data_dump,
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data_dump,
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control_dump,
    --                        control_in(SOUTH)   => control_dump,
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control_dump,
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate RIGHT_FRONT_BOTTOM_CORNER;
    --                
    --                LEFT_BACK_BOTTOM_CORNER: if ((x=0) AND (y=DIM_Y-1) AND (z=0)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data_dump,
    --                        data_in(NORTH)      => data_dump,
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data_dump,
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control_dump,
    --                        control_in(NORTH)   => control_dump,
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control_dump,
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate LEFT_BACK_BOTTOM_CORNER;
    --                
    --                RIGHT_BACK_BOTTOM_CORNER: if ((x=DIM_X-1) AND (y=DIM_Y-1) AND (z=0)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data_dump,
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data_dump,
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data_dump,
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control_dump,
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control_dump,
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control_dump,
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate RIGHT_BACK_BOTTOM_CORNER;
    --                
    --                LEFT_FRONT_TOP_CORNER: if ((x=0) AND (y=0) AND (z=DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data_dump,
    --                        data_in(WEST)       => data_dump,
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data_dump,
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control_dump,
    --                        control_in(WEST)    => control_dump,
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control_dump,
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate LEFT_FRONT_TOP_CORNER;
    --                
    --                RIGHT_FRONT_TOP_CORNER: if ((x=DIM_X-1) AND (y=0) AND (z=DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data_dump,
    --                        data_in(SOUTH)      => data_dump,
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data_dump,
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control_dump,
    --                        control_in(SOUTH)   => control_dump,
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control_dump,
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate RIGHT_FRONT_TOP_CORNER;
    --                
    --                LEFT_BACK_TOP_CORNER: if ((x=0) AND (y=DIM_Y-1) AND (z=DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data_dump,
    --                        data_in(NORTH)      => data_dump,
    --                        data_in(UP)         => data_dump,
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control_dump,
    --                        control_in(NORTH)   => control_dump,
    --                        control_in(UP)      => control_dump,
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate LEFT_BACK_TOP_CORNER;
    --                
    --                RIGHT_BACK_TOP_CORNER: if ((x=DIM_X-1) AND (y=DIM_Y-1) AND (z=DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data_dump,
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data_dump,
    --                        data_in(UP)         => data_dump,
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control_dump,
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control_dump,
    --                        control_in(UP)      => control_dump,
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP), -- altas aventuras
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate RIGHT_BACK_TOP_CORNER;
    --                
    --                FRONT_BOTTOM_BORDER: if ((x>0) AND (x<DIM_X-1) AND (y=0) AND (z=0)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data_dump,
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data_dump,
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control_dump,
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control_dump,
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate FRONT_BOTTOM_BORDER;
    --                
    --                LEFT_BOTTOM_BORDER: if ((x=0) AND (y>0) AND (y<DIM_Y-1) AND (z=0)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data_dump,
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data_dump,
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control_dump,
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control_dump,
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate LEFT_BOTTOM_BORDER;
    --                
    --                BACK_BOTTOM_BORDER: if ((x>0) AND (x<DIM_X-1) AND (y=DIM_Y-1) AND (z=0)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data_dump,
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data_dump,
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control_dump,
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control_dump,
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate BACK_BOTTOM_BORDER;
    --                
    --                RIGHT_BOTTOM_BORDER: if ((x=DIM_X-1) AND (y>0) AND (y<DIM_Y-1) AND (z=0)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data_dump,
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data_dump,
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control_dump,
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control_dump,
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate RIGHT_BOTTOM_BORDER;
    --                
    --                FRONT_TOP_BORDER: if ((x>0) AND (x<DIM_X-1) AND (y=0) AND (z=DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data_dump,
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data_dump,
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control_dump,
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control_dump,
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate FRONT_TOP_BORDER;
    --                
    --                LEFT_TOP_BORDER: if ((x=0) AND (y>0) AND (y<DIM_Y-1) AND (z=DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data_dump,
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data_dump,
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control_dump,
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control_dump,
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate LEFT_TOP_BORDER;
    --                
    --                BACK_TOP_BORDER: if ((x>0) AND (x<DIM_X-1) AND (y=DIM_Y-1) AND (z=DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data_dump,
    --                        data_in(UP)         => data_dump,
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control_dump,
    --                        control_in(UP)      => control_dump,
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate BACK_TOP_BORDER;
    --                
    --                RIGHT_TOP_BORDER: if ((x=DIM_X-1) AND (y>0) AND (y<DIM_Y-1) AND (z=DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data_dump,
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data_dump,
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control_dump,
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control_dump,
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate RIGHT_TOP_BORDER;
    --                
    --                LEFT_FRONT_BORDER: if ((x=0) AND (y=0) AND (z>0) AND (z<DIM_Z-1)) generate
    --                    gROUT: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data_dump,
    --                        data_in(WEST)       => data_dump,
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control_dump,
    --                        control_in(WEST)    => control_dump,
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate LEFT_FRONT_BORDER;
    --                
    --                RIGHT_FRONT_BORDER: if ((x=DIM_X-1) AND (y=0) AND (z>0) AND (z<DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data_dump,
    --                        data_in(SOUTH)      => data_dump,
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control_dump,
    --                        control_in(SOUTH)   => control_dump,
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate RIGHT_FRONT_BORDER;
    --                
    --                LEFT_BACK_BORDER: if ((x=0) AND (y=DIM_Y-1) AND (z>0) AND (z<DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data_dump,
    --                        data_in(NORTH)      => data_dump,
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control_dump,
    --                        control_in(NORTH)   => control_dump,
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate LEFT_BACK_BORDER;
    --                
    --                RIGHT_BACK_BORDER: if ((x=DIM_X-1) AND (y=DIM_Y-1) AND (z>0) AND (z<DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data_dump,
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data_dump,
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control_dump,
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control_dump,
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate RIGHT_BACK_BORDER;
    --                
    --                FRONT_FACE: if ((x>0) AND (x<DIM_X-1) AND (y=0) AND (z>0) AND (z<DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data_dump,
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control_dump,
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate FRONT_FACE;
    --                
    --                LEFT_FACE: if ((x=0) AND (y>0) AND (y<DIM_Y-1) AND (z>0) AND (z<DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data_dump,
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control_dump,
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate LEFT_FACE;
    --                
    --                RIGHT_FACE: if ((x>0) AND (x<DIM_X-1) AND (y=DIM_Y-1) AND (z>0) AND (z<DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data_dump,
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control_dump,
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate RIGHT_FACE;
    --                
    --                BACK_FACE: if ((x=DIM_X-1) AND (y>0) AND (y<DIM_Y-1) AND (z>0) AND (z<DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data_dump,
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control_dump,
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate BACK_FACE;
    --                
    --                BOTTOM_FACE: if ((x>0) AND (x<DIM_X-1) AND (y>0) AND (y<DIM_Y-1) AND (z=0)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data(x,y,z+1,DOWN),
    --                        data_in(DOWN)       => data_dump,
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control(x,y,z+1,DOWN),
    --                        control_in(DOWN)    => control_dump,
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate BOTTOM_FACE;
    --                
    --                TOP_FACE: if ((x>0) AND (x<DIM_X-1) AND (y>0) AND (y<DIM_Y-1) AND (z=DIM_Z-1)) generate
    --                    ROUTER_XYZ: Router
    --                        generic map(address => Address(x,y,z))
    --                        port map(
    --                        clk                 => clk,
    --                        rst                 => rst,
    --                        data_in(LOCAL)      => data_in(x,y,z),
    --                        data_in(EAST)       => data(x+1,y,z,WEST),
    --                        data_in(SOUTH)      => data(x,y-1,z,NORTH),
    --                        data_in(WEST)       => data(x-1,y,z,EAST),
    --                        data_in(NORTH)      => data(x,y+1,z,SOUTH),
    --                        data_in(UP)         => data_dump,
    --                        data_in(DOWN)       => data(x,y,z-1,UP),
    --                        control_in(LOCAL)   => control_in(x,y,z),
    --                        control_in(EAST)    => control(x+1,y,z,WEST),
    --                        control_in(SOUTH)   => control(x,y-1,z,NORTH),
    --                        control_in(WEST)    => control(x-1,y,z,EAST),
    --                        control_in(NORTH)   => control(x,y+1,z,SOUTH),
    --                        control_in(UP)      => control_dump,
    --                        control_in(DOWN)    => control(x,y,z-1,UP),
    --                        data_out(LOCAL)     => data_out(x,y,z),
    --                        data_out(EAST)      => data(x,y,z,EAST),
    --                        data_out(SOUTH)     => data(x,y,z,SOUTH),
    --                        data_out(WEST)      => data(x,y,z,WEST),
    --                        data_out(NORTH)     => data(x,y,z,NORTH),
    --                        data_out(UP)        => data(x,y,z,UP),
    --                        data_out(DOWN)      => data(x,y,z,DOWN),
    --                        control_out(LOCAL)  => control_out(x,y,z),
    --                        control_out(EAST)   => control(x,y,z,EAST),
    --                        control_out(SOUTH)  => control(x,y,z,SOUTH),
    --                        control_out(WEST)   => control(x,y,z,WEST),
    --                        control_out(NORTH)  => control(x,y,z,NORTH),
    --                        control_out(UP)     => control(x,y,z,UP),
    --                        control_out(DOWN)   => control(x,y,z,DOWN)
    --                    );
    --                end generate TOP_FACE;
    --                
    --            end generate X_COORD;
    --        end generate Y_COORD;
    --    end generate Z_COORD;
    --end generate MESH_3D;
end structural;