# @summary
#   Setup Icinga Web 2 database for user settings.
#
# @param db_type
#   What kind of database type to use.
#
# @param web_instances
#   List of Hosts to allow write access to the database. Usually an Icinga Web 2 instance.
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
class icinga::web::database (
  Enum['mysql','pgsql']      $db_type,
  Array[Stdlib::Host]        $web_instances,
  String                     $db_pass,
  String                     $db_name = 'icingaweb2',
  String                     $db_user = 'icingaweb2',
  Variant[Boolean,
  Enum['password','cert']]   $tls      = false,
) {
  icinga::database { "${db_type}-${db_name}":
    db_type          => $db_type,
    db_name          => $db_name,
    db_user          => $db_user,
    db_pass          => $db_pass,
    access_instances => $web_instances,
    mysql_privileges => ['ALL'],
    tls              => $tls,
  }
}
