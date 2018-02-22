FROM ubuntu:14.04
LABEL maintainer="Christian Jürges, christian.juerges@20minuten.ch"

# Please keep in mind....
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#/minimize-the-number-of-layers


ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# taken from https://github.com/fstab/docker-ubuntu/blob/master/Dockerfile

# add couchbase repo
RUN echo "deb http://packages.couchbase.com/ubuntu trusty trusty/main" > /etc/apt/sources.list.d/couchbase.list 

# get repo key to install oracle java stuff
RUN gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv A3FAA648D9223EDA && \
    gpg --export --armor A3FAA648D9223EDA | sudo apt-key add -

# RUN sed -i -e 's/http:\/\/us.archive/mirror:\/\/mirrors/' -e 's/\/ubuntu\//\/mirrors.txt/' /etc/apt/sources.list
# http://ubuntu.ethz.ch/ubuntu/
RUN sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu\//http:\/\/ubuntu.ethz.ch\/ubuntu\//' /etc/apt/sources.list
# update repos and get fastest repo
RUN apt-get update && \
    apt-get upgrade -qq -y

# Set the timezone and postfix mail
RUN echo "Europe/Zurich" | tee /etc/timezone && \
    ln -fs /usr/share/zoneinfo/Europe/Zurich /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    echo "postfix postfix/mailname string 20-local.ch" | debconf-set-selections   && \
    echo "postfix postfix/main_mailer_type string 'Local only'" | debconf-set-selections  

# install needed packages part 1
RUN apt-get install -qq -y --force-yes -o=Dpkg::Use-Pty=0 \
    supervisor \
    bash-completion \
    bc \
    curl \
    git \
    inetutils-traceroute \
    iputils-ping \
    lsof \
    man \
    netcat \
    nmap \
    psmisc \
    screen \
    telnet \
    unzip \
    vim \
    sysstat \
    wget \
    curl \
    build-essential \
    software-properties-common \
    python-software-properties \
    aptitude \
    mc \
    vim \
    lsof \
    apache2 \
    apache2-mpm-prefork \
    libtevent0 \
    libcv-dev \
    libcvaux-dev \
    libhighgui-dev \
    perl-doc \
    libapache2-mod-perl2 \
    libapache2-reload-perl \
    libgd-perl \
    libalgorithm-diff-perl \
    libtest-requires-perl \
    libterm-readline-gnu-perl \
    libcrypt-cbc-perl \
    libdbi-perl \
    libnet-https-any-perl \
    libsoap-lite-perl \
    libapache-db-perl \
    libdbd-mysql-perl \
    libmail-checkuser-perl \
    libxml-libxml-perl \
    libxml-rss-perl \
    libdatetime-perl \
    libdevel-cover-perl \
    libdatetime-timezone-perl \
    libarchive-extract-perl \
    libdatetime-format-iso8601-perl \
    libcache-memcached-fast-perl \
    libfile-mimeinfo-perl \
    libmime-tools-perl \
    libxml-sax-expat-incremental-perl \
    libmail-sendmail-perl \
    libnet-ip-perl \
    libnet-http-perl \
    libnet-dns-perl \
    libnet-ssleay-perl \
    libopencv-dev \
    libdate-iso8601-perl \
    libdigest-hmac-perl \
    libtie-ixhash-perl \
    libstring-crc32-perl \
    libevent-dev \
    zlib1g-dev \
    libexpat1-dev \
    libfreetype6-dev \
    libjpeg8-dev \
    liblzma-dev \
    libpng12-dev \
    libssl-dev \
    libtiff5-dev \
    libgd-dev \
    imagemagick \
    perlmagick \
    memcached \
    git \
    postfix \
    pkg-config \
    mysql-client \
    varnish \
    beanstalkd


