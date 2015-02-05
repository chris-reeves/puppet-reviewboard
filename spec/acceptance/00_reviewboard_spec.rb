require 'spec_helper_acceptance'

describe 'reviewboard class' do
  describe 'running puppet code' do
    it 'should work with no errors' do
      pp = <<-EOS
        Exec {
          timeout => 600,
        }
      
        class {'apache':
          default_vhost => false,
          default_mods  => false,
        }
      
        # Install Reviewboard
        class {'reviewboard':
          # Test package installation for all supported VCS
          install_vcs => ['cvs','svn','git','mercurial'],
        }
      
        # Setup site
        reviewboard::site {'/var/www/reviewboard':
          vhost     => 'localhost',
          dbpass    => 'testing',
          adminpass => 'testing',
        }
      
        # RBTools
        # pip install of RBTools fails on recent OSes (requires --allow-external)
        #include reviewboard::rbtool
      
        # LDAP auth
        # package {'python-ldap':}
        # reviewboard::site::ldap {'/var/www/reviewboard':
        #   uri    => 'test.example.com',
        #   basedn => 'dn=test,dn=example,dn=com',
        # }
      
        # Trac link plugin
        # pip provider is broken on RHEL >= 7 (PUP-3829)
        #package {'trac':
        #  provider => pip,
        #}
        #include reviewboard::traclink
      
        #package {'patch':}
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      expect(apply_manifest(pp, :catch_failures => true).exit_code).to be_zero
    end
  end
end
