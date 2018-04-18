# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# Author::     Ravi Shankar (ravi_sabapathy@dell.com)
# Copyright::  Copyright (c) 2018, Dell Inc. All rights reserved.
# License::    [Apache License] (http://www.apache.org/licenses/LICENSE-2.0)
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# This file contains BGP Address family command resource
#
# Example BGP AF resource:
#
# bgp_af "ipv4-unicast" do
#  asn_num '200'
#  address_family "ipv4-unicast"
#  default_metric '300'
#  redistribute_connected ({enable:true, 'route-map':"t7"})
#  redistribute_static ({enable:true, 'route-map':"t8"})
#  redistribute_ospf ({id:20, 'route-map':"t9"})
#  network_add_list [ {:prefix=>"2.2.2.2/24", :"route-map"=>"t9"},
#                     {:prefix=>"3.3.3.3/24", :"route-map"=>"t9"}]
#  action :create
# end
#
# bgp_af "ipv4-unicast" do
#  asn_num '200'
#  address_family "ipv4-unicast"
#  action :delete
# end

resource_name :bgp_af
actions :create, :delete
property :asn_num, String
property :vrf, String, default: 'default'
property :address_family, String, name_property: true
property :default_metric, String, default: ''
property :redistribute_connected, Hash, default: {}
property :redistribute_static, Hash, default: {}
property :redistribute_ospf, Hash, default: {}
property :network_add_list, [Array, Hash], default: []

##
# Utility API to set resitribute connect or static
#
# @param [redstibute_data] <Hash> redstibute_data value
#
# @param [cli_string] <String> CLI to set
#
# @param [cli_array] <Array>  Output CLI buffer
#
# @return [None]
#

def set_redistribute_cli(redstibute_data, cli_string, cli_array)
  unless redstibute_data.nil?
    if redstibute_data[:enable]
      enable_value = redstibute_data[:enable]
      raise 'enable value cannot be nil' if enable_value.nil?
      if enable_value == true
        route_map = redstibute_data[:'route-map']
        if route_map.nil?
          cli_array << 'no ' + cli_string
          cli_array << cli_string
        else
          cli_array << cli_string + ' route-map ' + route_map
        end
      elsif enable_value == false
        cli_array << 'no ' + cli_string
      else
        raise 'enable key will take either true or false'
      end
    elsif redstibute_data.empty?
      cli_array << 'no ' + cli_string
    elsif redstibute_data[:'route-map']
      raise 'enable key is a mandatory parameter for ' + \
            cli_string + 'property'
    end
  end
end

##
# Utility API for load_current_value to load the bgp values
#
# @param [bgp_data] <hash>         The bgp running-config from the switch.
#
# @return [None]
#
def set_address_family_properties(bgp_data, address_family_ver)
  return if bgp_data.nil?

  assign_asn_vrf(bgp_data)

  if address_family_ver == 'ipv4-unicast'
    address_family_data = extract(bgp_data, :'ipv4-unicast')
  elsif address_family_ver == 'ipv6-unicast'
    address_family_data = extract(bgp_data, :'ipv6-unicast')
  else
    raise 'Invalid address family version ' + address_family_ver
  end

  return if address_family_data.nil?

  if address_family_data[:"default-metric"]
    default_metric address_family_data[:"default-metric"]
  end

  if address_family_data[:"redistribute-connected"]
    route_map = extract(address_family_data,
                        :"redistribute-connected",
                        :"redistribute-route-map")
    redistribute_connected ({enable:true, 'route-map':route_map}) 
  end

  if address_family_data[:"redistribute-static"]
    route_map = extract(address_family_data,
                        :"redistribute-static",
                        :"route-map")
    redistribute_static ({enable:true, 'route-map': route_map})
  end

  if address_family_data[:"redistribute-ospf"]
    route_map = extract(address_family_data,
                        :"redistribute-ospf",
                        :"route-map")
    ospf_id = extract(address_family_data,
                 :'redistribute-ospf', :id)
    redistribute_ospf ({id:ospf_id.to_i, 'route-map': route_map})
  end

  if address_family_data[:"network-address-list"]
    network_add_data = address_family_data[:"network-address-list"]
    if network_add_data.class == Hash
      network_add_list [network_add_data]
    else
      network_add_list network_add_data
    end

  end
end

load_current_value do
  start_os10_shell('admin')
  bgp_data = read_bgp_details
  value_exist = false
  value_exist = true unless bgp_data.to_s.empty?

  current_value_does_not_exist! unless value_exist

  begin
    set_address_family_properties(bgp_data, address_family)
  rescue StandardError => e
    Chef::Log.error "Exception in #{__method__}"
    Chef::Log.error e.message
    Chef::Log.error e.backtrace[0]
    end_os10_shell
    raise
  end
end


