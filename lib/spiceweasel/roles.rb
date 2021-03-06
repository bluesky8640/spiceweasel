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

require 'yajl/json_gem'
require 'chef'

module Spiceweasel
  class Roles

    include CommandHelper

    attr_reader :role_list, :create, :delete

    def initialize(roles = {}, environments = [], cookbooks = {})
      @create = Array.new
      @delete = Array.new
      @role_list = Array.new
      if roles
        Spiceweasel::Log.debug("roles: #{roles}")
        flatroles = roles.collect {|x| x.keys}.flatten
        rolefiles = []
        flatroles.each do |role|
          Spiceweasel::Log.debug("role: #{role}")
          if File.directory?("roles")
            #expand wildcards and push into flatroles
            if role =~ /\*/ #wildcard support
              wildroles = Dir.glob("roles/#{role}")
              #remove anything not ending in .json or .rb
              wildroles.delete_if {|x| !x.end_with?(".rb", ".json")}
              Spiceweasel::Log.debug("found roles '#{wildroles}' for wildcard: #{role}")
              flatroles.concat(wildroles.collect {|x| x[x.rindex('/')+1..x.rindex('.')-1]})
              next
            end
            validate(role, environments, cookbooks, flatroles) unless Spiceweasel::Config[:novalidation]
          elsif !Spiceweasel::Config[:novalidation]
            STDERR.puts "ERROR: 'roles' directory not found, unable to validate or load roles"
            exit(-1)
          end
          if File.exists?("roles/#{role}.json")
            rolefiles.push("#{role}.json")
          else #assume no .json means they want .rb and catchall for misssing dir
            rolefiles.push("#{role}.rb")
          end
          delete_command("knife role#{Spiceweasel::Config[:knife_options]} delete #{role} -y")
          @role_list.push(role)
        end
        create_command("knife role#{Spiceweasel::Config[:knife_options]} from file #{rolefiles.uniq.sort.join(' ')}")
      end
    end

    #validate the content of the role file
    def validate(role, environments, cookbooks, roles)
      #validate the role passed in match the name of either the .rb or .json
      file = %W(roles/#{role}.rb roles/#{role}.json).detect{|f| File.exists?(f)}
      if role =~ /\// #pull out directories
        role = role.split('/').last
      end
      if file
        case file
        when /\.json$/
          c_role = Chef::JSONCompat.from_json(IO.read(file))
        when /\.rb$/
          if (Chef::VERSION.split('.')[0].to_i < 11)
            c_role = Chef::Role.new(true)
          else
            c_role = Chef::Role.new
          end
          begin
            c_role.from_file(file)
          rescue SyntaxError => e
            STDERR.puts "ERROR: Role '#{file}' has syntax errors."
            STDERR.puts e.message
            exit(-1)
          end
        end
        Spiceweasel::Log.debug("role: '#{role}' name: '#{c_role.name}'")
        if !role.eql?(c_role.name)
          STDERR.puts "ERROR: Role '#{role}' listed in the manifest does not match the name '#{c_role.name}' within the #{file} file."
          exit(-1)
        end
        c_role.run_list.each do |runlist_item|
          if(runlist_item.recipe?)
            Spiceweasel::Log.debug("recipe: #{runlist_item.name}")
            cookbook,recipe = runlist_item.name.split('::')
            Spiceweasel::Log.debug("role: '#{role}' cookbook: '#{cookbook}' dep: '#{runlist_item}'")
            unless(cookbooks.member?(cookbook))
              STDERR.puts "ERROR: Cookbook dependency '#{runlist_item}' from role '#{role}' is missing from the list of cookbooks in the manifest."
              exit(-1)
            end
          elsif(runlist_item.role?)
            Spiceweasel::Log.debug("role: '#{role}' role: '#{runlist_item}': dep: '#{runlist_item.name}'")
            unless(roles.member?(runlist_item.name))
              STDERR.puts "ERROR: Role dependency '#{runlist_item.name}' from role '#{role}' is missing from the list of roles in the manifest."
              exit(-1)
            end
          else
            STDERR.puts "ERROR: Unknown item in runlist: #{runlist_item.name}"
            exit(-1)
          end
        end
        #TODO validate any environment-specific runlists
      else #role is not here
        STDERR.puts "ERROR: Invalid Role '#{role}' listed in the manifest but not found in the roles directory."
        exit(-1)
      end
    end

    def member?(role)
      role_list.include?(role)
    end

  end
end
