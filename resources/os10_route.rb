# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# Author::     Lalit Gera (Lalit_Gera@dell.com)
# Copyright::  Copyright (c) 2018, Dell Inc. All rights reserved.
# License::    [Apache License] (http://www.apache.org/licenses/LICENSE-2.0)
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# This file contains os10 route command resource
# Example os10 route resource
# os10_route '4.4.4.4/32' do
# action :delete
# end
# os10_route '4.4.4.4/32' do
# next_hop ["interface ethernet 1/1/6 10.10.10.10", "20.20.20.20"]
# action :create
# end
# os10_route '4.4.4.4/32' do
# next_hop ["interface ethernet 1/1/6 10.10.10.10"]
# action :create
# end

resource_name :os10_route
property :route_ip, kind_of: String, name_property: true
property :next_hop, kind_of: Array

load_current_value do
  start_os10_shell('admin')
  hash = execute_show_command('show running-configuration | grep  ' + route_ip)
  route_data = hash[:stdout].split("\n")
  value_exist = false
  if !hash[:stdout].to_s.empty?
    value_exist = true
  end
  next_hop []
  current_value_does_not_exist! unless value_exist
  prefix_str = 'ip route ' + route_ip + ' '
  route_data.each do |route|
    next_hop << route.split(prefix_str)[1]
  end
  next_hop next_hop.sort
end

action :create do
  begin
    converge_if_changed :route_ip do
      cmd = []
      new_resource.next_hop.each do |nh|
        cmd << 'ip route ' + new_resource.route_ip + ' ' + nh
      end
      execute_config_command(cmd)
    end
    if current_resource.nil?
      return
    end
    new_resource.next_hop = new_resource.next_hop.sort
    converge_if_changed :next_hop do
      add = new_resource.next_hop - current_resource.next_hop
      remove = current_resource.next_hop - new_resource.next_hop
      cmd = []
      remove.each do |nh|
        cmd << 'no ip route ' + current_resource.route_ip + ' ' + nh
      end
      add.each do |nh|
        cmd << 'ip route ' + current_resource.route_ip + ' ' + nh
      end
      execute_config_command(cmd)
    end
  rescue StandardError => e
    Chef::Log.error e.message
  end
end

action :delete do
  begin
    converge_by "Deleting route #{new_resource.route_ip}" do
      if current_resource.nil?
        return
      end
      cmd = []
      current_resource.next_hop.each do |nh|
        cmd << 'no ip route ' + current_resource.route_ip + ' ' + nh
      end
      execute_config_command(cmd)
    end
  rescue StandardError => e
    Chef::Log.error e.message
  end
end
