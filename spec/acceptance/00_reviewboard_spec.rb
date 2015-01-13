require 'spec_helper_acceptance'

describe 'reviewboard class' do
  describe 'running puppet code' do
    it 'should work with no errors' do
      pp = <<-EOS
        Exec {
          timeout => 600,
        }
      
        include postgresql::server

        class {'apache':
          default_vhost => false,
          default_mods  => false,
        }
      
        case $::osfamily {
          'RedHat': {
            include epel

            package{['python-pip','python-devel']:
              require => Class['epel'],
            }
            Package['python-pip','python-devel'] -> Package<|provider==pip|>
            package {['memcached','python-memcached','python-ldap','patch']:}
          
            # Disable the firewall
            service {'iptables':
              ensure => stopped,
            }
          }
          'Debian': {
            package{ ['python-pip', 'python-dev']:
              ensure => installed,
            }

            package { ['memcached','python-memcache']:
              ensure => installed,
            }
          }
          default: {
            fail("Unsupport platform: ${::osfamily}")
          }
        }
      
        # Install Reviewboard
        class {'reviewboard':
          webprovider => 'puppetlabs/apache',
        }
      
        # Setup site
        reviewboard::site {'/var/www/reviewboard':
          require   => [
            Class['postgresql::server','postgresql::lib::python'],
            Package['memcached']
          ],
          vhost     => 'localhost',
          dbpass    => 'testing',
          adminpass => 'testing',
        }
      
        # RBTools
        # pip install of RBTools fails on recent OSes (requires --allow-external)
        #include reviewboard::rbtool
      
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
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end
  end
end
