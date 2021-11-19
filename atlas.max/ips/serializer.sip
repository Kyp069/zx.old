set_global_assignment -entity "serializer" -library "lib_serializer" -name IP_TOOL_NAME "altera_soft_lvds"
set_global_assignment -entity "serializer" -library "lib_serializer" -name IP_TOOL_VERSION "17.1"
set_global_assignment -entity "serializer" -library "lib_serializer" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_serializer" -name SPD_FILE [file join $::quartus(sip_path) "serializer.spd"]

set_global_assignment -library "lib_serializer" -name MISC_FILE [file join $::quartus(sip_path) "serializer_sim/serializer.v"]
