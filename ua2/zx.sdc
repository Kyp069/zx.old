create_clock -name "clock50" -period 20.000 [get_ports {clock50}]

derive_pll_clocks
derive_clock_uncertainty

set_false_path -to   {sync[*]}
set_false_path -to   {rgb[*]}
set_false_path -to   {i2s*}
set_false_path -to   {joy*}
set_false_path -to   {usd*}
set_false_path -to   {dram*}
#et_false_path -to   {sram*}
set_false_path -to   {stm}
set_false_path -to   {led*}

set_false_path -from {tape}
set_false_path -from {ps2k*}
set_false_path -from {joy*}
set_false_path -from {usd*}
set_false_path -from {dram*}
#et_false_path -from {sram*}
