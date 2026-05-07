module.exports = {
  apps: [
    {
      name: 'mongodb',
      script: 'mongod',
      args: '--dbpath /data/db --logpath /var/log/mongodb/mongod.log --bind_ip_all --wiredTigerCacheSizeGB 2.58',
      interpreter: 'none',
      exec_mode: 'fork',
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 3000,
      kill_timeout: 10000,
      pid_file: '/root/.pm2/pids/mongodb.pid',
      out_file: '/root/.pm2/logs/mongodb-out.log',
      error_file: '/root/.pm2/logs/mongodb-error.log'
    },
    {
      name: 'hydro-sandbox',
      script: '/bin/bash',
      args: '-c "ulimit -s unlimited && sandbox -mount-conf /root/.hydro/mount.yaml -http-addr=localhost:5050"',
      interpreter: 'none',
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 3000,
      out_file: '/root/.pm2/logs/hydro-sandbox-out.log',
      error_file: '/root/.pm2/logs/hydro-sandbox-error.log'
    },
    {
      name: 'hydrooj',
      script: '/usr/local/bin/hydrooj',
      interpreter: '/usr/local/bin/node',
      exec_mode: 'fork',
      autorestart: true,
      max_restarts: 10,
      min_uptime: '10s',
      restart_delay: 3000,
      kill_timeout: 5000,
      pid_file: '/root/.pm2/pids/hydrooj.pid',
      out_file: '/root/.pm2/logs/hydrooj-out.log',
      error_file: '/root/.pm2/logs/hydrooj-error.log',
      env: {
        HYDRO_SANDBOX_ENDPOINT: 'http://localhost:5050'
      }
    }
  ]
};