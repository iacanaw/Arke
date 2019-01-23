library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.Arke_pkg.all;

entity NetworkInterface_BiSync is 
    generic(
        DEPTH       : natural := 8;
        BUFF_WIDTH  : natural := 8
    );
    port(
        clk_IP      : in std_logic;
        clk_NoC     : in std_logic;
        rst_IP      : in std_logic;
        rst_NoC     : in std_logic;
        
        data_in_IP      : in std_logic_vector(DATA_WIDTH-1 downto 0);
        control_in_IP   : in std_logic_vector(CONTROL_WIDTH-1 downto 0);
        data_out_IP     : out std_logic_vector(DATA_WIDTH-1 downto 0);
        control_out_IP  : out std_logic_vector(CONTROL_WIDTH-1 downto 0);
        data_in_NoC     : in std_logic_vector(DATA_WIDTH-1 downto 0);
        control_in_NoC  : in std_logic_vector(CONTROL_WIDTH-1 downto 0);
        data_out_NoC    : out std_logic_vector(DATA_WIDTH-1 downto 0);
        control_out_NoC : out std_logic_vector(CONTROL_WIDTH-1 downto 0)
    );
end NetworkInterface_BiSync;

architecture structural of NetworkInterface_BiSync is
    signal full_as_stall_go, empty_as_stall_go : std_logic;
    signal data_in_IPNOC, data_out_IPNOC, data_in_NOCIP, data_out_NOCIP : std_logic_vector(DATA_WIDTH downto 0); 
    --signals between Q_IP_NOC and TALKER
    signal data_IPNOC: std_logic_vector(DATA_WIDTH-1 downto 0);
    signal eop_IPNOC: std_logic;
    signal readCtrl: std_logic;
    signal empty_IPNOC: std_logic;
    --signals between Q_NOC_IP and Listener
    signal data_NOCIP: std_logic_vector(DATA_WIDTH-1 downto 0);
    signal eop_NOCIP:  std_logic;
    signal writeCrtl:  std_logic;
    signal full:       std_logic;
    component BiSynchronous_FIFO
        generic(DEPTH: natural;
                DATA_WIDTH: natural);
        port(
            rst         : std_logic;
            clk_wr      : in std_logic;
            wr          : in std_logic;
            full        : out std_logic;
            data_in     : in std_logic_vector(DATA_WIDTH-1 downto 0);
            clk_rd      : in std_logic;
            rd          : in std_logic;
            empty       : out std_logic;
            data_out    : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;
    component Talker
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
    end component;
    component Listener 
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
    end component;
    ---------------------
    begin
        TALKERR: Talker
            port map(
                clk         => clk_NoC,
                rst         => rst_NoC,
                readCtrl    => readCtrl,
                tx_req      => control_out_NoC(TX),
                stall_ack   => control_in_NoC(STALL_GO),
                empty       => empty_IPNOC,
                data_in     => data_IPNOC,
                eop_in      => eop_IPNOC,
                data_out    => data_out_NoC,
                eop_out     => control_out_NoC(EOP)
            );
        
        IP_NOC: BiSynchronous_FIFO
            generic map(DEPTH=>DEPTH,
                        DATA_WIDTH=>BUFF_WIDTH)
            port map(
                rst         => rst_NoC,
                
                clk_wr      => clk_IP,
                wr          => control_in_IP(TX),
                full        => full_as_stall_go,
                data_in     => data_in_IPNOC,
                
                clk_rd      => clk_NoC,
                rd          => readCtrl,
                empty       => empty_IPNOC,
                data_out    => data_out_IPNOC
            );
        control_out_IP(STALL_GO) <= not full_as_stall_go;
        
        data_in_IPNOC(DATA_WIDTH) <= control_in_IP(EOP);
        data_in_IPNOC(DATA_WIDTH-1 downto 0) <= data_in_IP;
        
        eop_IPNOC <= data_out_IPNOC(DATA_WIDTH);
        data_IPNOC <= data_out_IPNOC(DATA_WIDTH-1 downto 0);
        
        
---------------------------------------------------------------------
        
        LISTENERR: Listener
            port map(
                clk         => clk_NoC,
                rst         => rst_NoC,
                writeCrtl   => writeCrtl,
                tx_req      => control_in_NoC(TX),
                stall_ack   => control_out_NoC(STALL_GO),
                full        => full,
                data_in     => data_in_NoC,
                eop_in      => control_in_NoC(EOP),
                data_out    => data_NOCIP,
                eop_out     => eop_NOCIP
            );
        
        NOC_IP: BiSynchronous_FIFO
            generic map(DEPTH=>DEPTH,
                        DATA_WIDTH=>BUFF_WIDTH)
            port map(
                rst         => rst_NoC,
                
                clk_wr      => clk_NoC,
                wr          => writeCrtl,
                full        => full,
                data_in     => data_in_NOCIP,
                
                clk_rd      => clk_IP,
                rd          => control_in_IP(STALL_GO),
                empty       => empty_as_stall_go,
                data_out    => data_out_NOCIP
            );
        -- if the queue is not empty then there is something to send to the NoC
        control_out_IP(RX) <= not empty_as_stall_go;
        
        data_in_NOCIP(DATA_WIDTH) <= eop_NOCIP;
        data_in_NOCIP(DATA_WIDTH-1 downto 0) <= data_NOCIP;
        
        control_out_IP(EOP) <= data_out_NOCIP(DATA_WIDTH);
        data_out_IP <= data_out_NOCIP(DATA_WIDTH-1 downto 0);
        
end structural;
