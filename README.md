Puppet Reviewboard
==================

Manage an install of [Reviewboard](http://www.reviewboard.org)

To install include the package 'reviewboard' in your manifest

Optionally you can install the RBtool package for submitting reviews by
including 'reviewboard::rbtool'

Pre-Requisites
--------------

The Modulefile only lists the mandatory 'stdlib' dependency. It is possible to
configure what modules are used to provide the web server and database, it is
neccessary to separately install these dependencies, e.g. for the default
setup:

    puppet module install puppetlabs/apache
    puppet module install puppetlabs/postgresql

The modules available are listed below in the 'Usage' section, pull requests to
support other providers are welcome.

Additionally the following optional prerequisites may be installed:

 * memcached & python-memcached for website caching
 * python bindings for your database (if not installed by the dbprovider)

Usage
-----

Create a reviewboard site based at '/var/www/reviewboard', available at ${::fqdn}/reviewboard:

    reviewboard::site {'/var/www/reviewboard':
        vhost    => "${::fqdn}",
        location => '/reviewboard'
    }

You can change the review board version installed with the 'version' argument to the
reviewboard class. Acceptable values for the version argument look like '1.7.20' or
'2.0rc1'. You can find a catalog of versions at:

http://downloads.reviewboard.org/releases/ReviewBoard/.

You can change how the sites are configured with the 'provider' arguments to the reviewboard class. 

**webprovider**:
  * *puppetlabs/apache*: Use puppetlabs/apache to create an Apache vhost
  * *simple*: Copy the apache config file generated by reviewboard & set up a basic Apache server
  * *none*: No web provisioning is done

**dbprovider**:
  * *puppetlabs/postgresql*: Use the puppetlabs/postgresql module to create database tables & install bindings
  * *none*: No DB provisioning is done (note a database is required for the install to work)

The default settings are
    
    class reviewboard {
        version     => '1.7.22',
        webprovider => 'puppetlabs/apache',
        dbprovider  => 'puppetlabs/postgresql'
    }

To use a custom web provider set the 'webuser' parameter & subscribe the web
service to `reviewboard::provider::web<||>`:

    class reviewboard {
        webprovider => 'none',
        webuser     => 'apache',
    }
    Reviewboard::Provider::Web<||> ~> Service['apache']

You will then need to manually configure your web server, Reviewboard generates
an example Apache config file in ${site}/conf/apache-wsgi.conf.

Other Features
--------------

 * **RBTool**: Reviewboard command-line interface. To install:

        include reviewboard::rbtool

 * **Trac integration**: The [traclink](https://github.com/ScottWales/reviewboard-trac-link) Reviewboard plugin posts a notice on a Trac ticket whenever the 'Bug' field is set in a review. To install:

        package {trac: } # Make sure Trac is installed via Puppet
        include reviewboard::traclink

    There is also some setup required in your site's `trac.ini`:

        [ticket-custom]
        reviews = text
        reviews.format = wiki
        [interwiki]
        review = //reviewboard/r/

Testing
-------

Integration tests make use of [serverspec](http://serverspec.org) to check the module is applied properly on a Vagrant VM.

To setup tests

    $ gem install bundler
    $ bundle install --path vendor/bundle

then to run the tests

    $ bundle exec rake

Use `vagrant destroy` to stop the test VM.

