#
# Cookbook:: octagon
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved
os10_portmonitoring '2' do
  source ['ethernet1/1/1']
  flowbase true
  shutdown true
  action :delete
end

os10_portmonitoring '2' do
  source ['ethernet1/1/1', 'ethernet1/1/5']
  flowbase true
  shutdown true
  action :create
end

os10_portmonitoring '2' do
  source ['ethernet1/1/1', 'ethernet1/1/3']
  flowbase false
  shutdown false
  action :create
end
