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
# This file contains os10 global lldp command resource
# Example os10 global lldp resource
#os10_lldp "lldp_conf" do
#enable true
#holdtime_multiplier "7"
#reinit "5"
#timer "80"
#med_fast_start_repeat_count "5"
#med_network_policy [{"id"=>"2", "app"=>"voice", "vlan"=>"3", "vlan-type"=> "ta                                                                             g", "priority"=>"3", "dscp"=>"4"}]
#end

resource_name :os10_lldp
property :enable, kind_of: [TrueClass, FalseClass], default: true
property :holdtime_multiplier, String, default: "4"
property :reinit, String, default: ""
property :timer, String, default: ""
property :med_fast_start_repeat_count, String, default: "3"
property :med_network_policy, [Array, Hash], default: []

load_current_value do
      start_os10_shell("admin")
      hash = execute_show_command("show running-configuration lldp")
      value_exist = false
      if !hash[:stderr].to_s.empty?
         raise RuntimeError.new(hash[:stderr])
      end
      if !hash[:stdout].to_s.empty?
          value_exist = true
      end
      enable true
      holdtime_multiplier "4"
      reinit ""
      timer ""
      med_fast_start_repeat_count "3"
      med_network_policy []
      begin
          lldp_data = hash[:stdout].split("\n")
          med_network_policy []
          lldp_data.each do |data|
               if data.include? "enable"
                  enable false
               end
               if data.include? "holdtime"
                  holdtime_multiplier  data.split(" ")[2]
               end
               if data.include? "reinit"
                  reinit  data.split(" ")[2]
               end
               if data.include? "timer"
                  timer data.split(" ")[2] 
               end
               if data.include? "med"
                  if data.include?"fast-start-repeat-count"
                      med_fast_start_repeat_count  data.split(" ")[3]                 
                  end
                  if (data.include?"network-policy")&&(!data.include?"add")
                      policy_hash = {}
                      policy_data = data.split(" ")
                      policy_hash["id"] = policy_data[3]
                      policy_hash["app"] = policy_data[5]
                      policy_hash["vlan"] = policy_data[7]
                      policy_hash["vlan-type"] = policy_data[9]
                      policy_hash["priority"] = policy_data[11]
                      policy_hash["dscp"] = policy_data[13]
                      med_network_policy << policy_hash
                      end
               end
          end 
     end
end

action :set do
      begin
          converge_if_changed :enable do
              cmd = []
              if new_resource.enable
                  cmd << "lldp enable"
              else
                  cmd << "no lldp enable"
              end
              hash = execute_config_command(cmd)
          end 
          if new_resource.holdtime_multiplier.empty?
              new_resource.holdtime_multiplier "4"
          end
 
          converge_if_changed :holdtime_multiplier do
              cmd = []
              cmd << "lldp holdtime-multiplier "+new_resource.holdtime_multiplier
              hash = execute_config_command(cmd)
          end
          converge_if_changed :reinit do
              cmd = []
              if new_resource.reinit.empty?
                  cmd << "no lldp reinit"
              else
                  cmd << "lldp reinit "+new_resource.reinit 
              end
              hash = execute_config_command(cmd)
          end
          converge_if_changed :timer do
              cmd = []
              if new_resource.timer.empty?
                  cmd << "no lldp timer"
              else
                  cmd << "lldp timer "+new_resource.timer
              end
              hash = execute_config_command(cmd)
          end
          if new_resource.med_fast_start_repeat_count.empty?
             new_resource.med_fast_start_repeat_count "3"
          end
          converge_if_changed :med_fast_start_repeat_count do
              cmd = []
              cmd << "lldp med fast-start-repeat-count "+new_resource.med_fast_start_repeat_count
              hash = execute_config_command(cmd)
          end
          new_resource.med_network_policy = new_resource.med_network_policy.sort
          converge_if_changed :med_network_policy do
              cmd = []
              if new_resource.med_network_policy.empty?
                  if !current_resource.nil?
                      current_resource.med_network_policy.each do |policy|
                          cmd << "no lldp med network-policy "+policy["id"]
                      end
                  end
              else
                  add = new_resource.med_network_policy - current_resource.med_network_policy
                  remove = current_resource.med_network_policy - new_resource.med_network_policy
                  remove.each do |policy|
                      cmd << "no lldp med network-policy "+policy["id"]
                  end
                  add.each do |policy|
                      cmd << "lldp med network-policy "+policy["id"]+" app "+ policy["app"] + " vlan "+policy["vlan"] +
                              " vlan-type "+policy["vlan-type"] + " priority "+policy["priority"] + " dscp "+policy["dscp"]
                  end
              end
              hash = execute_config_command(cmd)
          end
      rescue Exception => e
          Chef::Log.error e.message
      end
end