# add java ppa repo
RUN add-apt-repository -y ppa:webupd8team/java && \
    apt-get update && \
    echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections && \
    apt-get install -y oracle-java8-installer

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# install more perl Modules via CPAN (takes a long time to compile all things)
RUN ln -s /usr/bin/make /usr/bin/gmake
ENV PERL_MM_USE_DEFAULT 1

# install cpan
RUN apt-get -y install cpanminus
COPY perl_install_modules.list /root/perl_install_modules.list
COPY cpan.sh /root/
RUN /root/cpan.sh

# create needed directories
RUN mkdir -p /twentymin/webcache/anon && \
    chown www-data.www-data /twentymin/webcache/anon

# create some symlinks needed for perlbal and perlbal-compator
RUN adduser --system --disabled-password --shell /bin/false perlbal && \ 
    ln -s /vcfg/vm/perlbal/Plugin/DynaImg.pm /usr/local/share/perl/5.18.2/Perlbal/Plugin/ && \
    ln -s /vcfg/vm/perlbal/Plugin/SetExpires.pm /usr/local/share/perl/5.18.2/Perlbal/Plugin/ && \
    ln -s /vcfg/vm/perlbal/Plugin/TwentyRedirect.pm /usr/local/share/perl/5.18.2/Perlbal/Plugin/ && \
    ln -s /vcfg/vm/perlbal/compactor/perlbal-compactor /usr/local/bin/


# create more symlinks needed to the 20min dev system (beanstalk, inotify)
RUN ln -s /twentymin/sites/www-internal/templates /templates && \
    ln -s /twentymin/webcache /webcache && \
    ln -s /twentymin/sites/www-internal/docs /docs && \
    ln -s /twentymin/sites/www-internal/perl /perl && \
    ln -s /vcfg/vm/perlbal/compactor/startup/perlbal-compactor /etc/init.d/ && \
    ln -s /vcfg/vm/inotify/startup/bc-inotify /etc/init.d/ && \
    ln -s /vcfg/vm/inotify/bc-inotify /usr/local/bin/

# beanstalk files and symlinks
RUN rm /etc/default/beanstalkd && \
    mkdir /var/log/beanstalk/ && \
    chown www-data /var/log/beanstalk && \
    ln -s /vcfg/vm/beanstalk/beansworker.pl /usr/local/bin/beansworker.pl && \
    ln -s /vcfg/vm/beanstalk/startup/beansworker /etc/init.d/ && \
    ln -s /vcfg/vm/beanstalk/beansworker.conf /etc/beansworker.conf  && \
    ln -s /vcfg/vm/beanstalk/beanstalkd /etc/default




# Set the locale for UTF-8 support
RUN locale-gen de_DE.UTF-8 && \
    locale-gen de_DE && \
    locale-gen de_CH.UTF-8 && \
    locale-gen de_CH && \
    locale-gen en_US.UTF-8 && \
    locale-gen en_US && \
    update-locale LANG=de_CH

# enabled apache modules and enable apache mpm_prefork mode
RUN a2enmod headers expires cgi && \
    a2dismod mpm_event && \
    a2enmod mpm_prefork && \
    a2enmod cgi

# set latin1
ENV LANG de_CH.ISO-8859-1
ENV LANGUAGE de_CH.ISO-8859-1
ENV LC_ALL de_CH.ISO-8859-1
ENV PERL5LIB=/twentymin/sites/www-internal/perl


EXPOSE 80

# config
RUN echo 'defshell -bash' >> /root/.screenrc
RUN echo 'if [ -f /etc/bash_completion ] && ! shopt -oq posix; then' >> /root/.bashrc && \
    echo '    . /etc/bash_completion' >> /root/.bashrc && \
    echo 'fi' >> /root/.bashrc

COPY ./su-exec/su-exec /sbin

COPY ./start_services.sh /root/
# RUN chmod u+x /root/start_services.sh
# Define default command for the entrypoint
# COPY ./supervisord.conf /etc/supervisor/conf.d/
# ENV DEFAULT_RUNLEVEL=3
# ENTRYPOINT [ "init" ]