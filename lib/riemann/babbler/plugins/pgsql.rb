class Riemann::Babbler::Plugin::Pgsql < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:service, 'pgsql')
    plugin.set_default(:host, '127.0.0.1')
    plugin.set_default(:user, 'postgres')
    plugin.set_default(:psql, '/usr/bin/psql')
    plugin.set_default(:db4monit, 'riemann_monit')
    plugin.set_default(:conn_warn, 5)
    plugin.set_default(:conn_crit, 3)
    plugin.states.set_default(:warning, 120) # repl lag
    plugin.states.set_default(:critical, 500) # repl lag
    plugin.set_default(:interval, 60)
  end

  def run_plugin
    File.exists? plugin.psql
  end

  def run_sql(sql, db='postgres')
    shell("#{plugin.psql} -h #{plugin.host} -U #{plugin.user} -tnc \"#{sql}\" #{db}")
  end

  def in_recovery?
    run_sql('select pg_is_in_recovery()') == 't'
  end

  def db_exists?
    run_sql("select 1 from pg_database where datname = '#{plugin.db4monit}'") == '1'
  end

  def run_master_sql
    run_sql("create database #{plugin.db4monit}") unless db_exists?
    run_sql(
      "drop table if exists timestamp; \
      create table timestamp ( id int primary key, value timestamp default now() ); \
      insert into timestamp (id) values (1); \
      ", plugin.db4monit)
  end

  def repl_lag
    unixnow - run_sql("select extract(epoch from value::timestamp) from timestamp where id = 1;", plugin.db4monit).to_i
  end

  # connection to pg
  def connections
    max_conn = run_sql('show max_connections').to_i
    res_conn = run_sql('show superuser_reserved_connections').to_i
    cur_conn = run_sql('select count(1) from pg_stat_activity;').to_i
    [cur_conn, (max_conn - res_conn - cur_conn)]
  end

  def collect
    status = Array.new

    cur_conn, res_conn = connections

    if in_recovery?
      status << { :service => plugin.service + ' replication lag', :description => 'Postgresql replication lag', :metric => repl_lag } 
    else
      run_master_sql
    end

    status << { :service => plugin.service + ' connections', :description => 'Postgresql current connections', :state => 'ok', :metric => cur_conn }

    # check reserved pool size
    if res_conn < plugin.conn_warn
      if res_conn > plugin.conn_crit
        status << { :service => plugin.service + ' reserved connections', :description => 'Postgresql reserved connections state', :state => 'warning', :metric => res_conn }
      else
        status << { :service => plugin.service + ' reserved connections', :description => 'Postgresql reserved connections state', :state => 'critical', :metric => res_conn }
      end
    end

    status
  end

end
