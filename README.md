Ubuntu 24.04 with XFCE4 desktop

Runs websockify to expose the VNC port where 
the VNC server is running and exposes it via 
apache2 proxy on port 80.

# Run notes

--privileged is required in your docker run command.

# Default build command

docker build -t vnc_ubuntu24 . --progress=plain

# Default command for run

docker run --privileged -it -dt --name Ubuntu24 -p <port>:5901 -p <port>:22 -p <port>:80 vnc_ubuntu24:latest

## Exposed ports
5901 -> VNC default port, allows a VNC client to connect
22 -> SSH port
80 -> default apache webserver port
