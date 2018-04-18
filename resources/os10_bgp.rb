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
# This file contains BGP global command resource
#
# Example BGP resource:
#
# bgp "default" do
#  asn_num '200'
#  maxpath_ebgp '91'
#  bestpath_as_path "multipath-relax"
#  bestpath_med_confed true
#  bestpath_med_missing_as_worst true
#  bestpath_ignore_router_id true
#  outbound_optimization false
#  fast_ext_fallover false
#  log_neighbor_changes false
#  action :create
# end
# bgp "default" do
#  asn_num '200'
#  action :delete
# end

resource_name :bgp
actions :create, :delete
property :asn_num, String
property :vrf, kind_of: String, name_property: true
property :router_id, String, default: ''
property :maxpath_ibgp, String, default: '64'
property :maxpath_ebgp, String, default: '64'
property :bestpath_as_path, ['multipath-relax', 'ignore', '']
property :bestpath_med_confed, [true, false], default: false
property :bestpath_med_missing_as_worst, [true, false], default: false
property :bestpath_ignore_router_id, [true, false], default: false
property :outbound_optimization, [true, false], default: false
property :fast_ext_fallover, [true, false], default: true
property :log_neighbor_changes, [true, false], default: true

##
# Utility API for load_current_value to load the bgp values
#
# @param [bgp_data] <hash>         The bgp running-config from the switch.
#
# @return [None]
#

def assign_current_properties(bgp_data)
  return if bgp_data.nil?

  assign_asn_vrf(bgp_data)
  router_id bgp_data[:"router-id"] if bgp_data[:"router-id"]
  maxpath_ibgp extract_string_value(bgp_data,
                                    :"ibgp-number-of-path",
                                    DEFAULT_MAX_PATH)
  maxpath_ebgp extract_string_value(bgp_data,
                                    :"ebgp-number-of-path",
                                    DEFAULT_MAX_PATH)
  extract_bestpath_details(bgp_data)

  outbound_optimization true if bgp_data[:"outbound-optimization"]

  fast_ext_fallover extract_enum_value(bgp_data,
                                       :"fast-external-fallover")
  log_neighbor_changes extract_enum_value(bgp_data,
                                          :"log-neighbor-changes")
end

load_current_value do
  start_os10_shell('admin')
  bgp_data = read_bgp_details
  value_exist = false
  value_exist = true unless bgp_data.to_s.empty?

  current_value_does_not_exist! unless value_exist
  begin
    assign_current_properties(bgp_data)
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
    converge_if_changed :router_id do
      unless new_resource.router_id.nil?
        if new_resource.router_id.empty?
          cmd << ROUTER_ID_NEG
        else
          if is_valid_address(new_resource.router_id) == false
            raise 'Invalid router-id ' + new_resource.router_id
          end
          cmd << ROUTER_ID + new_resource.router_id
        end
      end
    end

    converge_if_changed :maxpath_ebgp do
      unless new_resource.maxpath_ebgp.nil?
        if new_resource.maxpath_ebgp.empty?
          cmd << 'no ' + MAXPATH_EBGP
        else
          int_maxpath_ebgp = new_resource.maxpath_ebgp.to_i
          if int_maxpath_ebgp >= 1 && int_maxpath_ebgp <= 128
            cmd << MAXPATH_EBGP + new_resource.maxpath_ebgp
          else
            raise 'The maxpath_ebgp value ' + new_resource.maxpath_ebgp + \
                  ' is not in the range of 1 - 128'
          end
        end
      end
    end
    converge_if_changed :maxpath_ibgp do
      unless new_resource.maxpath_ibgp.nil?
        if new_resource.maxpath_ibgp.empty?
          cmd << 'no ' + MAXPATH_IBGP
        else
          int_maxpath_ibgp = new_resource.maxpath_ibgp.to_i
          if int_maxpath_ibgp >= 1 && int_maxpath_ibgp <= 128
            cmd << MAXPATH_IBGP + new_resource.maxpath_ibgp
          else
            raise 'The maxpath_ibgp value ' + new_resource.maxpath_ibgp + \
                  ' is not in the range of 1 - 128'
          end
        end
      end
    end
    converge_if_changed :bestpath_as_path do
      unless new_resource.bestpath_as_path.nil?
        if new_resource.bestpath_as_path.empty?
          if !current_resource.nil? &&
             !current_resource.bestpath_as_path.nil? &&
             !current_resource.bestpath_as_path.empty?
            cmd << 'no ' + BESTPATH_ASPATH + ' ' + \
                   current_resource.bestpath_as_path
          end
        else
          cmd << BESTPATH_ASPATH + new_resource.bestpath_as_path
        end
      end
    end

    converge_if_changed :bestpath_med_confed do
      set_cli_command(new_resource.bestpath_med_confed,
                      BESTPATH_MED_CONFED, cmd)
    end

    converge_if_changed :bestpath_med_missing_as_worst do
      set_cli_command(new_resource.bestpath_med_missing_as_worst,
                      BESTPATH_MED_MIS_AS_WORST, cmd)
    end

    converge_if_changed :bestpath_ignore_router_id do
      set_cli_command(new_resource.bestpath_ignore_router_id,
                      BESTPATH_IGN_ROUTERID, cmd)
    end

    converge_if_changed :outbound_optimization do
      set_cli_command(new_resource.outbound_optimization,
                      OUTBOUND_OPT, cmd)
    end

    converge_if_changed :fast_ext_fallover do
      set_cli_command(new_resource.fast_ext_fallover,
                      FAST_EXT_FAILOVER, cmd)
    end

    converge_if_changed :log_neighbor_changes do
      set_cli_command(new_resource.log_neighbor_changes,
                      LOG_NBR_CHANGES, cmd)
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
    converge_by 'Deleting bgp config' do
      return if current_resource.nil?
      cmd = []
      if current_resource.asn_num != new_resource.asn_num
        Chef::Log.info 'The input ASN ' + new_resource.asn_num + \
                       ' should be equal to existing ASN ' + \
                       current_resource.asn_num
      end

      cmd << ROUTER_BGP_NEG
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
