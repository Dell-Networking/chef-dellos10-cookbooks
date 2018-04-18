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
# This file contains os10 interface command resource
# Example os10 interface resource
# os10_interface 'ethernet 1/1/5' do
# desc "ie5"
# portmode "trunk"
# mtu "1500"
# switchport_mode true
# admin "abc"
# ip_and_mask "1.1.1.1/24"
# suppress_ra true
# ipv6_and_mask "2001:db8:85a3::8a2e:370:7334/32"
# state_ipv6  "cde"
# ip_helper ["1.1.1.2", "1.1.1.13"]
# end

resource_name :os10_interface
property :interface_name, String, name_property: true
property :desc, String
property :portmode, String
property :mtu, String
property :switchport_mode, kind_of: [TrueClass, FalseClass]
property :admin, String
property :ip_and_mask, String
property :suppress_ra, kind_of: [TrueClass, FalseClass]
property :ipv6_and_mask, String
property :state_ipv6, String
property :ip_helper, Array, default: []
load_current_value do
        start_os10_shell("admin")
        ret = execute_show_command("show running-configuration interface #{interface_name} | display-xml")
        value_exist = false
        if !ret[:stdout]['rpc-reply'][:data][:interfaces].nil?
            value_exist = true
        end
        current_value_does_not_exist! unless value_exist
        begin
            intf = ret[:stdout]['rpc-reply'][:data][:interfaces][:interface]
            if intf[:description]
               desc intf[:description]
            else
               desc ""
            end
            if intf[:mtu]
               mtu intf[:mtu]
            else
               mtu ""
            end
            if intf[:enabled] == "false"
               admin "down"
            else 
               admin "up"
            end
            if intf[:mode]=="MODE_L2DISABLED" 
               switchport_mode false
               portmode ""
            elsif intf[:mode] == "MODE_L2HYBRID"
               switchport_mode true
               portmode "trunk"
            else
               if intf[:"mode"] == "access"
                   portmode ""
               else
                   portmode intf[:"mode"]
               end
               switchport_mode true
            end
            if intf[:"ipv6"] && intf[:"ipv6"][:"ra"]
                suppress_ra  false
            else
                suppress_ra  true
            end
            if intf[:"ipv4"]
                if intf[:"ipv4"][:"dhcp-config"]
                    ip_and_mask ""
                elsif intf[:"ipv4"][:address]
                    ip_and_mask intf[:"ipv4"][:address][:"primary-addr"]
                end
            else
                ip_and_mask ""
            end
            if intf[:"ipv6"]
                if intf[:"ipv6"][:"ipv6-addresses"]
                    ipv6_and_mask  intf[:"ipv6"][:"ipv6-addresses"][:address][:"ipv6-address"]
                    state_ipv6  "present"
                else
                    ipv6_and_mask  ""
                    state_ipv6  "absent"
                end 
            end
            if intf[:"dhcp-relay-if-cfgs"]
                existing_helper = intf[:"dhcp-relay-if-cfgs"][:"server-address"]
                if existing_helper.is_a?Array
                   ip_helper existing_helper 
                else
                   ip_helper [existing_helper]
                end
            end
            ip_helper ip_helper.sort
        rescue Exception => e
            Chef::Log.error e.message
        end
end

