library ieee;
use ieee.std_logic_1164.all;
library work;
use work.config.all;


entity spw_router is
    port (
        iClk: in std_logic;
        iReset: in std_logic;

        iValid: in std_logic_vector (cPort_num-2 downto 0);
        iData: in std_logic_vector ((cPort_num-1)*9-1 downto 0);
        oAck: out std_logic_vector (cPort_num-2 downto 0);

        oValid: out std_logic_vector (cPort_num-2 downto 0);
        oData: out std_logic_vector ((cPort_num-1)*9-1 downto 0);
        iAck: in std_logic_vector (cPort_num-2 downto 0)
    );
end entity;

architecture v1 of spw_router is

    constant cPn: natural := cPort_num;

    component spw_router_arbiter
        port (
            iClk: in std_logic;
            iReset: in std_logic;

            oTimeout_ticks: out std_logic_vector; -- len = port_num*timeout_width
            oLimit: out std_logic_vector; -- len = port_num*limit_width
            iRequest_mux: in std_logic_vector; -- len = port_num
            iPath: in std_logic_vector; -- len = port_num*8
            oGranted: out std_logic_vector; -- len = port_num
            oDiscard: out std_logic_vector; -- len = port_num
            oMux_en: out std_logic_vector; -- len = port_num
            oMux_onehot: out std_logic_vector; -- len = port_num*port_num

            -- internal port
            iValid: in std_logic;
            iData: in std_logic_vector (8 downto 0);
            oAck: out std_logic;

            oValid: out std_logic;
            oData: out std_logic_vector (8 downto 0);
            iAck: in std_logic
        );
    end component;

    component spw_router_interconnect
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
    end component;

    signal sValid_i: std_logic_vector (cPn-1 downto 0);
    signal sData_i: std_logic_vector (cPn*9-1 downto 0);
    signal sAck_i: std_logic_vector (cPn-1 downto 0);
    signal sValid_o: std_logic_vector (cPn-1 downto 0);
    signal sData_o: std_logic_vector (cPn*9-1 downto 0);
    signal sAck_o: std_logic_vector (cPn-1 downto 0);

    signal sTimeout_ticks: std_logic_vector (cTimeout_reg_width*cPn-1 downto 0);
    signal sLimit: std_logic_vector (cLimit_reg_width*cPn-1 downto 0);
    signal sRequest_mux: std_logic_vector (cPn-1 downto 0);
    signal sPath: std_logic_vector (cPn*8-1 downto 0);
    signal sGranted: std_logic_vector (cPn-1 downto 0);
    signal sDiscard: std_logic_vector (cPn-1 downto 0);
    signal sMux_en: std_logic_vector (cPn-1 downto 0);
    signal sMux_onehot: std_logic_vector (cPn*cPn-1 downto 0);

begin

    assert cPn > 1
        report "a router with 0 external ports makes no sense"
        severity failure;

    assert iData'length = (cPn-1)*9
        report "port width error"
        severity failure;

    assert oAck'length = cPn-1
        report "port width error"
        severity failure;

    assert oValid'length = cPn-1
        report "port width error"
        severity failure;

    assert oData'length = (cPn-1)*9
        report "port width error"
        severity failure;

    assert iAck'length = cPn-1
        report "port width error"
        severity failure;

    -- external ports
    sValid_i (cPn-1 downto 1) <= iValid;
    sData_i (cPn*9-1 downto 9) <= iData;
    oAck <= sAck_o (cPn-1 downto 1);
    oValid <= sValid_o (cPn-1 downto 1);
    oData <= sData_o (cPn*9-1 downto 9);
    sAck_i (cPn-1 downto 1) <= iAck;

    mux: spw_router_interconnect
        port map (
            iClk => iClk,
            iReset => iReset,

            iTimeout_ticks => sTimeout_ticks,
            iLimit => sLimit,
            oRequest_mux => sRequest_mux,
            oPath => sPath,
            iGranted => sGranted,
            iDiscard => sDiscard,
            iMux_en => sMux_en,
            iMux_onehot => sMux_onehot,

            iValid => sValid_i,
            iData => sData_i,
            oAck => sAck_o,

            oValid => sValid_o,
            oData => sData_o,
            iAck => sAck_i
        );

    arbiter: spw_router_arbiter
        port map (
            iClk => iClk,
            iReset => iReset,

            oTimeout_ticks => sTimeout_ticks,
            oLimit => sLimit,
            iRequest_mux => sRequest_mux,
            iPath => sPath,
            oGranted => sGranted,
            oDiscard => sDiscard,
            oMux_en => sMux_en,
            oMux_onehot => sMux_onehot,

            iValid => sValid_o (0),
            iData => sData_o (8 downto 0),
            oAck => sAck_i (0),

            oValid => sValid_i (0),
            oData => sData_i (8 downto 0),
            iAck => sAck_i (0)
        );

end v1;
