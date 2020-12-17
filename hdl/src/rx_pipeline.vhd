library ieee;
use ieee.std_logic_1164.all;


entity rx_pipeline is
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
end entity;

architecture v1 of rx_pipeline is

	component spw_pkg_timeout
		port (
			iClk: in std_logic;
			iReset: in std_logic;

			iTimeout_ticks: in std_logic_vector;

			iValid: in std_logic;
			iData: in std_logic_vector (8 downto 0);
			oAck: out std_logic;

			oValid: out std_logic;
			oData: out std_logic_vector (8 downto 0);
			iAck: in std_logic
		);
	end component;
	
	component spw_pkg_truncator
    	port (
     	   iClk: in std_logic;
     	   iReset: in std_logic;

	        iLimit: in std_logic_vector;

 	       iValid: in std_logic;
 	       iData: in std_logic_vector (8 downto 0);
 	       oAck: out std_logic;

 	       oValid: out std_logic;
 	       oData: out std_logic_vector (8 downto 0);
 	       iAck: in std_logic
 	   );
	end component;

	entity spw_pkg_buffer is
 	   port (
 	       iClk: in std_logic;
 	       iReset: in std_logic;

 	       -- from data source
 	       iValid: in std_logic;
 	       iData: in std_logic_vector (8 downto 0);
 	       oAck: out std_logic;

 	       -- control
 	       oHandshake: out std_logic;
 	       iHandshake: in std_logic;

 	       -- to data sink
 	       oValid: out std_logic;
 	       oData: out std_logic_vector (8 downto 0);
 	       iAck: in std_logic
 	   );
	end entity;

	entity spw_router_rx_fsm is
 	   port (
 	       iClk: in std_logic;
 	       iReset: in std_logic;

 	       -- to pkg buffer
 	       iHandshake: in std_logic;
 	       oHandshake: out std_logic;

 	       -- to router control
 	       oRequest_mux: out std_logic;
 	       oPath: out std_logic_vector (7 downto 0);
 	       iGranted: in std_logic;
 	       iDiscard: in std_logic;

 	       -- to pkg buffer
 	       iValid: in std_logic;
 	       iData: in std_logic_vector (8 downto 0);
 	       oAck: out std_logic;

 	       -- to data sink
 	       oValid: out std_logic;
 	       oData: out std_logic_vector (8 downto 0);
 	       iAck: in std_logic
 	   );
	end entity;

	signal sTimeout_valid: std_logic;
	signal sTimeout_data: std_logic_vector (8 downto 0);
	signal sTimeout_ack: std_logic;

	signal sTruncator_valid: std_logic;
	signal sTruncator_data: std_logic_vector (8 downto 0);
	signal sTruncator_ack: std_logic;

	signal sBuffer_handshake_in: std_logic;
	signal sBuffer_handshake_out: std_logic;
	signal sBuffer_valid: std_logic;
	signal sBuffer_data: std_logic_vector (8 downto 0);
	signal sBuffer_ack: std_logic;

begin

	gen_timeout_detector: if iTimeout_ticks'length > 0 generate

		detect_timeout: spw_pkg_timeout
			port map (
				iClk => iClk,
				iReset => iReset,

				iTimeout_ticks => iTimeout_ticks,

				iValid => iValid,
				iData => iData,
				oAck => oAck,

				oValid => sTimeout_valid,
				oData => sTimeout_data,
				iAck => sTimeout_ack
			);
		end component;

	end generate;
	
	no_timeout_detector: if iTimeout_ticks'length = 0 generate
		sTimeout_valid <= iValid;
		sTimeout_data <= iData;
		oAck <= sTimeout_ack;
	end generate;
	
	gen_truncator: if iLimit'length > 0 generate

		truncator: spw_pkg_truncator
 	   	port map (
 	    	   iClk => iClk,
 	    	   iReset => iReset,

		        iLimit => iLimit,

 		       iValid => sTimeout_valid,
 		       iData => sTimeout_data,
 		       oAck => sTimeout_ack,

 		       oValid => sTruncator_valid,
 		       oData => sTruncatr_data,
 		       iAck => sTruncator_ack
 		   );
		end component;

	end generate;
	
	no_truncator: if iLimit'length = 0 generate
		sTruncator_valid <= sTimeout_valid;
		sTruncator_data <= sTimeout_data;
		sTimeout_ack <= sTruncator_ack;
	end generate;

	pkg_buffer: spw_pkg_buffer
 	   port map (
 	       iClk => iClk,
 	       iReset => iReset,

 	       -- from data source
 	       iValid => sTruncator_valid,
 	       iData => sTruncator_data,
 	       oAck => sTruncator_ack,

 	       -- control
 	       oHandshake => sBuffer_handshake_out,
 	       iHandshake => sBuffer_handshake_in,

 	       -- to data sink
 	       oValid => sBuffer_valid,
 	       oData => sBuffer_data,
 	       iAck => sBuffer_ack
 	   );
 
 	fsm: spw_router_rx_fsm
 	   port map (
 	       iClk => iClk,
 	       iReset => iReset,

 	       -- to pkg buffer
 	       iHandshake => sBuffer_handshake_out,
 	       oHandshake => sBuffer_handshake_in,

 	       -- to router control
 	       oRequest_mux => oRequest_mux,
 	       oPath => oPath,
 	       iGranted => iGranted,
 	       iDiscard = iDiscard,

 	       -- to pkg buffer
 	       iValid => sBuffer_valid,
 	       iData => sData,
 	       oAck => sAck,

 	       -- to data sink
 	       oValid => oValid,
 	       oData => oData,
 	       iAck => iAck
 	   );

end v1;