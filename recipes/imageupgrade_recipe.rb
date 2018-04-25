#
# Cookbook:: octagon
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved
os10_imageupgrade 'scp://root:force10@10.16.138.27/root/PKGS_OS10-Enterprise-10.3.9999E.X.6820-installer-x86_64.bin' do
  action 'set'
end
