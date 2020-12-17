top=rx_pipeline
arg="ghdl hdl/src/$top.vhd -e $top; prep; show -stretch -prefix $top -format dot"
echo "yosys arg: $arg"
yosys -m ghdl -p $arg