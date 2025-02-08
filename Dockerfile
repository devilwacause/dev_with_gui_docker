FROM ubuntu:latest as system

RUN apt-get update && apt-get install -y openssh-server xauth x11-xserver-utils



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

RUN apt-get update && apt-get install -y openssh-server xauth xorg xvfb
RUN apt-get update && apt-get install -y xfce4
RUN apt-get update && apt-get install -y x11vnc

RUN apt-get update && apt-get install -y dbus-x11

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
#RUN echo "openbox --replace &" >> /startup.sh
#RUN echo "sleep 10" >> /startup.sh
#RUN echo "startlxde" >> /startup.sh
#RUN echo "sleep 10" >> /startup.sh
RUN x11vnc -rfbport 5901 -noshm -forever &
RUN websockify --web=/usr/share/novnc --cert=/etc/ssl/private/server.pem --key=/etc/ssl/private/server.key 8080 localhost:5901 &
RUN openbox --replace &


EXPOSE 8080
EXPOSE 5901

ENV DESKTOP_SESSION=xfce

RUN touch /startup.sh
RUN echo "#!/bin/bash" >> /startup.sh
RUN echo "/usr/sbin/sshd -D &" >> /startup.sh
RUN echo "Xvfb :1 -screen 0 1024x768x24 &" >> /startup.sh
RUN echo "x11vnc -rfbport 5901 -noshm -forever &" >> /startup.sh
RUN echo "websockify --web=/usr/share/novnc --cert=/etc/ssl/private/server.pem --key=/etc/ssl/private/server.key 8080 localhost:5901 &" >> /startup.sh
RUN echo "xfce4-session &" >> /startup.sh
RUN chmod +x /startup.sh

ENV USER=ubuntu

USER ubuntu