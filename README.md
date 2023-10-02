# All-In-One Proxy Tools

This script automates setting up TUIC and hysteria and other proxy-related tools in Linux according to [iSegaro's tuic tutorial](https://telegra.ph/How-to-start-the-TUIC-v5-protocol-with-iSegaro-08-26) and [iSegaro's hysteria tutorial](https://telegra.ph/How-run-Hysteria-Protocol-with-iSegaro-04-07)

## Features
- Hysteria
- Hysteria V2
- Tuic
- Reverse TLS Tunnel( Thanks to [Radkesvat](https://github.com/radkesvat/ReverseTlsTunnel) and [Peyman](https://github.com/Ptechgithub/ReverseTlsTunnel) )
- Different Panels( [X-Ui by Alireza](https://github.com/alireza0/x-ui), [X-Ui Sanaei](https://github.com/MHSanaei/3x-ui), [RealityEZPZ by Aleskxyz](https://github.com/aleskxyz/reality-ezpz), [Hiddify](https://github.com/hiddify/Hiddify-Server), and [Marzban](https://github.com/Gozargah/Marzban/) )
- Install, disable, and enable Warp(using [yonggekkk's script](https://github.com/yonggekkk/warp-yg) )
- Show Ports in use and their corresponding processes

   
## Usage

To use the script:

1. Run this command:
   ```
   source ~/.bashrc && bash <(curl -sL https://bit.ly/aio-proxy)
   ```
   or
   ```
   source ~/.bashrc && bash <(curl -sL https://raw.githubusercontent.com/hrostami/aio-proxy/master/aio.sh)
   ```
   
2. Choose from the menu which protocol you want to install

3. Follow the prompts to enter a port number and password

4. The script will install dependencies, generate certs, create a config, and start the service

5. Your proxy credentials and server info will be printed at the end
