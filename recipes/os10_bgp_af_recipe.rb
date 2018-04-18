#
# Cookbook:: os10_bgp_af
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved

bgp_af 'ipv4-unicast' do
  asn_num '200'
  address_family 'ipv4-unicast'
  default_metric '300'
  redistribute_connected ({ :enable => true, :'route-map' => 't7' })
  redistribute_static ({ :enable => true, :'route-map' => 't8' })
  redistribute_ospf ({ :id => 20, :'route-map' => 't9' })
  network_add_list [{ :prefix => '2.2.2.2/24', :'route-map' => 't9' }, \
                    { :prefix => '3.3.3.3/24', :'route-map' => 't9' }]
  action :create
end

bgp_af 'ipv4-unicast' do
  asn_num '200'
  address_family 'ipv4-unicast'
  action :delete
end
