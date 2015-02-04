require 'spec_helper'

$default_params = {
                   :dbpass => 'password1',
                   :adminpass => 'password2',
                  }
$default_vhost = 'reviewboard.example.com'
$default_site = '/var/www/reviewboard'
$default_dbname = 'reviewboard'

describe 'reviewboard::site' do
  let (:title) { $default_site }
  let (:facts) { $default_facts }
  let (:pre_condition) { 'class { reviewboard: }' }

  context 'with no parameters' do
    it 'should fail to compile the catalog' do
      should raise_error(Puppet::Error, /password not set/)
    end
  end

  context 'with no parameters except passwords' do
    let (:params) { $default_params }
    # catalog compilation
    it { should compile.with_all_deps }

    # classes/defines
    it { should contain_reviewboard__site($default_site) }
    it { should contain_reviewboard__site__install($default_site) }
    it { should contain_reviewboard__provider__db($default_site) }
    it { should contain_reviewboard__provider__web($default_site) }

    # dependencies
    it 'should install the database before installing the site' do
      should contain_reviewboard__provider__db($default_site).that_comes_before("Reviewboard::Site::Install[#{$default_site}]")
    end
    it 'should install the site before installing the web provider' do
      should contain_reviewboard__site__install($default_site).that_comes_before("Reviewboard::Provider::Web[#{$default_site}]")
    end

    # reviewboard::site::install
    it 'should install the site' do
      should contain_exec("rb-site install #{$default_site}").that_requires('Class[Reviewboard::Package]')
    end
  end

  # test $normalized_location
  context 'with $location parameter' do
    context 'set to "/"' do
      let (:params) { $default_params.merge(:location => '/') }

      it { should contain_reviewboard__site__install($default_site).with_location('/') }
    end

    context 'set to "/foo"' do
      let (:params) { $default_params.merge(:location => '/foo') }

      it { should contain_reviewboard__site__install($default_site).with_location('/foo/') }
    end

    context 'set to "/foo/"' do
      let (:params) { $default_params.merge(:location => '/foo/') }

      it { should contain_reviewboard__site__install($default_site).with_location('/foo/') }
    end
  end

  # reviewboard::provider::web
  context 'with the $webprovider parameter on the main module' do
    let (:params) { $default_params }

    context 'set to "none"' do
      let (:pre_condition) { 'class { reviewboard: webprovider => "none" }' }

      it { should_not contain_reviewboard__provider__web__simple($default_site) }
      it { should_not contain_reviewboard__provider__web__puppetlabsapache($default_site) }
    end

    context 'set to "simple"' do
      let (:pre_condition) { 'class { reviewboard: webprovider => "simple" }' }

      it { should contain_reviewboard__provider__web__simple($default_site) }
      it { should_not contain_reviewboard__provider__web__puppetlabsapache($default_site) }

      # reviewboard::provider::web::simple
      context 'and with ssl set to "false"' do
        let (:params) { $default_params.merge({ :vhost => $default_vhost, :ssl => false }) }

        it { should contain_class('reviewboard::provider::web::simplepackage') }
        it 'should install Reviewboard::Provider::Web::Simplepackage before Reviewboard::Provider::Web::Simple' do
          should contain_reviewboard__provider__web__simple($default_site).that_requires('Class[Reviewboard::Provider::Web::Simplepackage]')
        end
      end

      context 'and with ssl set to "true"' do
        let (:params) { $default_params.merge({ :vhost => $default_vhost, :ssl => true }) }

        it 'should fail to compile the catalog' do
          should raise_error(Puppet::Error, /Web provider .* does not support ssl/)
        end
      end
    end

    context 'set to "puppetlabs/apache"' do
      let (:pre_condition) { 'class { reviewboard: webprovider => "puppetlabs/apache" }' }

      it { should_not contain_reviewboard__provider__web__simple($default_site) }
      it { should contain_reviewboard__provider__web__puppetlabsapache($default_site) }
      it { should contain_class('apache') }

      # reviewboard::provider::web::puppetlabsapache
      context 'and with ssl set to "false"' do
        let (:params) { $default_params.merge({ :vhost => $default_vhost, :ssl => false }) }

        it { should contain_apache__vhost($default_vhost).with_port('80').with_ssl('false') }
        it { should_not contain_apache__vhost("#{$default_vhost} ssl-redirect") }
      end

      context 'and with ssl set to "true" and default certificates' do
        let (:params) { $default_params.merge({ :vhost => $default_vhost, :ssl => true }) }

        it { should contain_apache__vhost($default_vhost).with_port('443').with_ssl('true') }
        it { should_not contain_apache__vhost("#{$default_vhost} ssl-redirect") }
      end

      context 'and with ssl set to "true" and relative certificate paths' do
        let (:params) { $default_params.merge({ :vhost     => $default_vhost,
                                                :ssl       => true,
                                                :ssl_key   => 'certs/example_server.key',
                                                :ssl_crt   => 'certs/example_server.crt',
                                                :ssl_chain => 'certs/server_chain.pem',
                                             }) }

        it 'should fail to compile the catalog' do
          should raise_error(Puppet::Error, /is not an absolute path/)
        end
      end

      context 'and with ssl set to "true" and absolute certificate paths' do
        let (:params) { $default_params.merge({ :vhost     => $default_vhost,
                                                :ssl       => true,
                                                :ssl_key   => '/etc/ssl/certs/example_server.key',
                                                :ssl_crt   => '/etc/ssl/certs/example_server.crt',
                                                :ssl_chain => '/etc/ssl/certs/server_chain.pem',
                                             }) }

        it 'should pass the specified certificates through to apache::vhost' do
          should contain_apache__vhost($default_vhost).with_port('443').with_ssl('true').with_ssl_key('/etc/ssl/certs/example_server.key').with_ssl_cert('/etc/ssl/certs/example_server.crt').with_ssl_chain('/etc/ssl/certs/server_chain.pem')
        end
        it { should_not contain_apache__vhost("#{$default_vhost} ssl-redirect") }
      end

      context 'and with ssl set to "true" and ssl_redirect_http set to "true"' do
        let (:params) { $default_params.merge({ :vhost => $default_vhost, :ssl => true, :ssl_redirect_http => true }) }

        it { should contain_apache__vhost($default_vhost).with_port('443').with_ssl('true') }
        it { should contain_apache__vhost("#{$default_vhost} ssl-redirect").with_port('80').with_ssl('false').with_redirect_dest("https://#{$default_vhost}/") }
      end
    end

    context 'set to "foo"' do
      let (:pre_condition) { 'class { reviewboard: webprovider => "foo" }' }

      it 'should fail to compile the catalog' do
        should raise_error(Puppet::Error, /Web provider .* not defined/)
      end
    end
  end

  # reviewboard::provider::db
  context 'with the $dbprovider parameter on the main module' do
    let (:params) { $default_params }

    context 'set to "none"' do
      let (:pre_condition) { 'class { reviewboard: dbprovider => "none" }' }

      it { should_not contain_reviewboard__provider__db__puppetlabspostgresql($default_site) }
      it { should_not contain_reviewboard__provider__db__puppetlabsmysql($default_site) }
    end

    context 'set to "puppetlabs/postgresql"' do
      let (:pre_condition) { 'class { reviewboard: dbprovider => "puppetlabs/postgresql" }' }

      it { should contain_reviewboard__provider__db__puppetlabspostgresql($default_site) }
      it { should_not contain_reviewboard__provider__db__puppetlabsmysql($default_site) }

      # reviewboard::provider::db::puppetlabspostgresql
      context 'reviewboard::provider::db::puppetlabspostgresql' do
        it 'should depend on postgresql::lib::python' do
          should contain_reviewboard__provider__db__puppetlabspostgresql($default_site).that_requires('Class[Postgresql::Lib::Python]')
        end

        context 'with dbhost set to "localhost" and dbcreate "true"' do
          let (:params) { $default_params.merge({ :dbhost => 'localhost', :dbcreate => true }) }

          it { should contain_postgresql__server__db($default_dbname) }
        end

        context 'with dbhost set to "localhost" and dbcreate "false"' do
          let (:params) { $default_params.merge({ :dbhost => 'localhost', :dbcreate => false }) }

          it { should_not contain_postgresql__server__db($default_dbname) }
        end

        context 'with dbhost set to "foo" and dbcreate "true"' do
          let (:params) { $default_params.merge({ :dbhost => 'foo', :dbcreate => true }) }

          it 'should fail to compile the catalog' do
            should raise_error(Puppet::Error, /Remote db hosts not implemented/)
          end
        end

        context 'with dbhost set to "foo" and dbcreate "false"' do
          let (:params) { $default_params.merge({ :dbhost => 'foo', :dbcreate => false }) }

          it { should_not contain_postgresql__server__db($default_dbname) }
        end
      end
    end

    context 'set to "puppetlabs/mysql"' do
      let (:pre_condition) { 'class { reviewboard: dbprovider => "puppetlabs/mysql" }' }

      it { should_not contain_reviewboard__provider__db__puppetlabspostgresql($default_site) }
      it { should contain_reviewboard__provider__db__puppetlabsmysql($default_site) }

      # reviewboard::provider::db::puppetlabsmysql
      context 'reviewboard::provider::db::puppetlabsmysql' do
        it 'should depend on mysql::bindings' do
          should contain_reviewboard__provider__db__puppetlabsmysql($default_site).that_requires('Class[Mysql::Bindings]')
        end
        it { should contain_mysql__bindings.with_python_enable('true') }

        context 'with dbhost set to "localhost" and dbcreate "true"' do
          let (:params) { $default_params.merge({ :dbhost => 'localhost', :dbcreate => true }) }

          it { should contain_mysql__server.with_root_password($default_params[:dbpass]) }
          it { should contain_mysql__db($default_dbname).with_password($default_params[:dbpass]) }
        end

        context 'with dbhost set to "localhost" and dbcreate "false"' do
          let (:params) { $default_params.merge({ :dbhost => 'localhost', :dbcreate => false }) }

          it { should_not contain_mysql__server }
          it { should_not contain_mysql__db($default_dbname) }
        end

        context 'with dbhost set to "foo" and dbcreate "true"' do
          let (:params) { $default_params.merge({ :dbhost => 'foo', :dbcreate => true }) }

          it 'should fail to compile the catalog' do
            should raise_error(Puppet::Error, /Remote db hosts not implemented/)
          end
        end

        context 'with dbhost set to "foo" and dbcreate "false"' do
          let (:params) { $default_params.merge({ :dbhost => 'foo', :dbcreate => false }) }

          it { should_not contain_mysql__server }
          it { should_not contain_mysql__db }
        end
      end
    end

    context 'set to "foo"' do
      let (:pre_condition) { 'class { reviewboard: dbprovider => "foo" }' }

      it 'should fail to compile the catalog' do
        should raise_error(Puppet::Error, /DB provider .* not defined/)
      end
    end
  end

end
