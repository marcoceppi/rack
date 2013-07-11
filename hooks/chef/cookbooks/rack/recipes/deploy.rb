deploy_revision '/var/www/rack' do
  repo config_get('repo')
  action :deploy
  symlink_before_migrate({})
  user 'deploy'
  group 'deploy'

  case config_get('scm_provider')
  when 'git'
    branch config_get('branch')
    ssh_wrapper "/tmp/private_code/wrap-ssh.sh"
  when 'svn'
    revision config_get('revision')
    scm_provider Chef::Provider::Subversion
    svn_username config_get('svn_username')
    svn_password config_get('svn_password')
  else
    raise ArgumentError
  end

  before_migrate do
    execute 'bundle install' do
      cwd release_path
      user 'deploy'
      group 'deploy'
      command "unset BUNDLE_GEMFILE RUBYOPT GEM_HOME && bundle install --deployment --path /var/www/rack/shared/bundle"
      action :run
    end
  end

  before_restart do
    rake_task 'assets:precompile' do
      cwd '/var/www/rack/current'
      user 'deploy'
      group 'deploy'
      action :run
    end
  end
end