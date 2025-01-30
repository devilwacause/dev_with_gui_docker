FROM dorowu/ubuntu-desktop-lxde-vnc:latest

RUN touch /root/.bashrc && chmod +x /root/.bashrc

RUN mkdir /root/.chromium && cd /root/.chromium

RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

RUN dpkg -i google-chrome-stable_current_amd64.deb

RUN apt-get update && \ 
	apt-get install -y firefox git wget 

# Set up clamav on this and run it
WORKDIR /tmp
RUN wget -o https://www.clamav.net/downloads/production/clamav-1.4.2.linux.x86_64.deb

RUN apt install -y ./clamav-1.4.2.linux.x86_64.deb

# See if we can update clam-av out the box
RUN freshclam --verbose --log=/tmp/clamav-log.log --datadir=/tmp/clamav-data



# Lets put our additional arguments here 

ARG logincommand
ARG additionalapps
ARG additionalcommands
ARG gitsource
ARG localname


RUN [ -z "$additionalapps" ] && echo 'No additional apps' || apt-get install -y $additionalapps 

RUN [ -z "$additionalcommands" ] && echo 'No additional commands' || $additionalcommands

RUN useradd -ms /bin/bash ubuntu -p password 

# Modify the chrome application launcher so we launch with --no-sandbox 
# Chrome in a container requires this flag

WORKDIR /usr/share/applications

RUN sed -i 's/Exec=\/usr\/bin\/google-chrome-stable/Exec=\/usr\/bin\/google-chrome-stable --no-sandbox %U/g'  google-chrome.desktop

RUN touch .bashrc
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
USER ubuntu

WORKDIR /home/ubuntu
RUN mkdir .nvm && mkdir Desktop
RUN mkdir -p /home/ubuntu/.config/lxsession

# Create an autostart that always fires terminal on login
RUN touch /home/ubuntu/.config/lxsession/autostart

RUN echo -e '@lxpanel --profile LXDE\n@pcmanfm --desktop --profile LXDE\n@xscreensaver -no-splash\n@lxterminal'

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

RUN ls -al

RUN cat ~/.bashrc

RUN [ -z "$logincommand" ] && echo 'No login command provided' || echo -e "\n $logincommand" >> /home/ubuntu/.bashrc

RUN source ~/.nvm/nvm.sh && nvm install --lts && nvm use --lts && which npm 

RUN chown ubuntu:ubuntu /home/ubuntu/Desktop

WORKDIR /home/ubuntu/Desktop
RUN mkdir $localname

RUN ls -al && pwd
RUN whoami

RUN git clone $gitsource $localname

RUN cd $localname && source ~/.nvm/nvm.sh && npm install 



USER root