#
# Cookbook:: octagon
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved
os10_lldp_interface 'ethernet 1/1/1' do
  receive true
  transmit true
  med true
  med_network_policy ['7', '8']
  med_tlv_select_inventory true
  med_tlv_select_network_policy true
  tlvselect ({ 'dcbxp' => [''], 'dot1tlv' => ['link-aggregation'],
              'dot3tlv' => ['max-framesize', 'macphy-config'] })
end
