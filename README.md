# install-fedora-wsl
Install Fedora for WSL

## Requirements
- [Windows Subsystem for Linux](https://docs.microsoft.com/ja-jp/windows/wsl/install-win10)
- [XZ Utils](https://tukaani.org/xz/)

## Usage
1. Confirm following lines

    ```ps1
    Set-Variable -Name ver -Value '33' -Option Constant
    Set-Variable -Name rc -Value '1.2' -Option Constant
    Set-Variable -Name arch -Value 'x86_64' -Option Constant
    ```
    In this case, the script is going to download `Fedora-Container-Base-33-1.2.x86_64.tar.xz` from https://nrt.edge.kernel.org/fedora-buffet/fedora/linux/releases/33/Container/x86_64/images/.

2. Execute `Install-Fedora.ps1`.

## Notes
- For now we need [XZ Utils](https://tukaani.org/xz/) since `tar` (Powershell) seems not to support tar.xz extraction.
- If you apply additional packages, the script install followings.
  - Core [groupinstall]
  - wget (Dependency of Visual Studio Code Server)
  - gcc (for some personal reasons)
  - g++ (ditto)

## References
- [WSLでCentOS/Fedoraを利用する](https://roy-n-roy.github.io/Windows/WSL%EF%BC%86%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A/centos/)