action :create do
      begin
          converge_if_changed :desc do
              cmd = []
              cmd << "interface "+new_resource.interface_name
              if new_resource.desc.to_s.empty?
                 cmd << "no description "
              else 
                 cmd << "description "+new_resource.desc
              end   
              hash = execute_config_command(cmd)
              if !hash[:stderr].to_s.empty?
                  raise RuntimeError.new(hash[:stderr])
              end
          end
          converge_if_changed :mtu do
              cmd = []
              cmd << "interface "+new_resource.interface_name
              if new_resource.mtu.to_s.empty?
                 cmd << "no mtu "
              else
                 cmd << "mtu "+new_resource.mtu
              end
              hash = execute_config_command(cmd)
              if !hash[:stderr].to_s.empty?
                 raise RuntimeError.new(hash[:stderr])
              end
          end
          converge_if_changed :switchport_mode do 
              cmd = []
              cmd << "interface "+new_resource.interface_name
              if new_resource.switchport_mode == true
                  converge_if_changed :portmode do
                     if !new_resource.portmode.to_s.empty?
                        cmd << "switchport mode "+new_resource.portmode
                     else
                        cmd << "switchport mode access"
                     end
                  end
               else
                  cmd << "no switchport"
              end
              hash = execute_config_command(cmd)
              if !hash[:stderr].to_s.empty?
                 raise RuntimeError.new(hash[:stderr])
              end
          end
          converge_if_changed :portmode do
              cmd = []
              cmd << "interface "+new_resource.interface_name
              if !new_resource.portmode.to_s.empty?
                 cmd <<"switchport mode "+new_resource.portmode
              else
                 cmd << "no switchport"
              end
              hash = execute_config_command(cmd)
              if !hash[:stderr].to_s.empty?
                 raise RuntimeError.new(hash[:stderr])
              end
         end
         converge_if_changed :admin do
             cmd = []
             cmd << "interface "+new_resource.interface_name
             if new_resource.admin.to_s == "up"
                 cmd << "no shutdown"
             elsif new_resource.admin.to_s == "down"
                 cmd << "shutdown"
             else
                 raise ArgumentError.new("wrong value for admin property "+new_resource.admin)
             end
             hash = execute_config_command(cmd)
             if !hash[:stderr].to_s.empty?
                 raise RuntimeError.new(hash[:stderr])
             end
         end
         converge_if_changed :ip_and_mask do
             cmd = []
             cmd << "interface "+new_resource.interface_name
             if new_resource.ip_and_mask.to_s.empty?
                 cmd << "no ip address"
             else
                 cmd << "ip address "+new_resource.ip_and_mask
             end
             hash = execute_config_command(cmd)
             if !hash[:stderr].to_s.empty?
                 raise RuntimeError.new(hash[:stderr])
             end
         end
         converge_if_changed :suppress_ra do
             cmd = []
             cmd << "interface "+new_resource.interface_name
             if new_resource.suppress_ra
                 cmd << "no ipv6 nd send-ra"
             else
                 cmd << "ipv6 nd send-ra"
             end
             hash = execute_config_command(cmd)
             if !hash[:stderr].to_s.empty?
                 raise RuntimeError.new(hash[:stderr])
             end
         end

         converge_if_changed :ipv6_and_mask do
             cmd = []
             cmd << "interface "+new_resource.interface_name
             if !new_resource.ipv6_and_mask.to_s.empty?
                 converge_if_changed :state_ipv6 do
                    if new_resource.state_ipv6 == "absent" 
                        cmd << "no ipv6 address "+new_resource.ipv6_and_mask
                    elsif new_resource.state_ipv6 == "present"
                        cmd << "ipv6 address "+new_resource.ipv6_and_mask
                    else
                        raise ArgumentError.new("wrong value for ipv6_and_mask property "+ipv6_and_mask)
                    end
                 end
             end
             hash = execute_config_command(cmd)
             if !hash[:stderr].to_s.empty?
                 raise RuntimeError.new(hash[:stderr])
             end
         end
         new_resource.ip_helper = new_resource.ip_helper.sort
         converge_if_changed :ip_helper do
             cmd = []
             cmd << "interface "+new_resource.interface_name
             add = new_resource.ip_helper - current_resource.ip_helper
             remove = current_resource.ip_helper - new_resource.ip_helper
             remove.each do |ip|
                 cmd << "no ip helper-address "+ip
             end
             add.each do |ip|
                 cmd << "ip helper-address "+ip
             end
             hash = execute_config_command(cmd)
             if !hash[:stderr].to_s.empty?
                 raise RuntimeError.new(hash[:stderr])
             end
         end
      rescue Exception => e
         Chef::Log.error e.message
      end
end

