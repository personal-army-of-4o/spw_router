#!/bin/bash

top=$1
modules=( spw_pkg_timeout spw_pkg_truncator spw_router_mux spw_router_tx_fsm )

function build_module {
    sm=$1
    echo "building submodule $sm"
    cp config.json $sm/
    pushd $sm
    bash buildscripts/synth.bash > log
    if [ "$?" != "0" ]; then
        echo "failed to build submodule $sm"
        exit 1
    fi
    netlist="build/$sm.v"
    if [ ! -f $netlist ]; then
        echo "failed to find netlist $netlist"
        exit 1
    fi
    netlists="$netists $sm/$netlist"
    popd
}

echo git status:
git submodule status
sources=`cat filelist`
mydir=`pwd`
sources=(${sources[@]/#/$mydir\/})

# build modules
for m in ${modules[@]}; do
    build_module $m
done

compose yosys script
echo "ghdl --std=08 ${sources[@]} -e $top" > gendot.ys
echo "read_verilog $netlists" >> gendot.ys
echo "prep" >> gendot.ys
echo "show -prefix $top -format dot" >> gendot.ys
echo yosys script:
cat gendot.ys
yosys -m ghdl gendot.ys

