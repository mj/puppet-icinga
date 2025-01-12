# @summary
#   Setup Icinga Web 2 including a database backend for user settings,
#   PHP and a Webserver.
#
# @param default_admin_user
#   Set the initial name of the admin user.
#
# @param default_admin_pass
#   Set the initial password for the admin user.
#
# @param db_pass
#   Password to connect the database.
#
# @param apache_cgi_pass_auth
#   Either turn on or off the apache cgi pass thru auth.
#   An option available since Apache v2.4.15 and required for authenticated access to the Icinga Web Api.
#
# @param db_type
#   What kind of database type to use.
#
# @param db_host
#   Database host to connect.
#
# @param db_port
#   Port to connect. Only affects for connection to remote database hosts.
#
# @param db_name
#   Name of the database.
#
# @param db_user
#   Database user name.
#
# @param manage_database
#   Create database.
#
# @param api_host
#   Single or list of Icinga 2 API endpoints to connect.
#
# @param api_user
#   Icinga 2 API user.
#
# @param api_pass
#   Password to connect the Icinga 2 API.
#
class icinga::web (
  Icinga::Secret                              $db_pass,
  Icinga::Secret                              $api_pass,
  Boolean                                     $apache_cgi_pass_auth,
  String                                      $default_admin_user = 'icingaadmin',
  Icinga::Secret                              $default_admin_pass = 'icingaadmin',
  Enum['mysql', 'pgsql']                      $db_type            = 'mysql',
  Stdlib::Host                                $db_host            = 'localhost',
  Optional[Stdlib::Port::Unprivileged]        $db_port            = undef,
  String                                      $db_name            = 'icingaweb2',
  String                                      $db_user            = 'icingaweb2',
  Boolean                                     $manage_database    = false,
  Variant[Stdlib::Host, Array[Stdlib::Host]]  $api_host           = 'localhost',
  String                                      $api_user           = 'icingaweb2',
) {
  # install all required php extentions
  # by icingaweb (done by package dependencies) before PHP
  Package['icingaweb2']
  -> Class['php']
  -> Class['apache']
  -> Class['icingaweb2']

  #
  # Platform
  #
  case $facts['os']['family'] {
    'redhat': {
      case $facts[os][release][major] {
        '6': {
          $php_globals = {
            php_version => 'rh-php70',
            rhscl_mode => 'rhscl',
          }
        }
        '7': {
          $php_globals = {
            php_version => 'rh-php73',
            rhscl_mode => 'rhscl',
          }
        }
        default: {
          $php_globals = {}
        }
      }

      $package_prefix = undef
    } # RedHat

    'debian': {
      $php_globals    = {}
      $package_prefix = 'php-'
    } # Debian

    default: {
      fail("'Your operatingsystem ${facts['os']['name']} is not supported.'")
    }
  }

  #
  # PHP
  #
  class { 'php::globals':
    * => $php_globals,
  }

  class { 'php':
    ensure         => installed,
    manage_repos   => false,
    package_prefix => $package_prefix,
    apache_config  => false,
    fpm            => true,
    dev            => false,
    composer       => false,
    pear           => false,
    phpunit        => false,
    require        => Class['php::globals'],
  }

  #
  # Apache
  #
  $manage_package = false

  package { ['icingaweb2', 'icingaweb2-module-pdfexport']:
    ensure => installed,
  }

  class { 'apache':
    default_mods => false,
    mpm_module   => 'event',
  }

  $web_conf_user = $apache::user

  include apache::vhosts

  include apache::mod::alias
  include apache::mod::mime
  include apache::mod::status
  include apache::mod::dir
  include apache::mod::env
  include apache::mod::rewrite
  include apache::mod::proxy
  include apache::mod::proxy_fcgi
  include apache::mod::proxy_http
  include apache::mod::ssl

  apache::custom_config { 'icingaweb2':
    ensure        => present,
    content       => template('icinga/apache_custom_default.conf.erb'),
    verify_config => false,
    priority      => false,
  }

  #
  # Database
  #
  if $manage_database {
    class { 'icinga::web::database':
      db_type       => $db_type,
      db_name       => $db_name,
      db_user       => $db_user,
      db_pass       => $db_pass,
      web_instances => ['localhost'],
      before        => Class['icingaweb2'],
    }
    $_db_host = 'localhost'
  } else {
    if $db_type != 'pgsql' {
      include mysql::client
    } else {
      include postgresql::client
    }
    $_db_host = $db_host
  }

  #
  # Icinga Web 2
  #
  class { 'icingaweb2':
    db_type                => $db_type,
    db_host                => $_db_host,
    db_port                => $db_port,
    db_name                => $db_name,
    db_username            => $db_user,
    db_password            => $db_pass,
    default_admin_username => $default_admin_user,
    default_admin_password => $default_admin_pass,
    import_schema          => lookup('icingaweb2::import_schema', undef, undef, true),
    config_backend         => 'db',
    conf_user              => $web_conf_user,
    manage_package         => $manage_package,
  }
}
