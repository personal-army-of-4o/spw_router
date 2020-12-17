library ieee;
use ieee.std_logic_1164.all;


entity spw_router_interconnect is
    port (
        iClk: in std_logic;
        iReset: in std_logic;

        iTimeout_ticks: in std_logic_vector;
        iLimit: in std_logic_vector;
        oRequest_mux: out std_logic_vector;
        oPath: out std_logic_vector;
        iGranted: in std_logic_vector;
        iDiscard: in std_logic_vector;
        iMux_en: in std_logic_vector;
        iMux_onehot: in std_logic_vector; -- len = port num (pn)

        iValid: in std_logic_vector; -- len = port num(pn)
        iData: in std_logic_vector; -- len = pn*9
        oAck: out std_logic_vector; -- len = pn

        oValid: out std_logic_vector; -- len = pn
        oData: out std_logic_vector; -- len = pn*9
        iAck: in std_logic_vector -- len = pn
    );
end entity;

architecture v1 of spw_router_interconnect is

    constant cPn: natural := iValid'length;
    constant cTw: natural := iTimeout_ticks'length/cPn;
    constant cLw: natural := iLimit'length/cPn;

    component spw_router_mux
        port (
            iValid: in std_logic_vector; -- len = port num(pn)
            iData: in std_logic_vector; -- len = pn*9
            oAck: out std_logic_vector; -- len = pn

            oValid: out std_logic_vector; -- len = pn*pn
            oData: out std_logic_vector; -- len = pn*pn*9
            iAck: in std_logic_vector -- len = pn*pn
        );
    end component;

    component spw_router_port
        port (
            iClk: in std_logic;
            iReset: in std_logic;

            iTimeout_ticks: in std_logic_vector;
            iLimit: in std_logic_vector;
            oRequest_mux: out std_logic;
            oPath: out std_logic_vector (7 downto 0);
            iGranted: in std_logic;
            iDiscard: in std_logic;

            -- mux control
            iMux_en: in std_logic;
            iMux_onehot: in std_logic_vector; -- len = port num (pn)

            -- to spw
            iSpw_valid: in std_logic;
            iSpw_data: in std_logic_vector (8 downto 0);
            oSpw_ack: out std_logic;

            oSpw_valid: out std_logic;
            oSpw_data: out std_logic_vector (8 downto 0);
            iSpw_ack: in std_logic;

            -- to mux matrix
            iMux_valid: in std_logic_vector; -- len = pn
            iMux_data: in std_logic_vector; -- len = pn*9
            oMux_ack: out std_logic_vector; -- len = pn

            oMux_valid: out std_logic;
            oMux_data: out std_logic_vector (8 downto 0);
            iMux_ack: in std_logic
        );
    end component;

    signal sRx_valid: std_logic_vector (cPn-1 downto 0);
    signal sRx_data: std_logic_vector (cPn*9-1 downto 0);
    signal sRx_ack: std_logic_vector (cPn-1 downto 0);
    signal sTx_valid: std_logic_vector (cPn*cPn-1 downto 0);
    signal sTx_data: std_logic_vector (cPn*cPn*9-1 downto 0);
    signal sTx_ack: std_logic_vector (cPn*cPn-1 downto 0);

begin

    assert iData'length = (cPn)*9
        report "port width error"
        severity failure;

    assert oAck'length = cPn
        report "port width error"
        severity failure;

    assert oValid'length = cPn
        report "port width error"
        severity failure;

    assert oData'length = (cPn)*9
        report "port width error"
        severity failure;

    assert iAck'length = cPn
        report "port width error"
        severity failure;

    gen_ports: for i in 0 to cPn-1 generate

        a_port: spw_router_port
            port map (
                iClk => iClk,
                iReset => iClk,

                iTimeout_ticks => iTimeout_ticks ((i+1)*cTw-1 downto i*cTw),
                iLimit => iLimit ((i+1)*cLw-1 downto i*cLw),
                oRequest_mux => oRequest_mux (i),
                oPath => oPath ((i+1)*8-1 downto i*8),
                iGranted => iGranted (i),
                iDiscard => iDiscard (i),
                iMux_en => iMux_en (i),
                iMux_onehot => iMux_onehot ((i+1)*cPn-1 downto i*cPn),

                -- to spw
                iSpw_valid => iValid (i),
                iSpw_data => iData ((i+1)*9-1 downto i*9),
                oSpw_ack => oAck (i),

                oSpw_valid => oValid (i),
                oSpw_data => oData ((i+1)*9-1 downto i*9),
                iSpw_ack => iAck (i),

                -- to mux matrix
                iMux_valid => sTx_valid ((i+1)*cPn-1 downto i*cPn),
                iMux_data => sTx_data ((i+1)*9*cPn-1 downto i*9*cPn),
                oMux_ack => sTx_ack ((i+1)*cPn-1 downto i*cPn),

                oMux_valid => sRx_valid (i),
                oMux_data => sRx_data ((i+1)*9-1 downto i*9),
                iMux_ack => sRx_ack (i)
            );

    end generate;

    mux: spw_router_mux
        port map (
            iValid => sRx_valid,
            iData => sRx_data,
            oAck => sRx_ack,

            oValid => sTx_valid,
            oData => sTx_data,
            iAck => sTx_ack
        );

end v1;
