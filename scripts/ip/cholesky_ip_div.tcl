# get the directory where this script resides
set thisDir [file dirname [info script]]

set ipDir ./ip

open_project ./vivado/ip/ip.xpr

# Create IP
create_ip -vlnv xilinx.com:ip:div_gen:5.1 -module_name cholesky_ip_div -dir $ipDir

set_property -dict [list \
	CONFIG.Component_Name {cholesky_ip_div} \
	CONFIG.dividend_and_quotient_width {32} \
	CONFIG.divisor_width {32} \
	CONFIG.remainder_type {Fractional} \
	CONFIG.fractional_width {17} \
	CONFIG.latency_configuration {Automatic} \
	CONFIG.latency {53} \
	CONFIG.ACLKEN {true} \
	CONFIG.ARESETN {true} \
] [get_ips cholesky_ip_div]

generate_target all [get_files cholesky_ip_div.xci]

export_ip_user_files -of_objects [get_files cholesky_ip_div.xci] -no_script -ip_user_files_dir ./vivado/ip_user_files -sync -force -quiet

create_ip_run [get_files -of_objects [get_fileset sources_1] [get_files */cholesky_ip_div.xci]]

launch_runs -jobs 8 cholesky_ip_div_synth_1
wait_on_run cholesky_ip_div_synth_1

export_simulation -of_objects [get_files cholesky_ip_div.xci] -directory ./vivado/ip_user_files/sim_scripts -ip_user_files_dir ./vivado/ip_user_files -ipstatic_source_dir ./vivado/ip_user_files/ipstatic -use_ip_compiled_libs -force -quiet

close_project

