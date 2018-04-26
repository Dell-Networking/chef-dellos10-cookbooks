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
# This file contains os10 snmp command resource
# Example os10 snmp resource
# os10_snmp "snmp_conf" do
# location ""
# contact  "abc"
# community ["private"]
# trap []
# host [{"version"=>"1", "community"=>"public","ip"=>"2.2.2.2", "port"=>"162"},{"community" => "public", "ip"=>"1.1.1.1","port"=>"162", "version"=>"2c"}]
# end

resource_name :os10_snmp
property :location, kind_of: String
property :contact, kind_of: String
property :community, kind_of: Array
property :trap, kind_of: [Array, Hash]
property :host, kind_of: [Array, Hash]

load_current_value do
      start_os10_shell("admin")
      cmd = "show running-configuration | grep snmp"
      hash = execute_show_command(cmd)
      if !hash[:stderr].to_s.empty?
         raise RuntimeError.new(hash[:stderr])
      end
      if !hash[:stdout].to_s.empty?
          value_exist = true
      end
      current_value_does_not_exist! unless value_exist
      begin
          snmp_data = hash[:stdout].split("\n")
          community []
          trap []
          host []     
          snmp_data.each do |data|
              if data.include? "location"
                  location  data.split(" ")[2]
              end
              if data.include? "contact"
                  contact  data.split(" ")[2]
              end
              if data.include? "community"
                  community << data.split(" ")[2]
              end
              if data.include? "enable trap"
                 trap_hash = {}
 	         trap_hash[data.split(" ")[3]] = data.split(" ")[4]
                 trap << trap_hash
              end
              if data.include? "host"
                 host_hash = {}
                 host_data = data.split(" ")
                 host_hash["ip"] = host_data[2]
                 host_hash["version"] = host_data[5]
                 host_hash["community"] = host_data[6]
                 host_hash["port"] = host_data[8]
                 host << host_hash              
 	      end
          end
          if location.nil?
              location ""
          end
          if contact.nil?
             contact ""
          end
          community community.sort
          trap trap.sort_by{|item| item.keys}
          host host.sort_by{|item| item.keys}
      rescue Exception => e
          Chef::Log.error e.message
      end
end

action :set do
   begin
      if property_is_set?(:location)
        converge_if_changed :location do
          cmd = []
          if new_resource.location.empty?
             cmd <<"no snmp-server location "+ new_resource.location
          else
             cmd << "snmp-server location "+ new_resource.location
          end
          hash = execute_config_command(cmd)
        end
      end
      if property_is_set?(:contact)
        converge_if_changed :contact do
          cmd = []
          if new_resource.contact.empty?
              cmd << "no snmp-server  contact "+ new_resource.contact
          else
              cmd << "snmp-server  contact "+ new_resource.contact
          end
          hash = execute_config_command(cmd)
        end
      end
      if property_is_set?(:community)
        new_resource.community = new_resource.community.sort
        converge_if_changed :community do
          cmd = []
          add = new_resource.community - current_resource.community
          remove = current_resource.community - new_resource.community
          remove.each do |cm|
              cmd << "no snmp-server community "+cm
          end
          add.each do |cm|
              cmd << "snmp-server community "+cm+" ro"
          end
          hash = execute_config_command(cmd)
        end
      end
      if property_is_set?(:trap)
        new_resource.trap  new_resource.trap.sort_by{|item| item.keys}
        converge_if_changed :trap do
          cmd = []
          add = new_resource.trap - current_resource.trap
          remove = current_resource.trap - new_resource.trap
          remove.each do |tp|
              cmd <<"no snmp-server enable traps "+tp.keys[0]+" "+tp.values[0]
          end 
          add.each do |tp|
              cmd <<"snmp-server enable traps "+tp.keys[0]+" "+tp.values[0]
          end
          hash = execute_config_command(cmd)
        end
      end
      if property_is_set?(:host)
        new_resource.host  new_resource.host.sort_by{|item| item.keys}
        converge_if_changed :host do
          cmd = []
          add = new_resource.host - current_resource.host
          remove = current_resource.host - new_resource.host
          remove.each do |ht|
              cmd << "no snmp-server host "+ht["ip"]+" traps version "+ht["version"]+" "+ht["community"] +
                     " udp-port "+ ht["port"]
          end
          add.each do |ht|
              cmd << "snmp-server host "+ht["ip"]+" traps version "+ht["version"]+" "+ht["community"] +
                     " udp-port "+ ht["port"]
          end
          hash = execute_config_command(cmd)
        end
      end
   rescue Exception => e
       Chef::Log.error e.message
   end
end

