require 'beaker-rspec'
require 'pry'

UNSUPPORTED_PLATFORMS = [ 'Windows', 'AIX', 'Solaris', 'Suse' ]

unless ENV['RS_PROVISION'] == 'no' or ENV['BEAKER_provision'] == 'no'
  # This will install the latest available package on el and deb based
  # systems fail on windows and osx, and install via gem on other *nixes
  foss_opts = { :default_action => 'gem_install' }

  if default.is_pe?; then install_pe; else install_puppet( foss_opts ); end

  hosts.each do |host|
    on hosts, "mkdir -p #{host['distmoduledir']}"
  end
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module
    puppet_module_install(:source => proj_root, :module_name => 'reviewboard')
    hosts.each do |host|
      # Fixtures should also be added to <module>/.fixtures.yml
      on host, puppet('module','install','puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-concat'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-apache'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-postgresql'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module','install','puppetlabs-mysql'), { :acceptable_exit_codes => [0,1] }
      # RHEL, etc. has an additional dependency
      on host, puppet('module','install','stahnma-epel'), { :acceptable_exit_codes => [0,1] }
#      shell("/bin/touch #{default['puppetpath']}/hiera.yaml")
    end
  end
end
