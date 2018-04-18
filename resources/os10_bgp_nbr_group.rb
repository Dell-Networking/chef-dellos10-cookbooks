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
# This file contains BGP neighbor group command resource
#
# Example BGP neighbor group resource:
#
# bgp_nbr_group "tr1" do
#  asn_num '200'
#  advertisement_interval '600'
#  advertisement_start '50'
#  timers ({keepalive: 50, hold_time: 70})
#  connection_retry_timer '70'
#  remote_as '300'
#  remove_private_as true
#  password "Deepesh"
#  send_community_ext true
#  action :create
# end
#
# bgp_nbr_group "tr1" do
#  asn_num '200'
#  action :delete
# end

resource_name :bgp_nbr_group
actions :create, :delete
property :asn_num, String
property :vrf, String, default: 'default'
property :peer_group_config, String, name_property: true
property :advertisement_interval, String, default: '30'
property :advertisement_start, String, default: ''
property :timers, Hash, default: {}
property :connection_retry_timer, String, default: '60'
property :remote_as, String, default: ''
property :remove_private_as, [true, false], default: false
property :password, String, default: ''
property :send_community_ext, [true, false], default: false
property :send_community_std, [true, false], default: false
property :address_family, ['ipv4-unicast', 'ipv6-unicast']
property :af_activate, [true, false]

##
# Utility API for load_current_value to load the bgp values
#
# @param [bgp_data] <hash>         The bgp running-config from the switch.
#
# @return [None]
#
def set_nbr_group_properties(bgp_data, template, address_family)
  return if bgp_data.nil?

  assign_asn_vrf(bgp_data)
  return if template.empty?

  hash_data = is_value_present(bgp_data, :'peer-group-config',
                               :name, template)
  peer_group_config_data = hash_data[:data]
  if peer_group_config_data.nil?
    Chef::Log.debug 'The user requested peer config is not present'
    return
  end
  assign_peer_data(peer_group_config_data)

  if address_family == 'ipv4-unicast' &&
     peer_group_config_data[:'ipv4-unicast']
    af = extract(peer_group_config_data, :'ipv4-unicast')
  elsif address_family == 'ipv6-unicast' &&
        peer_group_config_data['ipv6-unicast']
    af = extract(peer_group_config_data, :'ipv6-unicast')
  end

  return if af.nil? || af.class != Hash

  af_activate false if af[:activate] == 'false'
  af_activate true if af[:activate] == 'true'
end

load_current_value do |desired|
  start_os10_shell('admin')
  bgp_data = read_bgp_details
  value_exist = false
  value_exist = true unless bgp_data.to_s.empty?

  current_value_does_not_exist! unless value_exist

  begin
    set_nbr_group_properties(bgp_data,
                             peer_group_config,
                             desired.address_family)
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

    unless new_resource.peer_group_config.nil?
      raise 'Templete length should be <= 16' \
            if new_resource.peer_group_config.length > 16
      cmd << TEMPLATE + new_resource.peer_group_config
    end

    converge_if_changed :remote_as do
      set_peer_remote_as(new_resource.remote_as, cmd)
    end

    converge_if_changed :password do
      set_peer_password(new_resource.password, cmd)
    end

    converge_if_changed :timers do
      set_peer_timer(new_resource.timers, cmd)
    end

    converge_if_changed :advertisement_start do
      set_peer_adv_start(new_resource.advertisement_start, cmd)
    end

    converge_if_changed :advertisement_interval do
      set_peer_adv_interval(new_resource.advertisement_interval, cmd)
    end

    converge_if_changed :connection_retry_timer do
      set_peer_retry_timer(new_resource.connection_retry_timer, cmd)
    end

    converge_if_changed :send_community_ext do
      set_cli_command(new_resource.send_community_ext,
                      SEND_COMM_EXT, cmd)
    end

    converge_if_changed :send_community_std do
      set_cli_command(new_resource.send_community_std,
                      SEND_COMM_STD, cmd)
    end

    converge_if_changed :remove_private_as do
      set_cli_command(new_resource.remove_private_as,
                      REMOTE_PRIVATE_AS, cmd)
    end

    if %w[ipv4-unicast ipv6-unicast].include?(new_resource.address_family)

      cmd << AF_IPV4 if new_resource.address_family == 'ipv4-unicast'
      cmd << AF_IPV6 if new_resource.address_family == 'ipv6-unicast'

      converge_if_changed :af_activate do
        set_cli_command(new_resource.af_activate, 'activate', cmd)
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
    converge_by 'Deleting bgp peer group config' do
      return if current_resource.nil?
      cmd = []
      asn_valid(new_resource)
      cmd << ROUTER_BGP + new_resource.asn_num
      return if new_resource.peer_group_config.nil?
      bgp_data = read_bgp_details
      unless bgp_data.nil?
        hash_data = is_value_present(bgp_data, :'peer-group-config', :name,
                                     new_resource.peer_group_config)
        if hash_data[:present] == false
          raise 'neighbor group config ' + new_resource.peer_group_config +
                ' not present in switch'
        end
      end
      if new_resource.address_family.nil?
        cmd << 'no ' + TEMPLATE + new_resource.peer_group_config
      else
        cmd << TEMPLATE + new_resource.peer_group_config
        if new_resource.address_family == 'ipv4-unicast'
          cmd << 'no ' + AF_IPV4
        elsif new_resource.address_family == 'ipv6-unicast'
          cmd << 'no ' + AF_IPV6
        end
      end
      exec_config_cmd(cmd)
    end
  rescue StandardError => e
    Chef::Log.error "Exception in #{__method__}"
    Chef::Log.error e.message
    Chef::Log.error e.backtrace[0]
    end_os10_shell
    raise
  end
end
