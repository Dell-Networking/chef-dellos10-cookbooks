#
# Cookbook:: octagon
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved
os10_lldp 'lldp_conf' do
  enable true
  holdtime_multiplier '7'
  reinit '5'
  timer '80'
  med_fast_start_repeat_count '5'
  med_network_policy [{ 'id' => '2', 'app' => 'voice', 'vlan' => '3', 'vlan-type' => 'tag', 'priority' => '3', 'dscp' => '4' }]
end
