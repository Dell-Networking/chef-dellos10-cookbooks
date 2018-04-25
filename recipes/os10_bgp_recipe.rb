#
# Cookbook:: os10_bgp
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved

bgp 'default' do
  asn_num '200'
  router_id '4.4.4.4'
  maxpath_ibgp '73'
  maxpath_ebgp '91'
  bestpath_as_path 'multipath-relax'
  bestpath_med_confed true
  bestpath_med_missing_as_worst true
  bestpath_ignore_router_id true
  outbound_optimization false
  fast_ext_fallover false
  log_neighbor_changes false
  action :create
end

bgp 'default' do
  asn_num '200'
  action :delete
end
