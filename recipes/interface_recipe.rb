#
# Cookbook:: octagon
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved
os10_interface 'ethernet 1/1/5' do
  desc 'ie5'
  portmode 'trunk'
  mtu '1500'
  switchport_mode true
  admin 'abc'
  ip_and_mask '1.1.1.1/24'
  suppress_ra true
  ipv6_and_mask '2001:db8:85a3::8a2e:370:7334/32'
  state_ipv6 'cde'
  ip_helper ['1.1.1.2', '1.1.1.13']
end
