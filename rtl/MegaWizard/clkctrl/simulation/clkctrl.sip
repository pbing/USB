set_global_assignment -entity "clkctrl" -library "lib_clkctrl" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "clkctrl" -library "lib_clkctrl" -name IP_TOOL_VERSION "18.0"
set_global_assignment -entity "clkctrl" -library "lib_clkctrl" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_clkctrl" -name SPD_FILE [file join $::quartus(sip_path) "../clkctrl.spd"]
set_global_assignment -library "lib_clkctrl" -name MISC_FILE [file join $::quartus(sip_path) "../../clkctrl.qsys"]

set_global_assignment -library "lib_clkctrl" -name MISC_FILE [file join $::quartus(sip_path) "clkctrl.v"]
set_global_assignment -library "lib_clkctrl" -name MISC_FILE [file join $::quartus(sip_path) "submodules/clkctrl_altclkctrl_0.v"]
