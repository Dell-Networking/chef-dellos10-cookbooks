#
# Cookbook:: os10_bgp_nbr_group
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved

bgp_nbr_group 'tr1' do
  asn_num '200'
  advertisement_interval '600'
  advertisement_start '50'
  timers ({ keepalive: 50, hold_time: 70 })
  connection_retry_timer '70'
  remote_as '300'
  remove_private_as true
  password 'Deepesh'
  send_community_ext true
  action :create
end

bgp_nbr_group 'tr1' do
  asn_num '200'
  action :delete
end
