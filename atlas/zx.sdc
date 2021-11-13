create_clock -name "clock12" -period 83.334 [get_ports {clock12}]

derive_pll_clocks
derive_clock_uncertainty

set_false_path -to   {tmds*}
set_false_path -to   {dsg*}
#et_false_path -to   {i2s*}
#et_false_path -to   {midi*}
#et_false_path -to   {joy*}
set_false_path -to   {usd*}
set_false_path -to   {dram*}
#et_false_path -to   {sram*}
set_false_path -to   {led*}

set_false_path -from {tape}
#et_false_path -from {midi*}
set_false_path -from {ps2k*}
#et_false_path -from {joy*}
set_false_path -from {usd*}
set_false_path -from {dram*}
#et_false_path -from {sram*}
