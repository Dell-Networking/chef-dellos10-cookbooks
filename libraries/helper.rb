# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# Author::     Ravi Shankar (ravi_sabapathy@dell.com)
# Copyright::  Copyright (c) 2017, Dell Inc. All rights reserved.
# License::    [Apache License] (http://www.apache.org/licenses/LICENSE-2.0)
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# This file contains BGP global command resource

# The Helper module contains utility API needed for CHef resources
module Helper
  $LOAD_PATH.unshift File.expand_path('/opt/dell/os10/bin/devops',  __FILE__)
  require 'dellos10_shell.rb'

  ##
  # Helper API to extract value for the give hash and key
  #
  # @param [hash_data] <Hash> The input hash data
  #
  # @param [keys] <keys> The variable number of keys to search
  #
  # @return [value] <String> The value corresponding for a hash key
  #

  def extract(hash_data, *keys)
    value = nil
    return value if hash_data.nil?
    begin
      keys.each do |k|
        value = hash_data[k]
        break if value.class != Hash
        hash_data = value
      end
      value
    rescue StandardError => e
      Chef::Log.error "Exception in #{__method__}"
      Chef::Log.error e.message
      Chef::Log.error e.backtrace[0]
      nil
    end
  end

  ##
  # Wrapper API for exec_config_cmd with exception handling
  #
  # @param [cmd] <String> The show command to execure
  #
  # @return [cfg_output] <String> The config command output from OS10
  #

  def exec_config_cmd(cmd, timeout = 1)
    begin
      cfg_output = execute_config_command(cmd, timeout)
      unless cfg_output[:stdout].to_s.empty?
        Chef::Log.debug cfg_output[:stdout]
      end
      unless cfg_output[:stderr].to_s.empty?
        Chef::Log.error cfg_output[:stderr]
      end
      cfg_output
    rescue StandardError => e
      Chef::Log.error e.message
      Chef::Log.error e.backtrace[0]
      raise
    end
  end

  ##
  # Wrapper API for exec_show_cmd with exception handling
  #
  # @param [cmd] <String> The show command to execure
  #
  # @return [show_output] <Hash> The show command output from OS10
  #

  def exec_show_cmd(cmd, timeout = 1)
    begin
      show_output = execute_show_command(cmd, timeout)
      unless show_output[:stdout].to_s.empty?
        Chef::Log.debug show_output[:stdout]
      end
      unless show_output[:stderr].to_s.empty?
        Chef::Log.error show_output[:stderr]
      end
      show_output
    rescue StandardError => e
      Chef::Log.error e.message
      Chef::Log.error e.backtrace[0]
      raise
    end
  end

  ##
  # Utility API user given peer group is present in config or not
  #
  # @param [search_data] <hash/array data> The input search buffer
  #
  # @param [context_key] <key>  The context key inside the search buffer
  #
  # @param [search_key] <key>   The sub key inside the context key data
  #
  # @param [search_key_value] <String> The value to search and match
  #
  # @return [true, false] true if present in config
  #                       false if not present in config
  #

  def is_value_present(search_data, context_key, search_key, search_key_value)
    output_data = nil
    is_present = false

    return { present: is_present, data: output_data } if search_data.nil?

    key_data = search_data[context_key]
    return { present: is_present, data: output_data } if key_data.nil?

    if key_data.class == Hash
      if key_data[search_key] &&
         key_data[search_key] == search_key_value
        is_present = true
        output_data = key_data
      end
    else
      key_data.each do |data|
        if extract(data, search_key) == search_key_value
          is_present = true
          output_data = data
        end
      end
    end
    { present: is_present, data: output_data }
  end

  def is_valid_address(ip_addr)
    !(IPAddr.new(ip_addr) rescue nil).nil?
  end
end
Chef::Recipe.send(:include, Helper)
Chef::Resource.send(:include, Helper)
Chef::Provider.send(:include, Helper)
