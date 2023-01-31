# @summary
#   Setup Director database.
#
# @param db_type
#   What kind of database type to use.
#
# @param web_instances
#   List of Hosts to allow write access to the database.
#   Usually an Icinga Web 2 instance.
#
# @param db_pass
#   Password to connect the database.
#
# @param db_name
#   Name of the database.
#
# @param db_user
#   Database user name.
#
# @param tls
#   Access only for TLS encrypted connections. Authentication via `password` or `cert`,
#   value `true` means password auth.
#
class icinga::web::director::database (
  Enum['mysql','pgsql']      $db_type,
  Array[Stdlib::Host]        $web_instances,
  Icinga::Secret             $db_pass,
  String                     $db_user = 'director',
  String                     $db_name = 'director',
  Variant[Boolean,
  Enum['password','cert']]   $tls      = false,
) {
  $_encoding = $db_type ? {
    'mysql' => 'utf8',
    default => 'UTF8',
  }

  icinga::database { "${db_type}-${db_name}":
    db_type          => $db_type,
    db_name          => $db_name,
    db_user          => $db_user,
    db_pass          => $db_pass,
    access_instances => $web_instances,
    mysql_privileges => ['ALL'],
    encoding         => $_encoding,
    tls              => $tls,
  }

  if $db_type == 'pgsql' {
    postgresql::server::extension { "${db_name}-pgcrypto":
      extension    => 'pgcrypto',
      database     => $db_name,
      package_name => 'postgresql-contrib',
    }
  }
}
