# Encoding: utf-8
include_recipe 'build-essential'
include_recipe 'java'
include_recipe 'ant'
include_recipe 'git'
include_recipe 'logstash::default'

package 'wget'

logstash_version = node['logstash']['source']['sha'] || "v#{node['logstash']['server']['version']}"

directory "#{node['logstash']['basedir']}/source" do
  action :create
  owner node['logstash']['user']
  group node['logstash']['group']
  mode '0755'
end

git "#{node['logstash']['basedir']}/source" do
  repository node['logstash']['source']['repo']
  reference logstash_version
  action :sync
  user node['logstash']['user']
  group node['logstash']['group']
end

execute 'build-logstash' do
  cwd "#{node['logstash']['basedir']}/source"
  environment(
    :JAVA_HOME => node['logstash']['source']['java_home']
  )
  user node['logstash']['user']
  # This variant is useful for troubleshooting stupid environment problems
  command "make clean && make tarball --debug > /tmp/make.log 2>&1"
  action :run
  creates "#{node['logstash']['basedir']}/source/build/logstash-v#{logstash_version}.tar.gz"
  not_if "test -f #{node['logstash']['basedir']}/source/build/logstash-v#{logstash_version}.tar.gz"
  notifies :run, 'execute[extract-logstash]', :immediately
end

execute 'extract-logstash' do
  cwd "#{node['logstash']['basedir']}/source/build"
  user node['logstash']['user']
  command "rm -rf #{node['logstash']['server']['home']}/* && tar zxvf logstash-v#{logstash_version}.tar.gz #{node['logstash']['server']['home']}"
  action :nothing
  notifies :restart, 'service[logstash_server]'
end


