create_clock -name "clock27" -period 37.037 [get_ports {clock27}]
create_clock -name "spiCk" -period 17.857 [get_ports {spiCk}]

derive_pll_clocks
derive_clock_uncertainty

set_false_path -to   {sync[*]}
set_false_path -to   {rgb[*]}
set_false_path -to   {dsg*}
set_false_path -to   {dram*}
set_false_path -to   {led}

set_false_path -from {tape}
set_false_path -from {dram*}
