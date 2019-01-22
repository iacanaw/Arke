--------------------------------------------------------------------------------------
-- DESIGN UNIT  : Crossbar                                                    		--
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

entity Crossbar is
    port(   
        -- Switch Control interface
        routingTable    : in Array2D_crossbarConfig(0 to PORTS-1, 0 to PORTS-1);
        --routingTable    : in Array1D_3bits(0 to PORTS-1);
        
        -- Input buffers interface
        data_in         : in Array1D_data(0 to PORTS-1);
        control_in      : in Array1D_control(0 to PORTS-1);
        
        -- Router output ports interface
        data_out        : out Array1D_data(0 to PORTS-1);
        control_out     : out Array1D_control(0 to PORTS-1)
    );
end Crossbar;

architecture full of Crossbar is
begin

    MESH_2D : if(DIM_X>1 and DIM_Y>1 and DIM_Z=1) generate
        --DATA_OUT
        DATAOUT: for i in 0 to PORTS-1 generate
            data_out(i) <= data_in(LOCAL) when routingTable(i,LOCAL) = '1' else
                           data_in(EAST)  when routingTable(i,EAST) = '1' else
                           data_in(SOUTH) when routingTable(i,SOUTH) = '1' else
                           data_in(WEST)  when routingTable(i,WEST) = '1' else
                           data_in(NORTH);
        end generate;

        --EOP
        EOPP: for i in 0 to PORTS-1 generate
            control_out(i)(EOP) <= control_in(LOCAL)(EOP) when routingTable(i,LOCAL) = '1' else
                                   control_in(EAST)(EOP)  when routingTable(i,EAST) = '1' else
                                   control_in(SOUTH)(EOP) when routingTable(i,SOUTH) = '1' else
                                   control_in(WEST)(EOP)  when routingTable(i,WEST) = '1' else
                                   control_in(NORTH)(EOP) when routingTable(i,NORTH) = '1' else
                                   '0';
        end generate;
        
        -- RX/TX
        RXTX: for i in 0 to PORTS-1 generate
            control_out(i)(RX) <= control_in(LOCAL)(RX) when routingTable(i,LOCAL) = '1' else 
                                  control_in(EAST)(RX)  when routingTable(i,EAST) = '1' else
                                  control_in(SOUTH)(RX) when routingTable(i,SOUTH) = '1' else
                                  control_in(WEST)(RX)  when routingTable(i,WEST) = '1' else
                                  control_in(NORTH)(RX) when routingTable(i,NORTH) = '1' else
                                  '0';
        end generate;
        
        --STALL_GO
        STALLGO: for i in 0 to PORTS-1 generate
            control_out(i)(STALL_GO) <= control_in(LOCAL)(STALL_GO) when routingTable(LOCAL,i) = '1' else
                                        control_in(EAST)(STALL_GO)  when routingTable(EAST,i) = '1' else
                                        control_in(SOUTH)(STALL_GO) when routingTable(SOUTH,i) = '1' else
                                        control_in(WEST)(STALL_GO)  when routingTable(WEST,i) = '1' else
                                        control_in(NORTH)(STALL_GO) when routingTable(NORTH,i) = '1' else
                                        '0';
        end generate;
    end generate;

    MESH_3D : if(DIM_X>1 and DIM_Y>1 and DIM_Z>1) generate
        --DATA_OUT
        DATAOUT: for i in 0 to PORTS-1 generate
            data_out(i) <= data_in(LOCAL) when routingTable(i,LOCAL) = '1' else
                           data_in(EAST)  when routingTable(i,EAST) = '1' else
                           data_in(SOUTH) when routingTable(i,SOUTH) = '1' else
                           data_in(WEST)  when routingTable(i,WEST) = '1' else
                           data_in(NORTH) when routingTable(i,NORTH) = '1' else
                           data_in(UP)    when routingTable(i,UP) = '1' else
                           data_in(DOWN);
        end generate;

        -- --EOP
        EOPP: for i in 0 to PORTS-1 generate
            control_out(i)(EOP) <= control_in(LOCAL)(EOP) when routingTable(i,LOCAL) = '1' else
                                   control_in(EAST)(EOP)  when routingTable(i,EAST) = '1' else
                                   control_in(SOUTH)(EOP) when routingTable(i,SOUTH) = '1' else
                                   control_in(WEST)(EOP)  when routingTable(i,WEST) = '1' else
                                   control_in(NORTH)(EOP) when routingTable(i,NORTH) = '1' else
                                   control_in(UP)(EOP)    when routingTable(i,UP) = '1' else
                                   control_in(DOWN)(EOP)  when routingTable(i,DOWN) = '1' else
                                   '0';
        end generate;

        --RX/TX
        RXTX: for i in 0 to PORTS-1 generate
            control_out(i)(RX) <= control_in(LOCAL)(RX) when routingTable(i,LOCAL) = '1' else
                                  control_in(EAST)(RX)  when routingTable(i,EAST) = '1' else
                                  control_in(SOUTH)(RX) when routingTable(i,SOUTH) = '1' else
                                  control_in(WEST)(RX)  when routingTable(i,WEST) = '1' else
                                  control_in(NORTH)(RX) when routingTable(i,NORTH) = '1' else
                                  control_in(UP)(RX)    when routingTable(i,UP) = '1' else
                                  control_in(DOWN)(RX)  when routingTable(i,DOWN) = '1' else
                                  '0';
        end generate;

        --STALL_GO
        STALLGO: for i in 0 to PORTS-1 generate
            control_out(i)(STALL_GO) <= control_in(LOCAL)(STALL_GO) when routingTable(LOCAL,i) = '1' else
                                        control_in(EAST)(STALL_GO)  when routingTable(EAST,i) = '1' else
                                        control_in(SOUTH)(STALL_GO) when routingTable(SOUTH,i) = '1' else
                                        control_in(WEST)(STALL_GO)  when routingTable(WEST,i) = '1' else
                                        control_in(NORTH)(STALL_GO) when routingTable(NORTH,i) = '1' else
                                        control_in(UP)(STALL_GO)    when routingTable(UP,i) = '1' else
                                        control_in(DOWN)(STALL_GO)  when routingTable(DOWN,i) = '1' else
                                        '0';
        end generate;
    end generate;

end architecture;