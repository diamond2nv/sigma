# get the directory where this script resides
set thisDir [file dirname [info script]]

set ipDir ./ip

open_project ./vivado/ip/ip.xpr

# Create IP
create_ip -vlnv xilinx.com:ip:c_addsub:12.0 -module_name pe_time_ip_sub_const -dir $ipDir

set_property -dict [list \
        CONFIG.Component_Name {pe_time_ip_sub_const} \
        CONFIG.Implementation {DSP48} \
        CONFIG.A_Type {Unsigned} \
        CONFIG.B_Type {Unsigned} \
        CONFIG.A_Width {32} \
        CONFIG.B_Width {1} \
        CONFIG.Add_Mode {Subtract} \
        CONFIG.Latency {0} \
        CONFIG.B_Constant {true} \
        CONFIG.B_Value {1} \
        CONFIG.CE {false} \
        CONFIG.Out_Width {32} \
] [get_ips pe_time_ip_sub_const]

generate_target all [get_files pe_time_ip_sub_const.xci]

export_ip_user_files -of_objects [get_files pe_time_ip_sub_const.xci] -no_script -ip_user_files_dir ./vivado/ip_user_files -sync -force -quiet

create_ip_run [get_files -of_objects [get_fileset sources_1] [get_files */pe_time_ip_sub_const.xci]]

launch_runs -jobs 8 pe_time_ip_sub_const_synth_1
wait_on_run pe_time_ip_sub_const_synth_1

export_simulation -of_objects [get_files pe_time_ip_sub_const.xci] -directory ./vivado/ip_user_files/sim_scripts -ip_user_files_dir ./vivado/ip_user_files -ipstatic_source_dir ./vivado/ip_user_files/ipstatic -use_ip_compiled_libs -force -quiet

close_project

