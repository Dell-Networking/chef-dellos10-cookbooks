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
# This file contains lldp interface command resource
# Example lldp interface resource
#os10_lldp_interface 'ethernet 1/1/1' do
#receive true
#transmit true
#med true
#med_network_policy ["7","8"]
#med_tlv_select_inventory true
#med_tlv_select_network_policy true
#tlvselect ({"dcbxp"=>[""],"dot1tlv"=>["link-aggregation"], "dot3tlv"=>["max-framesize", "macphy-config"]})
#end

resource_name :os10_lldp_interface
property :interface_name, String, name_property: true
property :receive, kind_of: [TrueClass, FalseClass]
property :transmit, kind_of: [TrueClass, FalseClass]
property :med, kind_of: [TrueClass, FalseClass]
property :med_network_policy, Array, default: []
property :med_tlv_select_inventory, kind_of: [TrueClass, FalseClass]
property :med_tlv_select_network_policy, kind_of: [TrueClass, FalseClass]
property :tlvselect, kind_of:Hash, default: {}

load_current_value do
      start_os10_shell("admin")
      hash = execute_show_command("show running-configuration interface #{interface_name}")
      value_exist = false
      if !hash[:stdout].to_s.empty?
          if hash[:stdout].include?"lldp"
              value_exist = true
          end
      end
      current_value_does_not_exist! unless value_exist
      begin
          intf_data = hash[:stdout].split("\n")
          tempselect = {}
          intf_data.each do |data|
               if data.include? "lldp"
                   if data.include?"receive"
                       receive false
                   else
                       receive true
                   end
                   if data.include?"transmit"
                      transmit false
                   else
                      transmit true
                   end
                   if data.include?"med"
                       if data.include?"disable"
                          med false 
                       else
                          med true 
                       end
                       if data.include?"network-policy"
                          med_network_policy data.scan(/\d/).sort
                       end
                       if data.include?"tlv-select"
                           if data.include?"inventory"
                               med_tlv_select_inventory true
                           else
                               med_tlv_select_inventory false 
                           end
                           if data.include?"network-policy"
                               med_tlv_select_network_policy false
                           else
                               med_tlv_select_network_policy true
                           end
                       end
                   end
                   if data.include?"lldp tlv-select"
                       tlv_data = data.split(" ")
                       if tlv_data.length == 4
                           tempselect[tlv_data[3]] = [""]
                       else
                           if tempselect[tlv_data[3]].nil?
			       tempselect[tlv_data[3]] = [tlv_data[4]]
                           else
                               tempselect[tlv_data[3]] = tempselect[tlv_data[3]] << tlv_data[4]
                               tempselect[tlv_data[3]] = tempselect[tlv_data[3]].sort
			   end
                       end
                   end
               end
          end 
     tlvselect tempselect
     rescue Exception => e
         Chef::Log.error e.message
     end
end

action :set do
    begin
         if !new_resource.tlvselect.nil?
           new_resource.tlvselect.each do |key, value|
             new_resource.tlvselect[key] = value.sort
           end
         end
         converge_if_changed :receive do
             cmd = []
             cmd << "interface "+new_resource.interface_name
             if new_resource.receive
                 cmd << "lldp receive"
             else
                 cmd << "no lldp receive"
             end
             hash = execute_config_command(cmd)
         end

         converge_if_changed :transmit do
             cmd = []
             cmd << "interface "+new_resource.interface_name
             if new_resource.transmit
                 cmd << "lldp transmit"
             else
                 cmd << "no lldp transmit"
             end
             hash = execute_config_command(cmd)
         end

         converge_if_changed :med do
             cmd = []
             cmd << "interface "+new_resource.interface_name
             if new_resource.med
                 cmd << "lldp med enable"
             else
                 cmd << "lldp med disable"
             end
             hash = execute_config_command(cmd)
         end
         if !new_resource.med_network_policy.nil?
           new_resource.med_network_policy = new_resource.med_network_policy.sort
         end
         if current_resource.nil?
             if !new_resource.med_network_policy.nil?
               cmd = []
               cmd << "interface "+new_resource.interface_name
               new_resource.med_network_policy.each do |policy|
                 cmd << "lldp med network-policy add "+policy
               end
               hash = execute_config_command(cmd)
             end
         else
             converge_if_changed :med_network_policy do
                 cmd = []
                 cmd << "interface "+new_resource.interface_name
                 add = []
                 remove = []
                 if new_resource.med_network_policy.nil?
                   remove = new_resource.med_network_policy
                 else
                   add = new_resource.med_network_policy - current_resource.med_network_policy
                   remove = current_resource.med_network_policy - new_resource.med_network_policy
                 end
                 add.each do |policy|
                     cmd << "lldp med network-policy add "+policy
                 end
                 remove.each do |policy|
                     cmd << "lldp med network-policy remove "+policy
                 end
                 hash = execute_config_command(cmd)
             end
         end
         converge_if_changed :med_tlv_select_inventory do
             cmd = []
             cmd << "interface "+new_resource.interface_name
             if new_resource.med_tlv_select_inventory
                 cmd << "lldp med tlv-select inventory"
             else
                 cmd << "no lldp med tlv-select inventory"
             end
             hash = execute_config_command(cmd)
         end

         converge_if_changed :med_tlv_select_network_policy do
             cmd = []
             cmd << "interface "+new_resource.interface_name
             if new_resource.med_tlv_select_network_policy
                 cmd << "lldp med tlv-select network-policy"
             else
                 cmd << "no lldp med tlv-select network-policy"
             end
             hash = execute_config_command(cmd)
         end

         converge_if_changed :tlvselect do
             if !new_resource.tlvselect.empty? &&
                 !current_resource.nil? &&
                 !current_resource.tlvselect.empty?
                 new_resource.tlvselect.each do |key, value|
                     disable = new_resource.tlvselect[key] - current_resource.tlvselect[key]
                     enable = current_resource.tlvselect[key] - new_resource.tlvselect[key]
                     cmd = []
                     cmd << "interface "+new_resource.interface_name
                     disable.each do |capabilities|
                         cmd << "no lldp tlv-select "+key+" "+capabilities
                     end             
                     enable.each do |capabilities|
                         cmd << "lldp tlv-select "+key+" "+capabilities
                     end
                     hash = execute_config_command(cmd)
                 end
              elsif !current_resource.nil? && 
                      !current_resource.tlvselect.empty?
                  current_resource.tlvselect.each do |key, value|
                     enable = current_resource.tlvselect[key]
                     cmd = []
                     cmd << "interface "+new_resource.interface_name
                     enable.each do |capabilities|
                         cmd << "lldp tlv-select "+key+" "+capabilities
                     end
                     hash = execute_config_command(cmd)
                 end
              elsif !new_resource.tlvselect.empty?
                  new_resource.tlvselect.each do |key, value|
                      disable = new_resource.tlvselect[key]
                      cmd = []
                      cmd << "interface "+new_resource.interface_name
                      disable.each do |capabilities|
                          cmd << "no lldp tlv-select "+key+" "+capabilities
                      end
                      hash = execute_config_command(cmd)
                  end
             end
         end
    rescue Exception => e
        Chef::Log.error e.message
    end
end
