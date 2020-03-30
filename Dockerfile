# Containerfile to run a local instance of redmine
# Currently uses the sqlite backend for simplicity
# Reference: https://www.redmine.org/projects/redmine/wiki/RedmineInstall/308
# For queries, please contact Ankur Sinha (sanjayankur31@github).

FROM ubuntu:xenial-20180705 AS ubuntu-xenial-20180705

RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get install -qq wget \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv E1DD270288B4E6030699E45FA1715D88E1DF1F24 \
 && echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu xenial main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv 80F70E11F0F0D5F10CB20E62F5DA5F09C3173AA6 \
 && echo "deb http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu xenial main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv 8B3981E7A6852F782CC4951600A6F0A3C300EE8C \
 && echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu xenial main" >> /etc/apt/sources.list \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
 && echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' > /etc/apt/sources.list.d/pgdg.list

FROM ubuntu:xenial-20180705

# Change this to the location of your repo on localhost
WORKDIR /home/asinha/Documents/02_Code/00_mine/2020-OSB/redmine/

# Test that this works
RUN pwd
RUN ls

ENV RUBY_VERSION=2.3 \
    REDMINE_VERSION=3.4.6 \
    REDMINE_USER="redmine" \
    REDMINE_HOME="." \
    REDMINE_LOG_DIR="/var/log/redmine" \
    REDMINE_ASSETS_DIR="/etc/docker-redmine" \
    REDMINE_LANG="en" \
    RAILS_ENV=production

ENV REDMINE_INSTALL_DIR="/home/asinha/Documents/02_Code/00_mine/2020-OSB/redmine" \
    REDMINE_DATA_DIR="${REDMINE_HOME}/data" \
    REDMINE_BUILD_ASSETS_DIR="${REDMINE_ASSETS_DIR}/build" \
    REDMINE_RUNTIME_ASSETS_DIR="${REDMINE_ASSETS_DIR}/runtime"

# GPG keys
COPY --from=ubuntu-xenial-20180705 /etc/apt/trusted.gpg /etc/apt/trusted.gpg
COPY --from=ubuntu-xenial-20180705 /etc/apt/sources.list /etc/apt/sources.list

# Install necessary packages, refer to install.sh in the redmine-docker repo
# Can probably be trimmed for dev deployment
RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get -qq install --no-install-recommends \
      sendmail supervisor logrotate nginx mysql-client postgresql-client ca-certificates sudo tzdata \
      imagemagick subversion git cvs bzr mercurial darcs rsync ruby${RUBY_VERSION} locales openssh-client \
      gcc g++ make patch pkg-config gettext-base ruby${RUBY_VERSION}-dev libc6-dev zlib1g-dev libxml2-dev \
      libmysqlclient20 libpq5 libyaml-0-2 libcurl3 libssl1.0.0 uuid-dev xz-utils \
      libxslt1.1 libffi6 zlib1g gsfonts wget libcurl4-openssl-dev libssl-dev \
      libmagickcore-dev libmagickwand-dev libmysqlclient-dev libpq-dev libxslt1-dev \
      libffi-dev libyaml-dev libsqlite3-dev \
 && update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
 && gem install -q --no-rdoc --no-ri sprockets -v 3.7.2 \
 && gem install -q --no-rdoc --no-ri rails -v 4.2.7.1 \
 && gem install -q --no-rdoc --no-ri bundler -v 1.17.3 \
 && rm -rf /var/lib/apt/lists/*

RUN bundle install --without development test

RUN bundle exec rake generate_secret_token
RUN bundle exec rake db:migrate
RUN bundle exec rake redmine:load_default_data

ARG SERVER_IP
ENV SERVER_IP=${SERVER_IP:-"http://localhost:10083/"}

RUN sed -i -E "s~^serverIP:.*$~serverIP: $SERVER_IP~g" ${REDMINE_INSTALL_DIR}/config/props.yml
# RUN sed -i.orig -e "s/^geppettoIP:.*$/geppettoIP: $GEPPETTO_IP/g" ${REDMINE_INSTALL_DIR}/config/props.yml

# RUN mkdir -pv ${REDMINE_INSTALL_DIR}/public/geppetto/tmp
# RUN chown -R redmine:redmine ${REDMINE_INSTALL_DIR}/public/geppetto/tmp
# RUN rm -rf ${REDMINE_INSTALL_DIR}/plugins/recaptcha
# RUN git clone "https://github.com/cdwertmann/recaptcha" ${REDMINE_INSTALL_DIR}/plugins/recaptcha
# delete view provided by recaptcha plugin (interferes with our redmine mods)
# RUN rm -rf ${REDMINE_INSTALL_DIR}/plugins/recaptcha/app/views/account
# RUN mkdir -pv /home/svnsvn/myGitRepositories
#RUN SELECT value FROM custom_values WHERE custom_field_id=14 and value!='';  
# RUN chown -R redmine:redmine /home/svnsvn

# Let the entry point be the shell so that one can make changes and run the server as necessary
# https://www.freecodecamp.org/news/painless-rails-development-environment-setup-with-docker/
ENTRYPOINT ["/bin/bash"]
