## \file    manifests/init.pp
#  \author  Scott Wales <scott.wales@unimelb.edu.au>
#  \brief
#
#  Copyright 2014 Scott Wales
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#
# Installation and basic configuration of Reviewboard
#
# === Parameters
#
# [*version*]
#   Version of Reviewboard to install.
#   Defaults to '1.7.28'
#
# [*webprovider*]
#   Package to use to configure the web server. Valid values are
#   'puppetlabs/apache', 'simple' or 'none' for no config.
#   Defaults to 'puppetlabs/apache'
#
# [*webuser*]
#   User that should own the web folders
#
# [*dbprovider*]
#   Package to use to configure the database. Valid values are
#   'puppetlabs/postgresql', 'puppetlabs/mysql' or 'none' for no config
#   Defaults to 'puppetlabs/postgresql'
#
# [*rbsitepath*]
#   Path to the rb-site binary.
#   Default is OS-dependent.
#
# === Examples
#
# The following two examples are equivalent:
#
# ==== Simple include
#
#  include reviewboard
#
# ==== Passing parameters
#
#  class { 'reviewboard':
#    version     => '2.0.12',
#    webprovider => 'puppetlabs/apache',
#    dbprovider  => 'puppetlabs/postgresql',
#  }

class reviewboard (
  $version     = '1.7.28', # Current stable release
  $webprovider = 'puppetlabs/apache',
  $webuser     = undef,
  $dbprovider  = 'puppetlabs/postgresql',
  $rbsitepath  = undef,
) inherits reviewboard::params {

  #
  # Parameter validation
  #

  validate_re($version, [ '^1\.7\.', '^2\.0\.' ],
    "Reviewboard module has not been tested with Reviewboard ${version}")

  # Validation of values is performed by reviewboard::provider::web
  validate_string($webprovider)

  # Validation of values is performed by reviewboard::provider::db
  validate_string($dbprovider)

  if $webuser != undef {
    validate_string($webuser)
  }

  if $rbsitepath != undef {
    validate_absolute_path($rbsitepath)
  }

  #
  # Set defaults
  #

  $_rbsitepath = $rbsitepath ? {
    undef   => $reviewboard::params::rbsitepath,
    default => $rbsitepath,
  }

  class { 'reviewboard::package':
    version => $version,
  }

}
