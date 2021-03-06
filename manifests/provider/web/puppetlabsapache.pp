## \file    manifests/provider/web/puppetlabsapache.pp
#  \author  Scott Wales <scott.wales@unimelb.edu.au>
#
#  Copyright 2014 ARC Centre of Excellence for Climate Systems Science
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

# Set up the website using puppetlabs/apache

define reviewboard::provider::web::puppetlabsapache (
  $vhost,
  $location,
  $ssl,
  $ssl_key,
  $ssl_crt,
  $ssl_chain,
  $ssl_redirect_http,
) {

  $site = $name

  $port = $ssl ? {
    true  => 443,
    false => 80,
  }

  include apache::mod::wsgi
  include apache::mod::mime

  $error_documents = [{error_code => '500', document => '/errordocs/500.html'}]
  if ($location == '/') {
    $locationfragment = ''
  } else {
    $locationfragment = $location
  }

  $script_aliases  = {"${location}" => "${site}/htdocs/reviewboard.wsgi${locationfragment}"}

  $directories = [
    {path   => "${site}/htdocs",
    options => ['-Indexes','+FollowSymLinks']
    },
    {path           => "${locationfragment}/media/uploaded",
    provider        => 'location',
    custom_fragment => '
      SetHandler None
      Options None

      AddType text/plain .html .htm .shtml .php .php3 .php4 .php5 .phps .asp
      AddType text/plain .pl .py .fcgi .cgi .phtml .phtm .pht .jsp .sh .rb

      <IfModule mod_php5.c>
        php_flag engine off
      </IfModule>
    '}
  ]

  $aliases = [
    {alias => "${locationfragment}/media",
    path => "${site}/htdocs/media"
    },
    {alias => "${locationfragment}/static",
    path => "${site}/htdocs/static"
    },
    {alias => "${locationfragment}/errordocs",
    path => "${site}/htdocs/errordocs"
    },
    {alias => "${locationfragment}/favicon.ico",
    path => "${site}/htdocs/static/rb/images/favicon.png"
    },
  ]

  apache::vhost {$vhost:
    port                => $port,
    ssl                 => $ssl,
    ssl_key             => $ssl_key,
    ssl_cert            => $ssl_crt,
    ssl_chain           => $ssl_chain,
    docroot             => "${site}/htdocs",
    error_documents     => $error_documents,
    wsgi_script_aliases => $script_aliases,
    custom_fragment     => 'WSGIPassAuthorization On',
    directories         => $directories,
    aliases             => $aliases,
  }

  if ($ssl and $ssl_redirect_http) {
    apache::vhost { "${vhost} ssl-redirect":
      servername      => $vhost,
      port            => 80,
      ssl             => false,
      docroot         => "${site}/htdocs",
      redirect_source => '/',
      redirect_dest   => "https://${vhost}/",
      redirect_status => 'permanent',
    }
  }

  # Propogate update events to the service
  exec {"Update ${name}":
    command     => '/bin/true',
    refreshonly => true,
    notify      => Class['apache::service'],
  }
}
