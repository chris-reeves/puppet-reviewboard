## \file    manifests/provider/web.pp
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

# Delegate to custom web provider (e.g. puppetlabs/apache, custom, etc)
define reviewboard::provider::web (
  $vhost,
  $location,
  $webuser,
  $ssl,
  $ssl_key,
  $ssl_crt,
  $ssl_chain,
  $ssl_redirect_http,
) {

  $site = $name

  if $reviewboard::webprovider == 'simple' {
    if $ssl {
      fail("Web provider 'simple' does not support ssl")
    }

    reviewboard::provider::web::simple {$site:
      vhost    => $vhost,
      location => $location,
    }

    $realwebuser = 'apache'
    $webservice  = Service['httpd']

  } elsif $reviewboard::webprovider == 'puppetlabs/apache' {
    include apache
    reviewboard::provider::web::puppetlabsapache {$site:
      vhost             => $vhost,
      location          => $location,
      ssl               => $ssl,
      ssl_key           => $ssl_key,
      ssl_crt           => $ssl_crt,
      ssl_chain         => $ssl_chain,
      ssl_redirect_http => $ssl_redirect_http,
    }

    $realwebuser = $apache::user
    $webservice  = Class['apache::service']

  } elsif $reviewboard::webprovider == 'none' {
    # No-op

    # If you're using a custom web provider you'll need to manually set up
    # service notifications, e.g.
    # Reviewboard::Provider::Web<||> ~> Service['apache']
    $realwebuser = $webuser
    $webservice  = undef

  } else {
    fail("Web provider '${reviewboard::webprovider}' not defined")
  }

  # Set web folder ownership
  file {["${site}/data", "${site}/htdocs/media", "${site}/htdocs/media/ext", "${site}/htdocs/static", "${site}/htdocs/static/ext"]:
    ensure  => directory,
    owner   => $realwebuser,
    notify  => $webservice,
    recurse => true,
  }
  file {"${site}/conf":
    ensure  => directory,
    owner   => $realwebuser,
    recurse => true,
    mode    => 'go-rwx',
  }

}
