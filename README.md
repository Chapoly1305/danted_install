# Dante SOCKS Proxy Service Installer & Manager

This script provides a simplified way to install, manage, and uninstall the Dante SOCKS proxy server on your Linux system. It handles all the necessary configurations and presents an interactive menu-driven interface.

## Features

- Auto-detects package manager (supports `apt` and `yum`).
- Easily install and uninstall the Dante SOCKS proxy server.
- Interactive interface selection during installation.
- User management for the Dante SOCKS proxy service.
- Configures firewall rule to allow the SOCKS proxy port (1080 by default).
- Safe user input handling to prevent malicious injections.

## Prerequisites

- `yum` or `apt` package manager
- `systemctl` for service management
- (optional) `ufw` for firewall configurations
- Script must be run as root

## Usage

1. Clone/download the script to your Linux machine.
2. Give it executable permissions:
   ```bash
   chmod +x <script-name>.sh
   ```
3. Run the script as root
   ```bash
   sudo ./<script-name>.sh
   ``````
4. Follow the on-screen instructions to install, manage users, or uninstall the service.
5. Test if the proxy works properly. 
    ```bash
    curl -x socks5://your_dante_user:your_dante_password@your_server_ip:1080 'https://api.ipify.org?format=json'
    ```

## Menu Options

1. Install Service: This option will install the Dante SOCKS proxy server and configure it.
2. Add a User: This will create a new user that can authenticate to the Dante SOCKS proxy.
3. Delete a User: Delete an existing user from the Dante SOCKS proxy.
4. Uninstall Service: Uninstall the Dante SOCKS proxy server and clean up configurations.
5. Exit: Exit the script.

## Caution

* Always make sure to back up your system or test in a virtual environment before running scripts that make changes to your system configuration.
* If you're not familiar with Dante or SOCKS proxies, read more about them to understand the potential risks and benefits of running such services.

## License
This script is released under the MIT License.