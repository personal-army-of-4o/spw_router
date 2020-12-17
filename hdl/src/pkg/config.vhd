library work;
use work.json.all;

package config is

    constant cTimeout_reg_width: natural;
    constant cLimit_reg_width: natural;
    constant cPort_num: natural;

end package;

package body config is

    constant cTimeout_tick_width_name: string := "timeout_cfg_width";
    constant cConfig_location: string := ".";
    constant cConfig_name: string := "config.json";
    constant cConfig_path: string := cConfig_location & "/" & cConfig_name;
    constant cConfig_str: T_JSON := jsonLoad (cConfig_path);

    function get_cfg (cfg: T_JSON; key: string) return natural is
        variable ret: natural;
    begin
        if jsonNoParserError (cfg) = false then
            assert false report jsonGetErrorMessage (cfg) severity failure;
        end if;
        return natural'value(jsonGetString(cfg, key));
    end function;

    constant cTimeout_reg_width: natural := get_cfg (cConfig_str, "timeout_reg_width");
    constant cLimit_reg_width: natural := get_cfg (cConfig_str, "limit_reg_width");
    constant cPort_num: natural := get_cfg (cConfig_str, "port_number");

end package body;

