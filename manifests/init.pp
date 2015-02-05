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
# [*egg_url*]
#   URL of Reviewboard egg to install.
#   Defaults to a URL built from the version parameter.
#
# [*pkg_python_pip*]
#   Package or (array of) packages to install for pip and easy_install.
#   Default is OS-dependent.
#
# [*pkg_python_dev*]
#   Package or (array of) packages to install for python headers and static
#   libs.
#   Default is OS-dependent.
#
# [*pkg_memcached*]
#   Package or (array of) packages to install for memcached support. Set to
#   the string 'NONE' if memcached support should not be installed.
#   Default is OS-dependent.
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
  $version        = '1.7.28', # Current stable release
  $webprovider    = 'puppetlabs/apache',
  $webuser        = undef,
  $dbprovider     = 'puppetlabs/postgresql',
  $egg_url        = undef,
  $pkg_python_pip = undef,
  $pkg_python_dev = undef,
  $pkg_memcached  = undef,
  $rbsitepath     = undef,
) inherits reviewboard::params {

  #
  # Parameter validation
  #

  # Validation of $version is performed when $_egg_url is set

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

  $egg_base_url = 'http://downloads.reviewboard.org/releases/ReviewBoard'
  if $egg_url == undef {
    case $version {
      /^2\.0\./: {
        $_egg_url = "${egg_base_url}/2.0/ReviewBoard-${version}-py2.6.egg"
      }
      /^1\.7\./: {
        $_egg_url = "${egg_base_url}/1.7/ReviewBoard-${version}-py2.6.egg"
      }
      default: {
        fail("Reviewboard module has not been tested with Reviewboard ${version}")
      }
    }
  } else {
    $_egg_url = $egg_url
  }

  $_pkg_python_pip = $pkg_python_pip ? {
    undef   => $reviewboard::params::pkg_python_pip,
    default => $pkg_python_pip,
  }

  $_pkg_python_dev = $pkg_python_dev ? {
    undef   => $reviewboard::params::pkg_python_dev,
    default => $pkg_python_dev,
  }

  $_pkg_memcached = $pkg_memcached ? {
    undef   => $reviewboard::params::pkg_memcached,
    'NONE'  => undef,
    default => $pkg_memcached,
  }

  $_rbsitepath = $rbsitepath ? {
    undef   => $reviewboard::params::rbsitepath,
    default => $rbsitepath,
  }

  include reviewboard::install
}
