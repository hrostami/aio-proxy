# All-In-One Proxy Tools
![AIO in action](https://gcdnb.pbrd.co/images/QXK9F18G0glj.png?o=1)

This script automates setting up TUIC, hysteria and other proxy-related tools in Linux.
## Features
- Setting domains( for both IPv4 and IPv6 proxy configs will be shown using domains if set) 
- Getting SSL certification for the domains and setting up a simple web page( Probe Resistance )
- Chisel Tunnel ( according to [iSegaro's tutorial](https://telegra.ph/How-to-tunnel-traffic-over-HTTP-with-iSegaro-11-24) )
- Hysteria V2 ( according to [iSegaro's hysteria v2 tutorial](https://telegra.ph/How-run-Hysteria-V2-Protocol-with-iSegaro-09-0) )
- Tuic ( according to [iSegaro's tuic tutorial](https://telegra.ph/How-to-start-the-TUIC-v5-protocol-with-iSegaro-08-26) )
- [Hiddify Reality Scanner](https://github.com/hiddify/Hiddify-Reality-Scanner)
- SSH ( you can set a custom port for each user)
- Telegram Proxy ( All 4 methods thanks to [@hirbodbehnam script](https://github.com/HirbodBehnam/MTProtoProxyInstaller) )
- Reverse TLS Tunnel( Thanks to [Radkesvat](https://github.com/radkesvat/ReverseTlsTunnel) and [Peyman](https://github.com/Ptechgithub/ReverseTlsTunnel) )
- Different Panels( [X-Ui by Alireza](https://github.com/alireza0/x-ui), [X-Ui Sanaei](https://github.com/MHSanaei/3x-ui), [RealityEZPZ by Aleskxyz](https://github.com/aleskxyz/reality-ezpz), [Hiddify](https://github.com/hiddify/Hiddify-Server), and [Marzban](https://github.com/Gozargah/Marzban/) )
- Install, disable, and enable Warp(using [yonggekkk's script](https://github.com/yonggekkk/warp-yg) )
- Sing Box 4-in-1 (reality+hyseria2+tuic+argo) script by [Yongge](https://gitlab.com/rwkgyg/sing-box-yg)
- Show Ports in use and their corresponding processes
- Android Script to use Chisel tunnel, just run the code below in Termux then enter the proxy port and domain:
```
bash <(curl -sL https://raw.githubusercontent.com/hrostami/aio-proxy/master/android-chisel.sh)
```

   
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
