require 'spec_helper'

$default_params = {
                   :dbpass => 'password1',
                   :adminpass => 'password2',
                  }
$default_site = '/var/www/reviewboard'

describe 'reviewboard::site' do
  let (:title) { $default_site }
  let (:facts) { $default_facts }
  let (:pre_condition) { 'class { reviewboard: }' }

  context 'with no parameters' do
    it 'should fail to compile the catalog' do
      expect { should compile }.to raise_error(Puppet::Error, /password not set/)
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
      should contain_exec("rb-site install #{$default_site}").that_requires("Class[Reviewboard::Package]")
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
      it { should contain_class('reviewboard::provider::web::simplepackage') }
      it 'should install Reviewboard::Provider::Web::Simplepackage before Reviewboard::Provider::Web::Simple' do
        should contain_reviewboard__provider__web__simple($default_site).that_requires('Class[Reviewboard::Provider::Web::Simplepackage]')
      end
    end

    context 'set to "puppetlabs/apache"' do
      let (:pre_condition) { 'class { reviewboard: webprovider => "puppetlabs/apache" }' }

      it { should_not contain_reviewboard__provider__web__simple($default_site) }
      it { should contain_reviewboard__provider__web__puppetlabsapache($default_site) }
      it { should contain_class('apache') }
    end

    context 'set to "foo"' do
      let (:pre_condition) { 'class { reviewboard: webprovider => "foo" }' }

      it 'should fail to compile the catalog' do
        expect { should compile }.to raise_error(Puppet::Error, /Web provider .* not defined/)
      end
    end
  end

  # reviewboard::provider::db
  context 'with the $dbprovider parameter on the main module' do
    context 'set to "none"' do
      let (:pre_condition) { 'class { reviewboard: dbprovider => "none" }' }

      it { should_not contain_reviewboard__provider__db__puppetlabspostgresql($default_site) }
    end

    context 'set to "puppetlabs/postgresql"' do
      let (:pre_condition) { 'class { reviewboard: dbprovider => "puppetlabs/postgresql" }' }

      it { should contain_reviewboard__provider__db__puppetlabspostgresql($default_site) }
    end

    context 'set to "foo"' do
      let (:pre_condition) { 'class { reviewboard: dbprovider => "foo" }' }

      it 'should fail to compile the catalog' do
        expect { should compile }.to raise_error(Puppet::Error, /DB provider .* not defined/)
      end
    end
  end

end
