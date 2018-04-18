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
# This file contains os10 imageupgrade command resource
# Example os10 imageupgrade resource
# os10_imageupgrade 'scp://root:force10@10.16.138.27/root/PKGS_OS10-Enterprise-10.3.9999E.X.6820-installer-x86_64.bin' do
# action 'set'
# end

resource_name :os10_imageupgrade
property :url, kind_of: String, name_property: true

load_current_value do
        start_os10_shell("admin")
end

action :set do
       begin

           hret = execute_show_command("show image status | display-xml")
           status = hret[:stdout]['rpc-reply'][:data][:'system-sw-state']
           state = status[:'software-upgrade-status'][:'global-state']

          if state != 'idle'
            raise "Installer state is #{state}. Aborting Download!"
          end

          command = execute_show_command("image install #{url}")

          # Periodically check for the status of download
          oldstate = state
          loop do
              hret = execute_show_command("show image status | display-xml")
              status = hret[:stdout]['rpc-reply'][:data][:'system-sw-state']
              state = status[:'software-upgrade-status'][:'global-state']
              perc = status[:'software-upgrade-status'][:'file-transfer-status'][:'file-progress']
              insst = status[:'software-upgrade-status'][:'software-install-status'][:'task-state-detail']
              if oldstate != state
                  Chef::Log.info "Installer state changed from #{oldstate} to #{state}" 
                  if state == 'idle'
                      Chef::Log.debug "Breaking out from loop during #{oldstate} to #{state} transition"
                      break
                  end
                  oldstate = state
               end
               sleep(1)                      
          end

           # Now that installer is idle, check for State Detail of both File Transfer
           # and Installation State before changing the boot partition. User can reload
           # the switch at a later point of time.

           stat1 = status[:"software-upgrade-status"][:"file-transfer-status"][:"task-state-detail"]
           stat2 = status[:"software-upgrade-status"][:"software-install-status"][:"task-state-detail"]

           if stat1 == 'Completed: No error' and stat2 == 'Completed: Success'
              Chef::Log.debug "Download state is #{stat1}"
              Chef::Log.debug "Install state is #{stat2}"
              Chef::Log.info "reloading to standby partition"
              execute_exec_command(["boot system standby"])
              execute_exec_command(["write memory"])
           else
              Chef::Log.error "Download and Install states are #{stat1} and #{stat2}"         
              raise 'Install failed!'
           end

       rescue Exception => e
           Chef::Log.error e.message
           raise
       end
  end

action :get do
    begin
      cmd = 'show version | grep OS | grep Version'
      hash = execute_show_command(cmd)
      print hash[:stdout]
    rescue Exception => e
        Chef::Log.error e.message
   end
end


