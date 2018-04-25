#
# Cookbook:: os10_bgp_nbr
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved

bgp_nbr '9.9.9.9' do
  asn_num '200'
  peer_config '9.9.9.9'
  advertisement_interval '600'
  advertisement_start '50'
  timers ({ keepalive: 50, hold_time: 70 })
  connection_retry_timer '70'
  remote_as '300'
  remove_private_as true
  shutdown false
  password ''
  send_community_ext true
  associate_peer_group 'tr1'
  address_family 'ipv4-unicast'
  allowas_in '10'
  action :create
end

bgp_nbr '9.9.9.9' do
  asn_num '200'
  address_family 'ipv4-unicast'
  action :delete
end
