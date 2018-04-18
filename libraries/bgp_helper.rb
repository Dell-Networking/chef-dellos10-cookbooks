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

# The bgp module has the utility API's needed for Chef BGP resources
module BgpHelper
  ROUTER_BGP = 'router bgp '.freeze
  ROUTER_BGP_NEG = 'no router bgp'.freeze
  ROUTER_ID = 'router-id '.freeze
  ROUTER_ID_NEG = 'no router-id'.freeze
  MAXPATH_EBGP = 'maximum-paths ebgp '.freeze
  MAXPATH_IBGP = 'maximum-paths ibgp '.freeze
  BESTPATH_ASPATH = 'bestpath as-path '.freeze
  BESTPATH_MED_CONFED = 'bestpath med confed'.freeze
  BESTPATH_MED_MIS_AS_WORST = 'bestpath med missing-as-worst'.freeze
  BESTPATH_IGN_ROUTERID = 'bestpath router-id ignore'.freeze
  OUTBOUND_OPT = 'outbound-optimization'.freeze
  FAST_EXT_FAILOVER = 'fast-external-fallover'.freeze
  LOG_NBR_CHANGES = 'log-neighbor-changes'.freeze
  NEIGHBOR = 'neighbor '.freeze
  REMOTE_AS = 'remote-as '.freeze
  PASSWD = 'password '.freeze
  ADV_START = 'advertisement-start '.freeze
  ADV_INTERVAL = 'advertisement-interval '.freeze
  CON_RETY_TIMER = 'connection-retry-timer '.freeze
  SEND_COMM_EXT = 'send-community extended'.freeze
  SEND_COMM_STD = 'send-community standard'.freeze
  REMOTE_PRIVATE_AS = 'remove-private-as'.freeze
  SHUTDOWN = 'shutdown'.freeze
  SHUTDOWN_NEG = 'no shutdown'.freeze
  AF_IPV4 = 'address-family ipv4 unicast'.freeze
  AF_IPV6 = 'address-family ipv6 unicast'.freeze
  ACTIVATE = 'no activate'.freeze
  ALLOWAS_IN = 'allowas-in '.freeze
  DEF_METRIC = 'default-metric '.freeze
  REDISTRIBUTE_CONNECT = 'redistribute connected '.freeze
  REDISTRIBUTE_STATIC = 'redistribute static '.freeze
  REDISTRIBUTE_OSPF = 'redistribute ospf '.freeze
  INHERIT_TEMPLATE = 'inherit template '.freeze
  NEIGHBOR_ = 'neighbor '.freeze
  TEMPLATE = 'template '.freeze
  SHOW_BGP_CONFIG = 'show running-configuration bgp | display-xml'.freeze
  DEFAULT_MAX_PATH = '64'.freeze

  ##
  # This API process the ruby hash and extracts the enum value for the
  # given key.
  #
  # @param [bgp_data] <hash>    The bgp running-config from the switch.
  # @param [key]      <String>  The input hash key
  #
  # @return [true/false]
  #

  def extract_enum_value(bgp_data, key)
    return false if bgp_data[key] && bgp_data[key] == 'false'
    true
  end

  ##
  # This API process the ruby hash and extracts the integer value for the
  # given key. It also converts the string to integer format
  #
  # @param [bgp_data] <hash>         The bgp running-config from the switch.
  # @param [key]      <String>       The input hash key
  # @param [default_value] <Integer> Default value for the CLI
  #
  # @return [value]  The integer value of the key
  #

  def extract_num_value(bgp_data, key, default_value)
    bgp_data && bgp_data[key] && bgp_data[key].to_i || default_value
  end

  ##
  # This API process the ruby hash and extracts the string value for the
  # given key. It also converts the string to integer format
  #
  # @param [bgp_data] <hash>         The bgp running-config from the switch.
  # @param [key]      <String>       The input hash key
  # @param [default_value] <Integer> Default value for the CLI
  #
  # @return [value]  The string value of the key
  #

  def extract_string_value(bgp_data, key, default_value)
    bgp_data && bgp_data[key] || default_value
  end

  ##
  # Utility API to validate the ASN number is in accepted range or not
  #
  # @param [asn_num] <String>        The ASN number
  #
  # @return [None]
  #

  def check_asn_range(asn_num)
    raise 'ASN Number is NULL' if asn_num.nil?

    new_asn_num = asn_num.to_f
    if !(new_asn_num >= 1 && new_asn_num <= 65_535.65535) ||
       !(new_asn_num >= 1 && new_asn_num <= 4_294_967_295)
      raise 'The ASN num value ' + asn_num + \
            ' is not in range of 1..65535 or 1..4294967295'
    end
  end

  ##
  # Utility API to check if the ASN number matches the configured value and
  # and test its range.
  #
  # @param [current_config] <property>  The current config in switch
  # @param [new_config]     <property>  The config given by Chef user
  #
  # @return [None]
  #

  def asn_valid(new_config)
    # This case will not happen. This is just a cosmetic check
    return if new_config.nil?

    raise 'ASN Number is NULL' if new_config.asn_num.nil?

    check_asn_range(new_config.asn_num)
  end

  def assign_asn_vrf(bgp_data)
    # Assign the corresponding property values if present in config output
    asn_num bgp_data[:'local-as-number'] if bgp_data[:'local-as-number']
    vrf bgp_data[:'vrf-name'] if bgp_data[:'vrf-name']
  end

  def bgp_data_valid(bgp)
    return true if extract(bgp, 'rpc-reply', :data, :'bgp-router')
    # If there is no BGP CLI's configured return from the API
    Chef::Log.debug 'BGP CLI is not configured'
    false
  end

  ##
  # This API takes the propery and cli string. Based on the property
  # assignment from the user returns the cli string or no form string.
  # given key.
  #
  # @param [property]    <RubyType> The bgp property given by user
  # @param [cli_string]  <String>   The CLI string
  # @param [output_cli]  <String>   Based on the property it can be
  #                                 delete/create CLI
  #
  #
  # @return [cli_cmd] The CLI command for the property
  #

  def set_cli_command(property, cli_string, output_cli)
    # The property can be nil
    return if property.nil?
    # The property takes true or false
    output_cli << (property ? cli_string : 'no ' + cli_string)
  end

  ##
  # Extracts all the best path parameters from a ruby hash and assign them
  # to the chef property variables
  #
  # @param [bgp_data] <hash> The bgp running-config from the switch.
  #
  # @return [None]
  #

  def extract_bestpath_details(bgp_data)
    return if bgp_data.nil? || bgp_data[:bestpath].nil?

    bgp_best_path = bgp_data[:bestpath]
    return if bgp_best_path.nil? || bgp_best_path.empty?
    if bgp_best_path.key? :'aspath-multipath-relax'
      bestpath_as_path 'multipath-relax'
    end
    if bgp_best_path.key? :'aspath-ignore'
      bestpath_as_path 'ignore'
    end
    if bgp_best_path.key? :'med-confed'
      bestpath_med_confed true
    else
      bestpath_med_confed false
    end
    if bgp_best_path.key? :'missing-as-best'
      bestpath_med_missing_as_worst true
    else
      bestpath_med_missing_as_worst false
    end
    if bgp_best_path.key? :'ignore-routerid'
      bestpath_ignore_router_id true
    else
      bestpath_ignore_router_id false
    end
  end

  ##
  # Utility API to set the peer details to the corresponding BGP peer properties
  #
  # @param [peer_config_data]  BGP peer config data
  #
  # @return [None]
  #

  def assign_peer_data(peer_config_data)
    return if peer_config_data.nil?

    if peer_config_data[:timers]
      keepalive = extract(peer_config_data, :timers, :'config-keepalive')
      hold_time = extract(peer_config_data, :timers, :'config-hold-time')
      timers ({ keepalive: keepalive.to_i, hold_time: hold_time.to_i })
    end

    remote_as peer_config_data[:'remote-as'] if peer_config_data[:'remote-as']

    password  peer_config_data[:password] if peer_config_data[:password]

    advertisement_start peer_config_data[:'advertisement-start'] \
                           if peer_config_data[:'advertisement-start']

    advertisement_interval peer_config_data[:'advertisement-interval'] \
      if peer_config_data[:'advertisement-interval']

    connection_retry_timer peer_config_data[:'connection-retry-timer'] \
      if peer_config_data[:'connection-retry-timer']

    send_community_ext (peer_config_data[:'send-community-extended'] && \
      peer_config_data[:'send-community-extended'] == 'true' ? true : false)

    send_community_std (peer_config_data[:'send-community-standard'] && \
      peer_config_data[:'send-community-standard'] == 'true' ? true : false)

    remove_private_as (peer_config_data[:'remove-private-as'] && \
      peer_config_data[:'remove-private-as'] == 'true' ? true : false)
  end

  ##
  # Utility API to get the BGP config
  #
  # @param [None]
  #
  # @return [bgp_data] bgp vrf config
  #

  def read_bgp_details
    ret = exec_show_cmd(SHOW_BGP_CONFIG)
    # Get the BGP configured command output
    bgp = ret[:stdout]
    Chef::Log.debug bgp
    if bgp_data_valid(bgp) == false
      Chef::Log.debug 'The BGP does not have any configured CLI'
      return nil
    end
    extract(bgp, 'rpc-reply', :data, :'bgp-router', :vrf)
  end

  ##
  # Utility API to get the proper ASN number and validate it
  #
  # @param [new_config] <Hash> The new resource from chef
  #
  # @return [new_asn] <String> The ASN number
  #

  def get_valid_asn(new_config)
    new_asn = new_config.asn_num unless new_config.nil?
    raise 'ASN Number is NULL' if new_asn.nil?
    new_asn
  end

  ##
  # Utility API to set neighbor timer CLI and validates the input
  #
  # @param [set_timer_config] <Hash> The neighbor timer config
  #
  # @param [cli_array] <Array>  Output CLI buffer
  #
  # @return [None]
  #

  def set_peer_timer(set_timer_config, cli_array)
    return if set_timer_config.nil?

    if set_timer_config.empty?
      cli_array << 'no timers'
      return
    end
    if !set_timer_config[:keepalive]
      raise 'Keepalive key is mandatory parameter for timer property'
    elsif !set_timer_config[:hold_time]
      raise 'Hold_time key is mandatory parameter for timer property'
    end

    keepalive = set_timer_config[:keepalive]
    hold_time = set_timer_config[:hold_time]
    raise 'Keepalive should be Integer' if keepalive.class != Integer
    raise 'Hold_time should be Integer' if hold_time.class != Integer

    if keepalive >= 1 && keepalive <= 65_535 &&
       hold_time >= 3 && hold_time <= 65_535
      cli_array << 'timers ' + keepalive.to_s + ' ' + \
                   hold_time.to_s
    else
      unless keepalive >= 1 && keepalive <= 65_535
        raise 'The keepalive timer value ' + keepalive + \
              ' is not in range of 1 - 65_535'
      end
      unless hold_time >= 3 && hold_time <= 65_535
        raise 'The hold_time timer value ' + hold_time + \
              ' is not in range of 3 - 65535'
      end
    end
  end

  ##
  # Utility API to set advertisement start CLI and validates the input
  #
  # @param [adv_start_config] <Integer> Delay initiating OPEN message for
  #                                     the specified time
  #
  # @param [cli_array] <Array>  Output CLI buffer
  #
  # @return [None]
  #

  def set_peer_adv_start(adv_start_config, cli_array)
    return if adv_start_config.nil?

    if adv_start_config.empty?
      cli_array << 'no ' + ADV_START
    else
      int_adv_start_config = adv_start_config.to_i
      if int_adv_start_config >= 0 &&
         int_adv_start_config <= 240
        cli_array << ADV_START + adv_start_config
      else
        raise 'The advertisement_start value ' + \
              adv_start_config + \
              ' is not in range of 0 - 240'
      end
    end
  end

  ##
  # Utility API to set advertisement interval CLI and validates the input
  #
  # @param [adv_start_config] <Integer> Minimum interval between sending
  #                                      BGP routing updates
  #
  # @param [cli_array] <Array>  Output CLI buffer
  #
  # @return [None]
  #

  def set_peer_adv_interval(adv_interval_config, cli_array)
    return if adv_interval_config.nil?

    if adv_interval_config.empty?
      cli_array << 'no ' + ADV_INTERVAL
    else
      int_adv_interval_config = adv_interval_config.to_i
      if int_adv_interval_config >= 1 &&
         int_adv_interval_config <= 600
        cli_array << ADV_INTERVAL + adv_interval_config.to_s
      else
        raise 'The advertisement_interval value ' + \
              adv_interval_config + \
              ' is not in range of 1 - 600'
      end
    end
  end

  ##
  # Utility API to set connection rety timer CLI and validates the input
  #
  # @param [conn_retry_timer] <Integer> Peer connection retry timer
  #
  # @param [cli_array] <Array>  Output CLI buffer
  #
  # @return [None]
  #

  def set_peer_retry_timer(conn_retry_timer, cli_array)
    return if conn_retry_timer.nil?
    if conn_retry_timer.empty?
      cli_array << 'no ' + CON_RETY_TIMER
    else
      int_conn_retry_timer = conn_retry_timer.to_i
      if int_conn_retry_timer >= 10 &&
         int_conn_retry_timer <= 65_535
        cli_array << CON_RETY_TIMER + conn_retry_timer.to_s
      else
        raise 'The connection_retry_timer value ' + \
              conn_retry_timer.to_s + \
              ' is not in range of 10 - 65535'
      end
    end
  end

  ##
  # Utility API to set password and validates the input
  #
  # @param [set_passwd] <String> Set password
  #
  # @param [cli_array] <Array>  Output CLI buffer
  #
  # @return [None]
  #

  def set_peer_password(set_passwd, cli_array)
    return if set_passwd.nil?
    if set_passwd.length > 128
      raise 'The password length should be <= 128'
    end
    cli_array << (set_passwd.empty? ? \
      ('no ' + PASSWD + " \" \"") : PASSWD + set_passwd)
  end

  ##
  # Utility API to set remote AS and validates the input
  #
  # @param [set_remote_as] <Integer> Remote ASN number
  #
  # @param [cli_array] <Array>  Output CLI buffer
  #
  # @return [None]
  #

  def set_peer_remote_as(set_remote_as, cli_array)
    return if set_remote_as.nil?
    if set_remote_as.empty?
      cli_array <<  'no ' + REMOTE_AS
    else
      int_remote_as = set_remote_as.to_i
      if int_remote_as >= 1 &&
         int_remote_as <= 4_294_967_295
        cli_array << REMOTE_AS + set_remote_as.to_s
      else
        raise 'The remote_as value ' + set_remote_as.to_s + \
              ' is not in range of 1..65535 or 1..4294967295'
      end
    end
  end
end
Chef::Resource.send(:include, BgpHelper)