action :create do
  begin
    if new_resource.address_family != 'ipv4-unicast' &&
       new_resource.address_family != 'ipv6-unicast'
      raise 'Invalid address family ' + new_resource.address_family
    end

    converge_if_changed :asn_num do
      cmd = []
      asn_valid(new_resource)

      cmd << ROUTER_BGP + new_resource.asn_num
      execute_config_command(cmd)
      # The router bgp commands for the first time creation
      # takes some time. So, apply a delay
      sleep 1
    end

    temp_asn = get_valid_asn(new_resource)
    return if temp_asn.nil?
    check_asn_range(temp_asn)

    cmd = []
    cmd << ROUTER_BGP + temp_asn

    if new_resource.address_family.include? 'ipv4'
      cmd << AF_IPV4
      address_family_ver = 'ipv4'
    elsif new_resource.address_family.include? 'ipv6'
      cmd << AF_IPV6
      address_family_ver = 'ipv6'
    end

    converge_if_changed :default_metric do
      unless new_resource.default_metric.nil?
        if new_resource.default_metric.empty?
          cmd << 'no ' + DEF_METRIC
        else
          int_default_metric = new_resource.default_metric.to_i
          if int_default_metric >= 1 &&
             int_default_metric <= 4294967295
            cmd << DEF_METRIC + new_resource.default_metric
          else
            raise 'The default_metric value ' + new_resource.default_metric + \
                  ' is not in range of 1 - 4294967295'
          end
        end
      end
    end

    converge_if_changed :redistribute_connected do
      set_redistribute_cli(new_resource.redistribute_connected,
                           REDISTRIBUTE_CONNECT, cmd)
    end

    converge_if_changed :redistribute_static do
      set_redistribute_cli(new_resource.redistribute_static,
                           REDISTRIBUTE_STATIC, cmd)
    end

    converge_if_changed :redistribute_ospf do
      unless new_resource.redistribute_ospf.nil?
        if address_family_ver == 'ipv4'
          ospf_str = 'ospf'
        else
          ospf_str = 'ospfv3'
        end
        if new_resource.redistribute_ospf[:id]
          id = new_resource.redistribute_ospf[:id]
          raise 'id cannot be nil' if id.nil?
          raise 'id should be Integer' if id.class != Integer

          if id >= 1 && id <= 65535
            ospf_id = id.to_s
            route_map = new_resource.redistribute_ospf[:'route-map']
            if route_map.nil?
              cmd << 'no redistribute ' + ospf_str + ' ' + ospf_id
              cmd << 'redistribute '  + ospf_str + ' ' + ospf_id
            else
              cmd << 'redistribute ' + ospf_str + ' '\
                     + ospf_id + ' route-map ' +route_map
            end
          else
            raise 'The OSPF process id ' + ospf_id + \
                  ' is not in range of 1 - 65535'
          end
        elsif new_resource.redistribute_ospf.empty? &&
              !current_resource.nil? &&
              !current_resource.redistribute_ospf.empty? &&
              current_resource.redistribute_ospf[:id]
          cmd << 'no redistribute ' + ospf_str + ' ' + \
                 current_resource.redistribute_ospf[:id].to_s
        elsif new_resource.redistribute_ospf[:'route-map']
          raise 'id key is a mandatory parameter for redistribute ' + \
                ospf_str + ' property'
        end
      end
    end

    converge_if_changed :network_add_list do
      unless new_resource.network_add_list.nil?
        if current_resource.nil? || current_resource.network_add_list.nil?
          add = new_resource.network_add_list
        else
          add = new_resource.network_add_list - \
                current_resource.network_add_list
          remove = current_resource.network_add_list -
                   new_resource.network_add_list
          remove.each do |add_list|
            cmd << 'no network ' + add_list[:prefix]
          end
        end
        add.each do |add_list|
          break if add_list.empty?
          unless add_list[:prefix]
            raise 'prefix key is a mandatory parameter for network property'
          end
          network_ip = add_list[:prefix]
          if is_valid_address(network_ip) == false
            raise 'Invalid network IP address ' + network_ip
          end
          network_cli = 'network ' + network_ip
          if add_list[:'route-map']
            network_cli = network_cli + ' route-map ' + add_list[:'route-map']
          end
          cmd << network_cli
        end
      end
    end
    exec_config_cmd(cmd)
  rescue StandardError => e
    Chef::Log.error "Exception in #{__method__}"
    Chef::Log.error e.message
    Chef::Log.error e.backtrace[0]
    end_os10_shell
    raise
  end
end

action :delete do
  begin
    converge_by 'Deleting bgp address family config' do
      return if current_resource.nil?
      cmd = []
      asn_valid(new_resource)
      cmd << ROUTER_BGP + new_resource.asn_num
      unless new_resource.address_family.nil?
        if new_resource.address_family.include? 'ipv4'
          ip_ver = 'ipv4'
        elsif new_resource.address_family.include? 'ipv6'
          ip_ver = 'ipv6'
        else
          raise 'Invalid address family ' + new_resource.address_family
        end
        cmd << 'no address-family ' + ip_ver + ' unicast'
        exec_config_cmd(cmd)
      end
    end
  rescue StandardError => e
    Chef::Log.error "Exception in #{__method__}"
    Chef::Log.error e.message
    Chef::Log.error e.backtrace[0]
    end_os10_shell
    raise
  end
end
