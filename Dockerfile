FROM ubuntu:18.04
RUN apt-get update
RUN yes | unminimize

RUN apt-get install -y -q vim
RUN apt-get install -y -q htop
RUN apt-get install -y -q git
RUN apt-get install -y -q openssh-server
RUN apt-get install -y -q mosh
RUN apt-get install -y -q python
RUN apt-get install -y -q curl
RUN apt-get install -y -q build-essential autotools-dev automake pkg-config
RUN apt-get install -y -q nginx

RUN touch /etc/inittab
RUN apt-get install -y -q runit

RUN useradd -d /home/sam -p password -G sudo -m -s /bin/bash sam

RUN mkdir /opt/local || echo 'Local directory exists already'o
RUN mkdir /opt/src || echo 'Sources directory exists already'

RUN mkdir /home/sam/.vim
WORKDIR /home/sam/.vim
RUN git config --global url.https://github.com/.insteadOf git://github.com/
RUN git config --global url.https://github.com/.insteadOf git@github.com:
RUN git clone https://github.com/samgiles/vim-setup .
RUN cp vimrc .vimrc
RUN git submodule update --init --recursive

#Install NodeJS
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y -q nodejs

# Disable password auth
RUN sed -i -e 's/^#PasswordAuthentication\syes/PasswordAuthentication no/' /etc/ssh/sshd_config
RUN sed -i -e 's/^\(session\s\+required\s\+pam_loginuid.so$\)/#\1/' /etc/pam.d/sshd

RUN mkdir /var/run/sshd
RUN mkdir ~sam/.ssh

COPY config/nginx.conf /etc/nginx/sites-enabled/default
RUN echo 'username ALL=NOPASSWD: ALL' >> /etc/sudoers

ADD config/runit/sshd /etc/service/sshd/run
RUN chmod +x /etc/service/sshd/run

ADD config/runit/nginx /etc/service/nginx/run
RUN chmod +x /etc/service/nginx/run

ADD ./ssh/id_rsa.pub /home/sam/.ssh/authorized_keys
CMD /usr/bin/runsvdir -P /etc/service
EXPOSE 22 6000 80
