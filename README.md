# AIO Auto Proxy Setup

This script automates setting up TUIC and hysteria  on Linux according to [iSegaro's tuic tutorial](https://telegra.ph/How-to-start-the-TUIC-v5-protocol-with-iSegaro-08-26) and [iSegaro's hysteria tutorial](https://telegra.ph/How-run-Hysteria-Protocol-with-iSegaro-04-07)

## Usage

To use the script:

1. Run this command if it's first time running this script(بار اول):
   ```
   git clone https://github.com/hrostami/aio-proxy.git && cd aio-proxy && sudo bash setup_menu.sh
   ```
   or this one if you've already downloaded the script(دفعات بعد):
    ```
   cd aio-proxy && git pull origin && sudo bash setup_menu.sh
   ```
   
2. Choose from the menu which protocol you want to install

3. Follow the prompts to enter a port number and password

4. The script will install dependencies, generate certs, create a config, and start the service

5. Your proxy credentials and server info will be printed at the end
