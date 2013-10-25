class Riemann::Babbler::Plugin::Pgsql < Riemann::Babbler::Plugin

  def init
    plugin.set_default(:service, 'pgsql')
    plugin.set_default(:host, '127.0.0.1')
    plugin.set_default(:user, 'postgres')
    plugin.set_default(:chk_file, '/usr/bin/pg_config')

    plugin.set_default(:rep_lag_sql, "select date_part('epoch', pg_last_xact_replay_timestamp() - now())::int")
    plugin.set_default(:rep_lag_warn, 500)
    plugin.set_default(:rep_lag_crit, 1000)

    plugin.set_default(:conn_warn, 5)
    plugin.set_default(:conn_crit, 3)

    plugin.set_default(:interval, 60)
  end

  def run_plugin
    File.exists? plugin.chk_file
  end

  def run_sql(sql)
    shell("psql -h #{plugin.host} -U #{plugin.user} -tnc \"#{sql}\" postgres")
  end

  def in_recovery?
    run_sql('select pg_is_in_recovery()') == 't'
  end

  # connection to pg
  def connections
    max_conn = run_sql('show max_connections').to_i
    res_conn = run_sql('show superuser_reserved_connections').to_i
    cur_conn = run_sql('select count(1) from pg_stat_activity;').to_i
    [cur_conn, (max_conn - res_conn - cur_conn)]
  end

  def rep_lag_state
    rep_lag = abs(run_sql(plugin.rep_lag_sql).to_i)
    if rep_lag >= plugin.rep_lag_crit
      { :service => plugin.service + ' rep_lag', :description => 'Postgresql replication lag state', :state => 'critical', :metric => rep_lag }
    elsif rep_lag >= plugin.rep_lag_warn
      { :service => plugin.service + ' rep_lag', :description => 'Postgresql replication lag state', :state => 'warning', :metric => rep_lag }
    else
      { :service => plugin.service + ' rep_lag', :description => 'Postgresql replication lag state', :state => 'ok', :metric => rep_lag }
    end
  end

  def collect
    status = Array.new

    cur_conn, res_conn = connections

    status << rep_lag_state if in_recovery?
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
