# encoding: UTF-8
#
# Author:: Matt Ray (<matt@getchef.com>)
#
# Copyright:: 2011-2014, Chef Software, Inc <legal@getchef.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

describe 'testing 2.5 --chef-client' do
  before(:each) do
    @expected_output = <<-OUTPUT
knife ssh 'name:serverA and role:base' 'sudo chef-client' -i ~/.ssh/mray.pem -x user --no-host-key-verify -p 22
knife ssh 'name:serverB and chef_environment:development and role:base' 'sudo chef-client' -i ~/.ssh/mray.pem -x user
knife ssh 'name:serverC and chef_environment:development and role:base' 'sudo chef-client' -i ~/.ssh/mray.pem -x user
knife ssh 'name:db* and chef_environment:qa and recipe:mysql and role:monitoring' 'chef-client'
knife winrm 'name:winboxA and role:base and role:iisserver' 'chef-client' -x Administrator -P 'super_secret_password'
knife ssh 'name:winboxB and role:base and role:iisserver' 'chef-client' -x Administrator -P 'super_secret_password'
knife ssh 'name:winboxC and role:base and role:iisserver' 'chef-client' -x Administrator -P 'super_secret_password'
knife ssh 'chef_environment:amazon and role:mysql' 'sudo chef-client' -i ~/.ssh/mray.pem -x ubuntu -G default
knife ssh 'chef_environment:amazon and role:webserver and recipe:mysql\\:\\:client' 'sudo chef-client' -i ~/.ssh/mray.pem -x ubuntu -G default
    OUTPUT

    @spiceweasel_binary = File.join(File.dirname(__FILE__), *%w[.. .. bin spiceweasel])
  end

  it 'test chef-client in 2.5, yml' do
    `#{@spiceweasel_binary} --novalidation --chef-client examples/example.yml`.should == @expected_output
  end

  it 'test chef-client in 2.5, json' do
    `#{@spiceweasel_binary} --chef-client examples/example.json --novalidation`.should == @expected_output
  end

  it 'test chef-client in 2.5, rb' do
    `#{@spiceweasel_binary} examples/example.rb --novalidation --chef-client`.should == @expected_output
  end
end

describe 'testing 2.5 --chef-client with --cluster-file' do
  before(:each) do
    @expected_output = <<-OUTPUT
knife ssh 'name:serverB and chef_environment:qa and role:base and role:webserver' 'sudo chef-client' -i ~/.ssh/mray.pem -x user
knife ssh 'name:serverC and chef_environment:qa and role:base and role:webserver' 'sudo chef-client' -i ~/.ssh/mray.pem -x user
knife winrm 'name:winboxA and chef_environment:qa and role:base and role:iisserver' 'chef-client' -x Administrator -P 'super_secret_password'
knife ssh 'name:winboxB and chef_environment:qa and role:base and role:iisserver' 'chef-client' -x Administrator -P 'super_secret_password'
knife ssh 'name:winboxC and chef_environment:qa and role:base and role:iisserver' 'chef-client' -x Administrator -P 'super_secret_password'
knife ssh 'chef_environment:qa and role:webserver and recipe:mysql\\:\\:client' 'sudo chef-client' -x ubuntu -P ubuntu
    OUTPUT

    @spiceweasel_binary = File.join(File.dirname(__FILE__), *%w[.. .. bin spiceweasel])
  end

  it 'test chef-client with --cluster-file in 2.5, yml' do
    `#{@spiceweasel_binary} --novalidation --chef-client --cluster-file examples/cluster-file-example.yml examples/example.yml`.should == @expected_output
  end

  it 'test chef-client with --cluster-file in 2.5, json' do
    `#{@spiceweasel_binary} --cluster-file examples/cluster-file-example.yml --novalidation examples/example.json --chef-client`.should == @expected_output
  end

  it 'test chef-client with --cluster-file in 2.5, rb' do
    `#{@spiceweasel_binary} --novalidation --chef-client examples/example.rb --cluster-file examples/cluster-file-example.yml`.should == @expected_output
  end
end

describe 'testing 2.5 --chef-client with -a' do
  before(:each) do
    @expected_output = <<-OUTPUT
knife ssh 'chef_environment:mycluster and role:mysql' 'sudo chef-client' -i ~/.ssh/mray.pem -x ubuntu -a ec2.public_hostname
knife ssh 'chef_environment:mycluster and role:webserver and recipe:mysql\\:\\:client' 'sudo chef-client' -i ~/.ssh/mray.pem -x ubuntu -a ec2.public_hostname
    OUTPUT

    @spiceweasel_binary = File.join(File.dirname(__FILE__), *%w[.. .. bin spiceweasel])
  end

  it 'test chef-client with -a ec2.public_hostname in 2.5' do
    `#{@spiceweasel_binary} --novalidation --chef-client -a ec2.public_hostname examples/example-cluster.yml`.should == @expected_output
  end

end
