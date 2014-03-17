# Encoding: utf-8
include_recipe 'build-essential'
include_recipe 'java'
include_recipe 'ant'
include_recipe 'git'
include_recipe 'logstash::default'

package 'wget'

logstash_version = node['logstash']['source']['sha'] || node['logstash']['server']['version']

directory "#{node['logstash']['basedir']}/source" do
  action :create
  owner node['logstash']['user']
  group node['logstash']['group']
  mode '0755'
end

git "#{node['logstash']['basedir']}/source" do
  repository node['logstash']['source']['repo']
  reference "v#{logstash_version}"
  action :sync
  user node['logstash']['user']
  group node['logstash']['group']
end

execute 'build-logstash' do
  cwd "#{node['logstash']['basedir']}/source"
  environment(
    "JAVA_HOME" => node['logstash']['source']['java_home']
  )
  path ["/usr/local/rvm/gems/jruby-1.7.11/bin", "/usr/local/rvm/gems/jruby-1.7.11@global/bin",
  "/usr/local/rvm/rubies/jruby-1.7.11/bin","/usr/local/sbin","/usr/local/bin","/usr/sbin:/usr/bin",
  "/sbin","/bin","/usr/local/rvm/bin"]
  user node['logstash']['user']
  # This variant is useful for troubleshooting stupid environment problems
  command "make clean && make tarball"
  action :run
  creates "#{node['logstash']['basedir']}/source/build/logstash-#{logstash_version}.tar.gz"
  not_if "test -f #{node['logstash']['basedir']}/source/build/logstash-#{logstash_version}.tar.gz"
  notifies :run, 'execute[extract-logstash]', :immediately
end

execute 'extract-logstash' do
  cwd "#{node['logstash']['basedir']}/source/build"
  user node['logstash']['user']
  command "rm -rf #{node['logstash']['server']['home']}/* && tar zxvf logstash-#{logstash_version}.tar.gz -C #{node['logstash']['server']['home']}"
  action :nothing
  notifies :restart, 'service[logstash_server]'
end


