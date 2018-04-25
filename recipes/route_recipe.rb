#
# Cookbook:: octagon
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved
os10_route '4.4.4.4/32' do
  action :delete
end
os10_route '4.4.4.4/32' do
  next_hop ['interface ethernet 1/1/6 10.10.10.10', '20.20.20.20']
  action :create
end
os10_route '4.4.4.4/32' do
  next_hop ['interface ethernet 1/1/6 10.10.10.10',
            'interface ethernet 1/1/6 20.20.20.20']
  action :create
end
