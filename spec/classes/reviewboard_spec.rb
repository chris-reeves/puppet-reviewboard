require 'spec_helper'

describe 'reviewboard' do
  let (:facts) { $default_facts }

  context 'with default parameters' do
    it { should compile.with_all_deps }
    it { should contain_class('reviewboard') }
    it { should contain_class('reviewboard::install') }
  end

  context 'with version and egg_url' do
    custom_egg_url = 'http://egg.example.com/ReviewBoard.egg'

    context 'set to 1.7.28 and not specified, respectively' do
      let (:params) { { :version => '1.7.28' } }

      it { should contain_exec('install reviewboard') }
    end

    context 'set to 2.0.12 and not specified, respectively' do
      let (:params) { { :version => '2.0.12' } }

      it { should contain_exec('install reviewboard') }
    end

    context 'set to 1.8.0 and not specified, respectively' do
      let (:params) { { :version => '1.8.0' } }

      it { should raise_error(Puppet::Error, /Reviewboard module has not been tested with Reviewboard/) }
    end

    context "set to 1.7.28 and #{custom_egg_url}" do
      let (:params) { { :version => '1.7.28', :egg_url => custom_egg_url } }

      it { should contain_exec('install reviewboard').with_command("easy_install '#{custom_egg_url}'") }
    end

    # Shouldn't care about version number when egg_url is specified
    context "set to 1.8.0 and #{custom_egg_url}" do
      let (:params) { { :version => '1.8.0', :egg_url => custom_egg_url } }

      it { should contain_exec('install reviewboard').with_command("easy_install '#{custom_egg_url}'") }
    end
  end

  context 'with pkg_memcached' do
    context 'left at the default' do
      it { should contain_package('memcached') }
    end

    context 'set to my-memcached' do
      let (:params) { { :pkg_memcached => 'my-memcached' } }

      it { should contain_package('my-memcached') }
    end

    context 'set to an array' do
      let (:params) { { :pkg_memcached => [ 'my-memcached', 'my-python-memcached' ] } }

      it { should contain_package('my-memcached') }
      it { should contain_package('my-python-memcached') }
    end

    context 'set to NONE' do
      let (:params) { { :pkg_memcached => 'NONE' } }

      it { should_not contain_package('memcached') }
    end
  end
end
