### WSLにFedoraをインストールするスクリプト
### 参考: https://roy-n-roy.github.io/Windows/WSL%EF%BC%86%E3%82%B3%E3%83%B3%E3%83%86%E3%83%8A/centos/

### TODO: バージョンとアーキテクチャを設定
Set-Variable -Name ver -Value '33' -Option Constant
Set-Variable -Name rc -Value '1.2' -Option Constant
Set-Variable -Name arch -Value 'x86_64' -Option Constant

function Install-Fedora([string]$ver,[string]$rc,[string]$arch) {
    
    [string]$dist_name="Fedora-$ver"
    [string]$install_path="$env:LOCALAPPDATA\wsl\Fedora\$ver-$rc"

    [string]$image_url="https://nrt.edge.kernel.org/fedora-buffet/fedora/linux/releases/$ver/Container/$arch/images/Fedora-Container-Base-$ver-$rc.$arch.tar.xz"
    [string]$archive_name=(Split-Path $image_url -Leaf)
    [string]$lnk_path="$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Fedora $ver.lnk"

    Push-Location $env:TEMP

    if (Test-Path $install_path) {
        Remove-Installation $dist_name $install_path $lnk_path
        Write-Host
    }

    # コンテナイメージをダウンロード
    try {
        Write-Host 'Downloading...'
        Invoke-WebRequest -Uri $image_url -OutFile $archive_name
    }
    catch {
        Write-Host "Invalid URL: $image_url"
        Wait-Input
        exit
    }

    # rootfsをインポート
    Install-Distribution $dist_name $install_path $archive_name

    # ユーザーを追加
    Write-Host
    Add-User $dist_name
    Write-Host

    # 追加インストール
    if ((Read-Host 'Install additional packages [y/N]') -eq 'y') {
        wsl -d $dist_name dnf groupinstall -y Core > $null 2>&1
        wsl -d $dist_name dnf install -y wget gcc g++ > $null 2>&1
    }

    # ユーザーをデフォルトに設定
    Set-DefaultUser $dist_name

    # ショートカットを作成
    if ((Read-Host 'Add a start menu shortcut [y/N]') -eq 'y') {
        Add-Shortcut $lnk_path $dist_name
    }

    Pop-Location

    Wait-Input
}
function Wait-Input {
    Write-Host
    Write-Host -NoNewLine 'Press any key to continue...'
    $null=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
function Remove-Installation([string]$dist_name,[string]$install_path,[string]$lnk_path) {
    Write-Host -NoNewline 'Removing the previous installation.'
    wsl --unregister $dist_name > $null 2>&1
    Write-Host -NoNewline '.'
    Remove-Item -Recurse $install_path -Force > $null 2>&1
    Write-Host '.'

    if (Test-Path $lnk_path) {
        Remove-Item $lnk_path -Force
    }
}
function Install-Distribution([string]$dist_name,[string]$install_path,[string]$archive_name) {
    
    # layer.tarを取得
    [string]$layer_path=''
    Get-Layer([ref]$archive_name)([ref]$layer_path)

    Write-Host -NoNewline 'Installing'
    New-Item $install_path -ItemType Directory > $null 2>&1
    Write-Host -NoNewline '.'
    wsl --import $dist_name $install_path $layer_path > $null 2>&1
    Write-Host -NoNewline '.'
    wsl -d $dist_name dnf install -y passwd cracklib-dicts > $null 2>&1
    Write-Host '.'

    # 後片付け
    Remove-Item $archive_name,$layer_path -Force
}
function Get-Layer([ref]$archive_name_ref,[ref]$layer_path_ref) {
    [string]$archive_name=$archive_name_ref.Value
    [string]$layer_path=$layer_path_ref.Value

    Write-Host -NoNewline 'Extracting'
    xz -dv $archive_name > $null 2>&1
    Write-Host -NoNewline '.'
    $archive_name=$archive_name.Substring(0,$archive_name.Length-3)
    $layer_path=(tar xf $archive_name -O manifest.json | ConvertFrom-Json).Layers
    Write-Host -NoNewline '.'
    tar xf $archive_name $layer_path > $null 2>&1
    Write-Host '.'

    $archive_name_ref.Value=$archive_name
    $layer_path_ref.Value=$layer_path
}
function Add-User([string]$dist_name) {
    [string]$username=Read-Host 'Enter new UNIX username'
    wsl -d $dist_name useradd -u 1000 $username
    wsl -d $dist_name usermod -G wheel $username
    wsl -d $dist_name passwd $username
}
function Set-DefaultUser([string]$dist_name) {
    $reg_path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss'
    $child_item=(Get-ChildItem $reg_path)

    for ($i = 0; $i -lt $child_item.Length; $i++) {
        $reg_path=$reg_path+'\'+(Split-Path $child_item[$i] -Leaf)

        if ((Get-ItemProperty($reg_path)).DistributionName -ceq $dist_name) {
            break
        }
    }
    Set-ItemProperty -Path $reg_path -Name 'DefaultUid' -Value 1000
}
function Add-Shortcut([string]$lnk_path,[string]$dist_name) {
    
    $lnk=(New-Object -ComObject WScript.Shell).CreateShortcut($lnk_path)
    $lnk.TargetPath = "$env:SystemRoot\System32\wsl.exe"
    $lnk.Arguments = "-d $dist_name"
    
    $lnk.Save()
}

Install-Fedora $ver $rc $arch
