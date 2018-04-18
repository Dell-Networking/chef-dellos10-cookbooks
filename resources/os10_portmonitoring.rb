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
# This file contains os10 portmonitoring command resource
# Example os10 portmonitoring resource
#os10_portmonitoring "2" do
#source ["ethernet1/1/1","ethernet1/1/5"]
#flowbase true
#shutdown true
#action :create
#end

resource_name :os10_portmonitoring
property  :port_id, kind_of: String, name_property: true
property  :source, kind_of: Array
property  :destination, kind_of: String
property  :flowbase, [true, false], default: false
property  :shutdown, [true, false], default: false
load_current_value do
        start_os10_shell("admin")
        hash = execute_show_command("show running-configuration monitor | display-xml", 2)
        portmonitor_data = hash[:stdout]
        sessions = Hash.new
        if !portmonitor_data["rpc-reply"][:data].nil?
            allsession = portmonitor_data["rpc-reply"][:data][:sessions]
            if  allsession
                allsession = allsession[:"session"]
                if allsession && allsession.class == Hash
                    allsession = [allsession]
                end
                allsession.each do |sess|
                    id_key = sess[:"id"]
                    sessions[id_key]=sess
                end
     	    end
        end
        source []
        current_value_does_not_exist! unless sessions.key?(port_id)
        cur_sess  = sessions[port_id]
        if !cur_sess[:"source-intf"].is_a?Array
          cur_sess[:"source-intf"] = [cur_sess[:"source-intf"]]
        end
        cur_sess[:"source-intf"].each do |src|
           source << src[:name]
        end
        destination  cur_sess[:"destination-interface"]
        if cur_sess.key?(:"flow-enabled")
           flowbase  true
        end
        if !cur_sess.key?(:disable)
           shutdown  true
        end
end

action :create do
           cmd =  []
           converge_if_changed :port_id do
               cmd <<  "monitor session "+new_resource.port_id
               if !new_resource.source.nil?
                   new_resource.source.each do |src|
                      cmd << "source interface "+src
                   end
               end
               if !new_resource.destination.to_s.empty?
                   cmd << "destination interface "+new_resource.destination
               end
               if new_resource.flowbase
		   cmd << "flow-based enable"
               else
 		   cmd << "no flow-based enable"
               end
               if new_resource.shutdown
                   cmd << "shut"
               else
		   cmd << "no shut"
               end
               hash = execute_config_command(cmd)
               if !hash[:stderr].to_s.empty?
                   raise RuntimeError.new(hash[:stderr])
               end
          end
          if current_resource.nil?
              return
          end
          cmd = []
          converge_if_changed :source do
                cmd <<  "monitor session "+new_resource.port_id
                add = new_resource.source - current_resource.source
                remove = current_resource.source - new_resource.source
                remove.each do |src|
                     cmd << "no source interface "+src
                end
                add.each do |src|
                     cmd << "source interface "+src
                end
          end
          converge_if_changed :destination do
                cmd <<  "monitor session "+new_resource.port_id
                cmd << "destination interface "+new_resource.destination
          end
          converge_if_changed :flowbase do
               cmd <<  "monitor session "+new_resource.port_id
               if new_resource.flowbase
                   cmd << "flow-based enable"
               else
                   cmd << "no flow-based enable"
               end
          end
          converge_if_changed :shutdown do
               cmd <<  "monitor session "+new_resource.port_id
               if new_resource.shutdown
                   cmd << "shut"
               else
                   cmd << "no shut"
               end
          end
          if !cmd.empty?
               hash = execute_config_command(cmd)
               if !hash[:stderr].to_s.empty?
                   raise RuntimeError.new(hash[:stderr])
               end
          end
  end
action :delete do
  converge_by "Deleteing port_monitoring  #{new_resource.port_id}" do
     if current_resource.nil?
        return
     end
     cmd = Array.new 
     cmd << "no monitor session "+new_resource.port_id
     hash = execute_config_command(cmd)
     if !hash[:stderr].to_s.empty?
        raise RuntimeError.new(hash[:stderr])
     end
 end
end
