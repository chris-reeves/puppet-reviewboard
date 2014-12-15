require 'puppetlabs_spec_helper/module_spec_helper'

$default_facts = {
                  :osfamily => 'Debian',
                  :operatingsystem => 'Ubuntu',
                  :operatingsystemrelease => '14.04',
                  :concat_basedir => '/foo'
                 }
