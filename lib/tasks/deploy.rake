task :deploy do
  rev = (`git rev-list --max-count=1 HEAD`).strip
  server = 'detailedbalance.net'
  deploy_root = '/var/www/apps/mrandmrs-api'
  sh "rsync -vlr --exclude=tmp --exclude=log --exclude='*.pdf' . #{server}:#{deploy_root}"
  sh "ssh #{server} 'source /etc/profile.d/rvm.sh && cd #{deploy_root} && bundle install --deployment'"
  sh "ssh #{server} 'cd #{deploy_root} && echo #{rev} > REVISION && mkdir -p tmp && touch tmp/restart.txt'"
end
