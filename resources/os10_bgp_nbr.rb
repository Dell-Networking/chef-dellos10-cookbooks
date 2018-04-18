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
# This file contains BGP neighbor command resource
#
# Example BGP Neighbor resource:
#
# bgp_nbr "9.9.9.9" do
#  asn_num '200'
#  peer_config "9.9.9.9"
#  advertisement_interval '600'
#  advertisement_start '50'
#  timers ({keepalive: 50, hold_time: 70})
#  connection_retry_timer '70'
#  remote_as '300'
#  remove_private_as true
#  shutdown false
#  password "Deepesh"
#  send_community_ext true
#  associate_peer_group "art1"
#  action :create
# end
#
# bgp_nbr "9.9.9.9" do
#   asn_num '200'
#   action :delete
# end

resource_name :bgp_nbr
actions :create, :delete
property :asn_num, String
property :vrf, String, default: 'default'
property :peer_config, String, name_property: true
property :advertisement_interval, String, default: '30'
property :advertisement_start, String, default: ''
property :timers, Hash, default: {}
property :connection_retry_timer, String, default: '60'
property :remote_as, String, default: ''
property :remove_private_as, [true, false], default: false
property :shutdown, [true, false], default: true
property :password, String, default: ''
property :send_community_ext, [true, false], default: false
property :send_community_std, [true, false], default: false
property :associate_peer_group, String, default: ''
property :address_family, ['ipv4-unicast', 'ipv6-unicast']
property :af_activate, [true, false]
property :allowas_in, String, default: ''

##
# Utility API for load_current_value to load the bgp values
#
# @param [bgp_data] <hash>         The bgp running-config from the switch.
#
# @return [None]
#
def set_nbr_properties(bgp_data, neighbor, address_family)
  return if bgp_data.nil?

  assign_asn_vrf(bgp_data)
  return if neighbor.empty?

  hash_data = is_value_present(bgp_data, :'peer-config', :'remote-address',
                               neighbor)
  peer_config_data = hash_data[:data]
  if peer_config_data.nil?
    Chef::Log.debug 'The user requested peer config is not present'
    return
  end
  assign_peer_data(peer_config_data)
  shutdown false if peer_config_data[:'shutdown-status']

  if peer_config_data[:'associate-peer-group']
    peer_group_name = peer_config_data[:'associate-peer-group']
    associate_peer_group peer_group_name unless peer_group_name.nil?
  end

  if address_family == 'ipv4-unicast' &&
     peer_config_data[:'ipv4-unicast']
    af = extract(peer_config_data, :'ipv4-unicast')
  elsif address_family == 'ipv6-unicast' &&
        peer_config_data[:'ipv6-unicast']
    af = extract(peer_config_data, :'ipv6-unicast')
  end

  return if af.nil? || af.class != Hash

  af_activate false if af[:activate] == 'false'
  af_activate true if af[:activate] == 'true'
  allowas_in af[:'allowas-in'] if af[:'allowas-in']
end

load_current_value do |desired|
  start_os10_shell('admin')
  bgp_data = read_bgp_details
  value_exist = false
  value_exist = true unless bgp_data.to_s.empty?

  current_value_does_not_exist! unless value_exist

  begin
    set_nbr_properties(bgp_data, peer_config, desired.address_family)
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

    unless new_resource.peer_config.nil?
      raise 'Invalid neighbor IP address ' + new_resource.peer_config \
            unless is_valid_address(new_resource.peer_config)
      cmd << NEIGHBOR + new_resource.peer_config
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

    converge_if_changed :shutdown do
      set_cli_command(new_resource.shutdown, SHUTDOWN, cmd)
    end

    converge_if_changed :associate_peer_group do
      unless new_resource.associate_peer_group.nil?
        if !new_resource.associate_peer_group.empty?
          raise 'Inherit template length should be <= 16' \
                if new_resource.associate_peer_group.length > 16
          bgp_data = read_bgp_details
          unless bgp_data.nil?
            hash_data = is_value_present(bgp_data, :'peer-group-config', :name,
                                         new_resource.associate_peer_group)
            raise_str = 'The peer group ' + \
                        new_resource.associate_peer_group + \
                        ' is not present in the box'
            raise raise_str unless hash_data[:present]
            cmd << INHERIT_TEMPLATE + new_resource.associate_peer_group
          end
        elsif !current_resource.nil? && \
              !current_resource.associate_peer_group.empty?
          # If NULL string is given then delete the
          # associate_peer_group property
          cmd << 'no ' + INHERIT_TEMPLATE + \
                 current_resource.associate_peer_group
        end
      end
    end

    if %w[ipv4-unicast ipv6-unicast].include?(new_resource.address_family)

      cmd << AF_IPV4 if new_resource.address_family == 'ipv4-unicast'
      cmd << AF_IPV6 if new_resource.address_family == 'ipv6-unicast'

      converge_if_changed :af_activate do
        set_cli_command(new_resource.af_activate, 'activate', cmd)
      end

      converge_if_changed :allowas_in do
        unless new_resource.allowas_in.nil?
          if new_resource.allowas_in.empty?
            cmd << 'no allowas-in'
          else
            raise_str = 'The allowas_in value ' + new_resource.allowas_in + \
                        ' is not in range of 1 - 10'
            raise raise_str unless (1..10).member?(new_resource.allowas_in.to_i)
            cmd << 'allowas-in ' + new_resource.allowas_in
          end
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
    converge_by 'Deleting bgp peer config' do
      return if current_resource.nil?
      cmd = []
      asn_valid(new_resource)
      cmd << ROUTER_BGP + new_resource.asn_num
      return if new_resource.peer_config.nil?
      bgp_data = read_bgp_details
      unless bgp_data.nil?
        hash_data = is_value_present(bgp_data, :'peer-config',
                                     :'remote-address',
                                     new_resource.peer_config)
        if hash_data[:present] == false
          raise 'neighbor config ' + new_resource.peer_config +
                ' not present in switch'
        end
      end
      if !new_resource.address_family.nil?
        cmd << NEIGHBOR + new_resource.peer_config
        if new_resource.address_family == 'ipv4-unicast'
          cmd << 'no ' + AF_IPV4
        elsif new_resource.address_family == 'ipv6-unicast'
          cmd << 'no ' + AF_IPV6
        end
      else
        cmd << 'no ' + NEIGHBOR + new_resource.peer_config
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
