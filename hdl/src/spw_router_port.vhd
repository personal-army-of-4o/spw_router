library ieee;
use ieee.std_logic_1164.all;


entity spw_router_port is
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
end entity;


architecture v1 of spw_router_port is

    component spw_router_rx_pipeline
        port (
            iClk: in std_logic;
            iReset: in std_logic;

            iTimeout_ticks: in std_logic_vector;
            iLimit: in std_logic_vector;
            oRequest_mux: out std_logic;
            oPath: out std_logic_vector (7 downto 0);
            iGranted: in std_logic;
            iDiscard: in std_logic;

            iValid: in std_logic;
            iData: in std_logic_vector (8 downto 0);
            oAck: out std_logic;

            oValid: out std_logic;
            oData: out std_logic_vector (8 downto 0);
            iAck: in std_logic
        );
    end component;

    component spw_router_tx_fsm
        port (
            iClk: in std_logic;
            iReset: in std_logic;

            -- mux control
            iMux_en: in std_logic;
            iMux_onehot: in std_logic_vector; -- len = port num (pn)

            -- to data source
            iValid: in std_logic_vector; -- len = pn
            iData: in std_logic_vector; -- len = pn*9
            oAck: out std_logic_vector; -- len = pn

            -- to data sink
            oValid: out std_logic;
            oData: out std_logic_vector (8 downto 0);
            iAck: in std_logic
        );
    end component;

begin

    rx: spw_router_rx_pipeline
        port map (
            iClk => iClk,
            iReset => iReset,

            iTimeout_ticks => iTimeout_ticks,
            iLimit => iLimit,
            oRequest_mux => oRequest_mux,
            oPath => oPath,
            iGranted => iGranted,
            iDiscard => iDiscard,

            iValid => iSpw_valid,
            iData => iSpw_data,
            oAck => oSpw_ack,

            oValid => oMux_valid,
            oData => oMux_data,
            iAck => iMux_ack
        );

    tx: spw_router_tx_fsm
        port map (
            iClk => iClk,
            iReset => iReset,

            -- mux control
            iMux_en => iMux_en,
            iMux_onehot => iMux_onehot,

            -- to data source
            iValid => iMux_valid,
            iData => iMux_data,
            oAck => oMux_ack,

            -- to data sink
            oValid => oSpw_valid,
            oData => oSpw_data,
            iAck => iSpw_ack
        );

 end v1;