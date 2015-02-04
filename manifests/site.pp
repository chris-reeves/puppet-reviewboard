#  \file    manifests/site.pp
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

# Set up an instance of a Reviewboard site
#
# === Parameters
#
# [*site*]
#   Filesystem path into which this instance will be installed.
#   Defaults to the name of the declared Reviewboard::Site resource.
#
# [*vhost*]
#   Fully-qualified host name through which this instance will be accessed
#   Defaults to $fqdn
#
# [*location*]
#   URL path to this instance, relative to the host name
#   Defaults to '/reviewboard'
#
# [*dbtype*]
#   Type of database to be used. Valid values are 'postgresql' and 'mysql'.
#   Defaults to 'postgresql'
#
# [*dbname*]
#   Name of the Reviewboard database.
#   Defaults to 'reviewboard'
#
# [*dbhost*]
#   Hostname of the server hosting the Reviewboard database.
#   Defaults to 'localhost'
#
# [*dbuser*]
#   Name of the Reviewboard database user.
#   Defaults to 'reviewboard'
#
# [*dbpass*]
#   Password for the Reviewboard database user.
#   Required parameter.
#
# [*admin*]
#   Name of the Reviewboard admin user.
#   Defaults to 'admin'
#
# [*adminpass*]
#   Password for the Reviewboard admin user.
#   Required parameter.
#
# [*adminemail*]
#   Email address of the Reviewboard admin user.
#   Defaults to $webuser@$fqdn
#
# [*company*]
#   Company name (displayed by Reviewboard).
#   Defaults to the empty string.
#
# [*cache*]
#   Type of cache used by reviewboard. Valid values are 'memcached' and
#   'file'.
#   Defaults to 'memcached'
#
# [*cacheinfo*]
#   Cache identifier (memcached connection string or file cache directory).
#   Defaults to 'localhost:11211'
#
# [*webuser*]
#   User that should own the web folders
#
# [*ssl*]
#   Controls whether this instance is protected using SSL or not (boolean).
#   Only supported by the puppetlabs/apache web provider.
#   Defaults to false
#
# [*ssl_key*]
#   Absolute path to the SSL certificate key file. This module is not
#   responsible for placing the key file on the server. Only used when 'ssl'
#   is true.
#   Defaults to default system-generated certificate key.
#
# [*ssl_crt*]
#   Absolute path to the SSL certificate file. This module is not responsible
#   for placing the certificate file on the server. Only used when 'ssl' is
#   true.
#   Defaults to default system-generated certificate.
#
# [*ssl_chain*]
#   Absolute path to the SSL certificate chain file. This module is not
#   responsible for placing the certificate chain file on the server. Only
#   used when 'ssl' is true.
#   Defaults to undef.
#
# [*ssl_redirect_http*]
#   Controls whether a redirect is configured to redirect any non-SSL traffic
#   to the SSL-enabled host. Only used when 'ssl' is true.
#   Defaults to false.
#
# === Examples
#
#   reviewboard::site {'/var/www/reviewboard':
#     dbpass    => 'password1',
#     adminpass => 'password2',
#   }
#
#   reviewboard::site {'/var/www/reviewboard':
#     vhost             => 'myhost.example.com',
#     location          => '/'
#     dbtype            => 'mysql',
#     dbhost            => 'mysql.example.com',
#     dbname            => 'rboard_db',
#     dbuser            => 'rboard_user',
#     dbpass            => 'password1',
#     dbcreate          => false,
#     adminpass         => 'password2',
#     ssl               => true,
#     ssl_redirect_http => true,
#   }

define reviewboard::site (
  $site              = $name,
  $vhost             = $::fqdn,
  $location          = '/reviewboard',
  $dbtype            = 'postgresql',
  $dbname            = 'reviewboard',
  $dbhost            = 'localhost',
  $dbuser            = 'reviewboard',
  $dbpass            = undef,
  $dbcreate          = true,
  $admin             = 'admin',
  $adminpass         = undef,
  $adminemail        = "${reviewboard::webuser}@${::fqdn}",
  $company           = '',
  $cache             = 'memcached',
  $cacheinfo         = 'localhost:11211',
  $webuser           = $reviewboard::webuser,
  $ssl               = false,
  $ssl_key           = undef,
  $ssl_crt           = undef,
  $ssl_chain         = undef,
  $ssl_redirect_http = false,
) {
  include reviewboard

  #
  # Parameter validation
  #

  validate_absolute_path($site)

  # TODO validate valid hostname
  validate_string($vhost)

  # XXX This will also allow Windows-style paths
  validate_absolute_path($location)

  validate_re($dbtype, [ '^postgresql$', '^mysql$' ],
    "Invalid database type '${dbtype}' specified")

  validate_string($dbname)

  # TODO validate valid hostname
  validate_string($dbhost)

  validate_string($dbuser)

  if $dbpass == undef {
    fail('Database password not set')
  }

  validate_bool($dbcreate)

  validate_string($admin)

  if $adminpass == undef {
    fail('Admin password not set')
  }

  # TODO validate email address
  validate_string($adminemail)

  validate_string($company)

  validate_re($cache, [ '^memcached$', '^file$' ],
    "Invalid cache type '${cache}' specified")

  if ($cache == 'file') {
    validate_absolute_path($cacheinfo)
  } else {
    validate_string($cacheinfo)
  }

  validate_bool($ssl)

  if $ssl_key != undef {
    validate_absolute_path($ssl_key)
  }

  if $ssl_crt != undef {
    validate_absolute_path($ssl_crt)
  }

  if $ssl_chain != undef {
    validate_absolute_path($ssl_chain)
  }

  validate_bool($ssl_redirect_http)

  # Create the database
  reviewboard::provider::db {$site:
    dbuser   => $dbuser,
    dbpass   => $dbpass,
    dbname   => $dbname,
    dbhost   => $dbhost,
    dbcreate => $dbcreate,
  }

  case $location { # A trailing slash is required
    /\/$/:   { $normalized_location = $location}
    default: { $normalized_location = "${location}/" }
  }

  # Run site-install
  reviewboard::site::install {$site:
    vhost      => $vhost,
    location   => $normalized_location,
    dbtype     => $dbtype,
    dbname     => $dbname,
    dbhost     => $dbhost,
    dbuser     => $dbuser,
    dbpass     => $dbpass,
    admin      => $admin,
    adminpass  => $adminpass,
    adminemail => $adminemail,
    company    => $company,
    cache      => $cache,
    cacheinfo  => $cacheinfo,
    require    => Reviewboard::Provider::Db[$site],
  }

  # Set up the web server
  reviewboard::provider::web {$site:
    vhost             => $vhost,
    location          => $location,
    webuser           => $webuser,
    ssl               => $ssl,
    ssl_key           => $ssl_key,
    ssl_crt           => $ssl_crt,
    ssl_chain         => $ssl_chain,
    ssl_redirect_http => $ssl_redirect_http,
    require           => Reviewboard::Site::Install[$site],
  }

}
