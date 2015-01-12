require 'spec_helper_acceptance'

describe 'reviewboard class' do
  describe 'running puppet code' do
    it 'should work with no errors' do
      pp = <<-EOS
        Exec {
          timeout => 600,
        }
      
        include postgresql::server
        include epel
        class {'apache':
          default_vhost => false,
          default_mods  => false,
        }
      
        package{['python-pip','python-devel']:
          require => Class['epel'],
        }
        Package['python-pip','python-devel'] -> Package<|provider==pip|>
        package {['memcached','python-memcached','python-ldap','patch']:}
      
        # Install Reviewboard
        class {'reviewboard':
          webprovider => 'puppetlabs/apache',
        }
      
        # Setup site
        reviewboard::site {'/var/www/reviewboard':
          require   => [
            Class['postgresql::server','postgresql::lib::python'],
            Package['memcached','python-memcached','python-ldap']
          ],
          vhost     => 'localhost',
          dbpass    => 'testing',
          adminpass => 'testing',
        }
      
        # RBTools
        include reviewboard::rbtool
      
        # # Setup LDAP auth
        # reviewboard::site::ldap {'/var/www/reviewboard':
        #   uri    => 'test.example.com',
        #   basedn => 'dn=test,dn=example,dn=com',
        # }
      
        # Trac link plugin
        package {'trac':
          provider => pip,
        }
        #include reviewboard::traclink
      
        #package {'git':
        #  ensure => present,
        #  before => Class['Reviewboard::Traclink'],
        #}
      
        # Disable the firewall
        service {'iptables':
          ensure => stopped,
        }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end
  end
end
