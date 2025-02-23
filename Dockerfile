FROM ubuntu:latest as system

ENV DEBIAN_FRONTEND noninteractive
ENV WINDOWMANAGER xfce4

RUN apt-get update && apt-get install -y openssh-server xauth x11-xserver-utils x11-utils xfce4 xfce4-goodies xfonts-base dbus-x11 sudo xvfb xorg



# Create /run/sshd directory
RUN mkdir -p /run/sshd

# Configure SSH server to allow X11 forwarding
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN echo "X11Forwarding yes" >> /etc/ssh/sshd_config
RUN echo "X11DisplayOffset 10" >> /etc/ssh/sshd_config

# Set password for root account
RUN echo "root:password" | chpasswd

# Expose SSH port
EXPOSE 22

RUN apt-get update && apt-get install -y websockify novnc
RUN openssl req -x509 -newkey rsa:2048 -nodes -keyout /etc/ssl/private/server.key -out /etc/ssl/private/server.pem -days 365 -subj "/C=US/ST=State/L=Locality/O=Organization/CN=localhost"

RUN apt-get update && apt-get install -y x11vnc fonts-liberation

RUN mkdir /root/.chromium && cd /root/.chromium

RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

RUN dpkg -i google-chrome-stable_current_amd64.deb

WORKDIR /usr/share/applications

RUN sed -i 's/Exec=\/usr\/bin\/google-chrome-stable/Exec=\/usr\/bin\/google-chrome-stable --no-sandbox %U/g'  google-chrome.desktop

# Set the VNC password
RUN x11vnc -storepasswd password /etc/x11vnc.password

# Set the X11 display number
ENV DISPLAY=:1

# Set the X11 environment variables
ENV X11VNC_FINDDISPLAY=on
ENV X11VNC_CREATEGC=on
ENV X11VNC_CREATEGEOM=on
ENV X11VNC_CREATEWINDGEOF=on

ENV DISPLAY=:1

RUN /usr/sbin/sshd -D &
RUN Xvfb :1 -screen 0 1024x768x24 &
RUN sleep 5
RUN x11vnc -rfbport 5901 -noshm -forever &
RUN openbox --replace &


EXPOSE 80
EXPOSE 5901

ENV DESKTOP_SESSION=xfce

RUN touch /startup.sh
RUN echo "#!/bin/bash" >> /startup.sh
RUN echo "/usr/sbin/sshd -D &" >> /startup.sh
RUN echo "Xvfb :1 -screen 0 1024x768x24 &" >> /startup.sh
RUN echo "x11vnc -rfbport 5901 -noshm -forever &" >> /startup.sh
RUN echo "websockify --web=/usr/share/novnc --cert=/etc/ssl/private/server.pem --key=/etc/ssl/private/server.key 9081 localhost:5901 &" >> /startup.sh
RUN echo "setcap cap_sys_admin+ep /usr/bin/xfce4-session &" >> /startup.sh
RUN echo "xfce4-session &" >> /startup.sh
RUN echo "service apache2 start" >> /startup.sh
RUN echo "/bin/bash " >> /startup.sh
RUN chmod +x /startup.sh

RUN apt-get install -y apache2
RUN apt-get install -y lynx

RUN a2enmod proxy proxy_wstunnel proxy_http

RUN rm /etc/alternatives/www-browser
RUN ln -s /usr/bin/lynx /etc/alternatives/www-browser

COPY 000-default.conf /etc/apache2/sites-available

RUN update-rc.d apache2 enable

ENV USER=ubuntu

USER root
WORKDIR /
ENTRYPOINT ["bash", "/startup.sh"]

FROM system as nodelayer

RUN apt-get install -y curl 

RUN touch /root/.bashrc && chmod +x /root/.bashrc

RUN mkdir /root/.nvm

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN source ~/.nvm/nvm.sh && nvm install --lts && nvm use --lts && which npm 

