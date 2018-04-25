#
# Cookbook:: octagon
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved
os10_snmp 'snmp_conf' do
  location ''
  contact  'abc'
  community ['private']
  trap []
  host [{ 'version' => '1', 'community' => 'public', 'ip' => '2.2.2.2', 'port' => '162' },
        { 'community' => 'public', 'ip' => '1.1.1.1', 'port' => '162', 'version' => '2c' }]
end
