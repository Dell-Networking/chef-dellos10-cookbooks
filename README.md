# dellos10-cookbook

[![Cookbook Release]](https://supermarket.chef.io/cookbooks/dellos10-cookbook)

--
## Table of Contents

1. [Overview](#overview)
2. [Cookbook Description](#cookbook-description)
3. [Setup](#setup)
4. [Usage](#usage)
5. [Requirements](#requirements)
   * [Chef Requirements](#chef-requirements)
6. [Resource Reference](#resource-reference)
   * [Resource Catalog ](#resource-by-name)
7. [Learning Resources](#learning-resources)



## Overview

The `dellos10-cookbook` allows a network administrator to manage Dell OS10 switch using Chef. This cookbook bundles a set of Chef Resources, Sample Recipes and installation Tools for effective network management.  The resources and capabilities provided by this cookbook will grow with contributions from Dell, Chef Software Inc., and the open source community.
The [Chef Requirements](#chef-requirements) section provides details on compatible Chef client.

This GitHub repository contains the latest version of the dellos10-cookbook source code. Supported versions of the dellos10-cookbook are available at Chef Supermarket. Please refer to [SUPPORT] for additional details.

Contributions to this cookbook are welcome. Guidelines on contributions to the cookbook are captured in [CONTRIBUTING]

## Cookbook Description

This cookbook enables management of supported Dell OS10 using Chef. This cookbook enhances the Chef DSL by introducing new Chef Resources capable of managing network elements.

## Setup

### Chef Server

The `dellos10-cookbook` is installed on the Chef server. Please see [The Chef Server](https://docs.chef.io/server/) for information on Chef server setup. See Chef's [knife cookbook site](https://docs.chef.io/knife_cookbook_site.html) for general information on Chef cookbook installation.

### Chef Client
The Chef Client (agent) requires installation and setup on each device. Agent setup can be performed as a manual process or it may be automated. For more information please see the [README-agent-install] document for detailed instructions on agent installation and configuration on Dell OS10 devices.

### Gems

The dellos10-cookbook has dependencies on a few ruby gems. These gems are already installed in the cookbook as vendored gems so there are no additional steps required for installing these gems. The gems are shown here for reference only:


## Usage

Place a dependency on dellos10-cookbook in your cookbook's metadata.rb

```ruby
depends 'dellos10-cookbook', '~> 1.0'
```

See the recipes directory for example usage of dellos10 providers and resources.

## Requirements

### Chef Requirements

Dell OS10 Chef implementation requires Chef version 12.6.0

## Resource Reference
* [`dellos10_bgp`](#type-dellos10_bgp)
* [`dellos10_bgp_af`](#type-dellos10_bgp_af)
* [`dellos10_bgp_nbr`](#type-dellos10_bgp_nbr)
* [`dellos10_bgp_nbr_group`](#type-dellos10_bgp_nbr_group)
* [`dellos10_imageupgrade`](#type-dellos10_imageupgrade)
* [`dellos10_interface`](#type-dellos10_interface)
* [`dellos10_lldp`](#type-dellos10_lldp)
* [`dellos10_lldp_interface`](#type-dellos10_lldp_interface)
* [`dellos10_portmonitoring`](#type-dellos10_portmonitoring)
* [`dellos10_route`](#type-dellos10_route)
* [`dellos10_snmp`](#type-dellos10_snmp)

### Resource Details

The following resources are listed alphabetically.

#### Type: dellos10_bgp

The `dellos10_bgp` resource is used to manage global parameters of BGP protocol.

| Minimum Requirements |OS10 |
|----------------------|:---:|
| OS Image | 10.4 |
| Dell OS10 Cookbook Version | 1.0.0 |

**Examples**

```ruby
bgp 'default' do
 asn_num '200'
 router_id '4.4.4.4'
 maxpath_ibgp '73'
 maxpath_ebgp '91'
 bestpath_as_path 'multipath-relax'
 bestpath_med_confed true
 bestpath_med_missing_as_worst true
 bestpath_ignore_router_id true
 outbound_optimization false
 fast_ext_fallover false
 log_neighbor_changes false
 action :create
end

bgp 'default' do
 asn_num '200'
 action :delete
end

```

**Parameters**

| Property         | Type                      | Description                                             |
|------------------|---------------------------|---------------------------------------------------------|
| ``asn_num`` | String        | The Autonomous system number. The value should be 0.1..65535.65535 or 1..4294967295*|
| ``router_id``| String  | Override configured router identifier                                  |
| ``maxpath_ibgp``| String  | Forward packets over multiple paths for IBGP. The value should be between 1-128 with default value 64*|
| ``maxpath_ebgp``| String  | Forward packets over multiple paths for EBGP. The value should be between 1-128 with default value 64* |
| ``bestpath_as_path``| String  | AS path for best path computation. This property can take ignore or multipath-relax as options|
| ``bestpath_med_confed``| boolean   | bestpath selection for MED attribute. Compare MED among confederation paths                                 |
| ``bestpath_med_missing_as_worst``| boolean   | bestpath selection for MED attribute.Treat missing MED as the least preferred one|
| ``bestpath_ignore_router_id``| boolean   | Router identifier for best path computation |
| ``outbound_optimization``| boolean   | Enables outbound optimization for IBGP Peer-group members |
| ``fast_ext_fallover``| boolean   | Immediately reset session if a link to a directly connected external peer goes down(default)|
| ``log_neighbor_changes``| boolean   | Log neighbor up/down and reset reason(default)|

**Actions**

- `:create` - Creates or updates the BGP global properties.
- `:Delete` - Deletes the BGP global properties.

```ruby
* The Integer values should be entered in string format
```


#### Type: dellos10_bgp_af

The `dellos10_bgp_af` resource is used to manage global address family parameters of BGP protocol.

| Minimum Requirements |OS10 |
|----------------------|:---:|
| OS Image | 10.4 |
| Dell OS10 Cookbook Version | 1.0.0 |

**Examples**

```ruby
bgp_af 'ipv4-unicast' do
 asn_num '200'
 address_family 'ipv4-unicast'
 default_metric '300'
 redistribute_connected ({enable:true, 'route-map':'t7'})
 redistribute_static ({enable:true, 'route-map':'t8'})
 redistribute_ospf ({id:20, 'route-map':'t9'})
 network_add_list [ {:prefix=>'2.2.2.2/24', :'route-map'=>'t9'},  {:prefix=>'3.3.3.3/24', :'route-map'=>'t9'}]
 action :create
end

bgp_af 'ipv4-unicast' do
 asn_num '200'
 address_family 'ipv4-unicast'
 action :delete
end

```

**Parameters**

| Property         | Type                      | Description                                             |
|------------------|---------------------------|---------------------------------------------------------|
| ``asn_num`` | String        | The Autonomous system number. The value should be 0.1..65535.65535 or 1..4294967295*  |
| ``address_family``| String  | The address family mode. It will take ipv4 or ipv6 unicast |
| ``default_metric``| String  | Set metric of redistributed routes. The value should be between 1-4294967295* |
| ``redistribute_connected``| Hash  | Redistribute Connected Routes. The hash contains enable and route-map. The enable key is mandatory|
| ``redistribute_static``| Hash  | Redistribute Static Routes. The hash contains enable and route-map. The enable key is mandatory |
| ``redistribute_ospf``| Hash  | Redistribute OSPF Routes. The hash contains ospf ID and route map. The ospf ID is mandatory. The OSPF instance or ID should be created before executing this property|
| ``network_add_list``| Array of Hash | Enable routing on an IP network. Each hash in the array contains network address and route map. The network address is mandatory parameter|

**Actions**

- `:create` - Creates or updates the BGP address family properties.
- `:Delete` - Deletes the BGP address family properties.

```ruby
* The Integer values should be entered in string format
```

### Type: dellos10_bgp_nbr

The `dellos10_bgp_nbr` resource is used to manage neighbor configuration of BGP protocol.

| Minimum Requirements |OS10 |
|----------------------|:---:|
| OS Image | 10.4 |
| Dell OS10 Cookbook Version | 1.0.0 |

**Examples**

```ruby
bgp_nbr '9.9.9.9' do
 asn_num '200'
 advertisement_interval '600'
 advertisement_start '50'
 timers ({keepalive: 50, hold_time: 70})
 connection_retry_timer '70'
 remote_as '300'
 remove_private_as true
 shutdown false
 password 'devops'
 send_community_ext true
 send_community_std true 
 associate_peer_group 'tr1'
 address_family 'ipv4-unicast'
 allowas_in '10'
 action :create
end

bgp_nbr '9.9.9.9' do
 asn_num '200'
 address_family 'ipv4-unicast'
 action :delete
end

```

**Parameters**

| Property         | Type                      | Description                                             |
|------------------|---------------------------|---------------------------------------------------------|
| ``asn_num`` | String        | The Autonomous system number. The value should be 0.1..65535.65535 or 1..4294967295*  |
| ``peer_config``| String  | Neighbor router address|
| ``advertisement_interval``| String  | Minimum interval between sending BGP routing updates. The value should be between 1-600 with default value 30*|
| ``advertisement_start``| String  | Delay initiating OPEN message for the specified time. The value should be between 0-240* |
| ``timer``| Hash | Adjust routing timers keepalive and holdtime value. The Hash contains keepalive and holdtimer value. The keepalive value should be between 1-65535 with default value is 60. The hold timer should be between 3-65535 with default value of 180. The values are of type Integer.|
| ``connection_retry_timer``| String  | Peer connection retry timer. The value should be between 10-65535 with default default of 60*|
| ``remote_as``| String  | AS of remote BGP neighbor. The value should be 0.1..65535.65535 or 1..4294967295*|
| ``remove_private_as``| Boolean  | Remove private AS number from outbound updates|
| ``shutdown``| Boolean  | Enable r disable the neighbor|
| ``password``| String  | Set password|
| ``send_community_ext``| Boolean  | Neighbor's extended community attribute|
| ``send_community_std``| Boolean  | Neighbor's standard community attribute|
| ``associate_peer_group``| String | Inherit configuration of peer-group. The peer group property should be confirgured first before configuring this property|
| ``address_family``| String | The address family mode. It will take ipv4 or ipv6 unicast|
| ``allowas_in``| String | Allow local AS number in as-path. The value should be between 1-10*|
| ``af_activate`` | Boolean | Enable the Address Family for this Neighbor|

**Actions**

- `:create` - Creates or updates the BGP neighbor properties.
- `:Delete` - Deletes the BGP neighbor properties or address family of BGP neighbor.

```ruby
* The Integer values should be entered in string format
```

### Type: dellos10_bgp_nbr_group

The `dellos10_bgp_nbr_group` resource is used to manage template configuration of BGP protocol.

| Minimum Requirements |OS10 |
|----------------------|:---:|
| OS Image | 10.4 |
| Dell OS10 Cookbook Version | 1.0.0 |

**Examples**

```ruby
bgp_nbr_group 'tr1' do
 asn_num '200'
 advertisement_interval '600'
 advertisement_start '50'
 timers ({keepalive: 50, hold_time: 70})
 connection_retry_timer '70'
 remote_as '300'
 remove_private_as true
 password 'devops'
 send_community_ext true
 send_community_std true
 address_family 'ipv4-unicast'
 no acivate
 action :create
end

bgp_nbr_group 'tr1' do
 asn_num '200'
 address_family 'ipv4-unicast'
 action :delete
end

```

**Parameters**

| Property         | Type                      | Description                                             |
|------------------|---------------------------|---------------------------------------------------------|
| ``asn_num`` | String        | The Autonomous system number. The value should be 0.1..65535.65535 or 1..4294967295*  |
| ``peer_group_config``| String  | template name|
| ``advertisement_interval``| String  | Minimum interval between sending BGP routing updates. The value should be between 1-600 with default value 30*|
| ``advertisement_start``| String  | Delay initiating OPEN message for the specified time. The value should be between 0-240*|
| ``timer``| Hash | Adjust routing timers keepalive and holdtime value. The Hash contains keepalive and holdtimer value. The keepalive value should be between 1-65535 with default value is 60. The hold timer should be between 3-65535 with default value of 180. The values are of type Integer.|
| ``connection_retry_timer``| String  | Peer connection retry timer. The value should be between 10-65535 with default default of 60*|
| ``remote_as``| String  | AS of remote BGP neighbor. The value should be 0.1..65535.65535 or 1..4294967295*|
| ``remove_private_as``| Boolean  | Remove private AS number from outbound updates|
| ``password``| String  | Set password|
| ``send_community_ext``| Boolean  | Neighbor's extended community attribute|
| ``send_community_std``| Boolean  | Neighbor's standard community attribute|
| ``address_family``| String | The address family mode. It will take ipv4 or ipv6 unicast|
| ``af_activate`` | Boolean | Enable the Address Family for this Neighbor|

**Actions**

- `:create` - Creates or updates the BGP template properties.
- `:Delete` - Deletes the BGP template properties or address familty of BGP template.

```ruby
* The Integer values should be entered in string format
```

### Type: dellos10_interface

The `dellos10_interface` resource is used to manage general configuration of all
interface types, including ethernet, port-channel, loopback, and vlan.

| Minimum Requirements |OS10 |
|----------------------|:---:|
| OS Image | 10.4 |
| Dell OS10 Cookbook Version | 1.0.0 |

**Examples**

```ruby
os10_interface 'ethernet 1/1/5' do
desc "ie5"
portmode "trunk"
mtu "1500"
switchport_mode true
admin "up"
ip_and_mask "1.1.1.1/24"
suppress_ra true
ipv6_and_mask "2001:db8:85a3::8a2e:370:7334/32"
state_ipv6  "cde"
ip_helper ["1.1.1.2", "1.1.1.13"]
end

```

**Parameters**


- `interface_name` -string -The interface name, in lower case. Defaults to the
   resource name.
- `desc`	-string	  Configures a single line interface description	
- `portmode`	-string	  Configures port-mode according to the device type	
- `switchport`	-boolean  Configures an interface in L2 mode
- `admin`	-string   Configures the administrative state for the interface; configuring the value as administratively "up" enables the interface; configuring the value as administratively "down" disables the interface
- `mtu`	        -integer  Configures the MTU size for L2 and L3 interfaces; example, MTU range is 1280 to 65535 on dellos10 devices
- `suppress_ra`	-boolean  Configures IPv6 router advertisements if set to present
- `ip_and_mask`	-string	  Configures the specified IP address to the interface on dellos9 and dellos10 devices; configures the specified IP address to the interface VLAN on dellos6 devices (192.168.11.1/24 format)
- `ipv6_and_mask` -string Configures a specified IPv6 address to the interface; configures a specified IP address to the interface VLAN on dellos6 devices (2001:4898:5808:ffa2::1/126 format)
- `state_ipv6`	-string   present or absent, deletes the IPV6 address if set to absent
- `ip_helper`	-Array    Configures DHCP server address objects (IPv4 address of the DHCP server)

**Actions**

- `:create` - updates the interface configuration. It is default action, so optional to provide in recipe.


Note
physical interfaces (Ethernet, etc.) can only be configured/unconfigured.


### Type: dellos10_lldp

The `dellos10_lldp` resource is used to manage general configuration of lldp

| Minimum Requirements |OS10 |
|----------------------|:---:|
| OS Image | 10.4 |
| Dell OS10 Cookbook Version | 1.0.0 |

**Examples**

```ruby

os10_lldp "lldp_conf" do
enable true
holdtime_multiplier "7"
reinit "5"
timer "80"
med_fast_start_repeat_count "5"
med_network_policy [{"id"=>"2", "app"=>"voice", "vlan"=>"3", "vlan-type"=> "tag", "priority"=>"3", "dscp"=>"4"}]
end
```

**Parameters**

-`enable`	                -boolean Enables or disables LLDP at a global level
-`multiplier`	                -string  Configures the LLDP multiplier (2 to 10)	
-'reinit`	                -string  Configures the reinit value (1-10)	
-`timer`	                -string  Configures the timer value (5-254)
-`med_fast_start_repeat_count` 	-string  Configures med fast start repeat count 
-`med_network_policy`           -hash    Network policy parameters 

**Actions**

- `:set` - updates the global lldp configuration. It is default action, so optional to provide in recipe.

### Type: dellos10_lldp_interface

The `dellos10_lldp_interface` resource is used to manage general configuration of lldp interface

| Minimum Requirements |OS10 |
|----------------------|:---:|
| OS Image | 10.4 |
| Dell OS10 Cookbook Version | 1.0.0 |

**Examples**

```ruby
os10_lldp_interface 'ethernet 1/1/1' do
receive true
transmit true
med true
med_network_policy ["7","8"]
med_tlv_select_inventory true
med_tlv_select_network_policy true
tlvselect ({"dcbxp"=>[""],"dot1tlv"=>["link-aggregation"], "dot3tlv"=>["max-framesize", "macphy-config"]})
end
```

**Parameters**

-`interface_name`                -string The interface name, in lower case. Defaults to the
   resource name.
-`receive`                       -boolean Configures receive at the interface level
-`transmit`                      -boolean Configures transmit at the interface level.
-`med`                           -boolean Configures MED at the interface level 
-`med_network_policy`            -Array   Configures the network policy id for the application of MED
-`med_tlv_select_inventory`      -boolean Configures tlv inventory at the interface level
-`med_tlv_select_network_policy` -boolean Configures tlv network policy at the interface level
-`tlvselect`                     -hash Disabled capabilities,by default capabilities are enabled. To disable provide values in hash
                                  whose key,value will be below values. Provide any or all values.
                                  basic-tlv => ["management-address",  "port-description",    "system-capabilities", "system-description", "system-name"]
                                  dcbxp => ""
                                  dcbxp-appln => ["iscsi", "fcoe"]
				  dot3tlv => ["macphy-config", "max-framesize"]
                                  dot1tlv => ["link-aggregation", "port-vlan-id"]
**Actions**

- `:set` - updates the interface lldp configuration. It is default action, so optional to provide in recipe.
~

### Type: dellos10_portmonitoring

The `dellos10_portmonitoring` resource is used to manage general configuration of port monitoring session.

| Minimum Requirements |OS10 |
|----------------------|:---:|
| OS Image | 10.4 |
| Dell OS10 Cookbook Version | 1.0.0 |

**Examples**

```ruby
os10_portmonitoring "2" do
source ["ethernet1/1/1","ethernet1/1/5"]
flowbase true
shutdown true
action :create
end
```

**Parameters**

-`port_id`       -String port monitoring session id.  Defaults to the
   resource name.
-'source`        -Array    Configures the source of an interface
-`destination`   -String   Configures the destination of an interface
-`flowbase`      -boolean  Enables flow-based monitoring	
-`shutdown`      -boolean  Enable/disables the monitoring session	

**Actions**

- `:create` - creates and updates the port monitoring configuration. It is default action, so optional to provide in recipe.
- `:delete` - delete the port monitoring session.
~

### Type: dellos10_route

The `dellos10_route` resource is used to manage general configuration of route.

| Minimum Requirements |OS10 |
|----------------------|:---:|
| OS Image | 10.4 |
| Dell OS10 Cookbook Version | 1.0.0 |

**Examples**

```ruby
os10_route '4.4.4.4/32' do
next_hop ["interface ethernet 1/1/6 10.10.10.10", "20.20.20.20"]
action :create
end
```

**Parameters**

-`route_ip`       -String route ip.  Defaults to the resource name.
-'next_hop`       -Array    Configures the next hop

**Actions**

- `:create` - creates and updates the route configuration. It is default action, so optional to provide in recipe.
- `:delete` - delete the route.

### Type: dellos10_snmp

The `dellos10_snmp` resource is used to manage general configuration of snmp.

| Minimum Requirements |OS10 |
|----------------------|:---:|
| OS Image | 10.4 |
| Dell OS10 Cookbook Version | 1.0.0 |

**Examples**

```ruby
os10_snmp "snmp_conf" do
location "aaa"
contact  "abc"
community ["private"]
trap []
host [{"version"=>"1", "community"=>"public","ip"=>"2.2.2.2", "port"=>"162"},{"community" => "public", "ip"=>"1.1.1.1","port"=>"162", "version"=>"2c"}]
end
```

**Parameters**

-`location`       -String Configures SNMP location information 
-'contact`        -String Configures SNMP contact information
-`community`      -Array  Configures SNMP community information
-`trap`           -[Array, Hash] Configures SNMP traps ["envmon"=>"fan","envmon"=>"power-supply","envmon"=>"temperature",
                                 "snmp"=>"authentication","snmp"=>"linkdown","snmp"=>"linkup","snmp"=>"coldstart","snmp"=>"warmstart"]
-`host`           -[Array, Hash] Configures SNMP hosts to receive SNMP traps 
**Actions**

- `:set` - updates the snmp configuration. It is default action, so optional to provide in recipe.

