# インストール方法(Ubuntu20.04)
OSはUbuntu 20.04を想定しています。それ以外のOSでは適宜読み替えてください。

## インストール下準備
標準的なこと
``` shell
# アップデートしてtimezone直す
sudo apt update
sudo apt upgrade
sudo timedatectl set-timezone Asia/Tokyo
```
必要なパッケージのインストール
``` shell
# PowerShell用リポジトリの追加(URLはUbuntu20.04のものなので、他のディストリビューションでは適宜変更)
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update

# 必要なものインストール
sudo apt install git nginx ffmpeg powershell
sudo apt install avahi-daemon # サーバへhogehoge.localでアクセスしたい場合のみ
```
スクリプト取得
``` shell
sudo git clone https://github.com/maeda577/VoiceActorRadioDownloader.git /usr/local/bin/VoiceActorRadioDownloader/
cd /usr/local/bin/VoiceActorRadioDownloader/
sudo git pull origin v0.3 # 最新のバージョンタグ名を指定
```

## 設定
[設定ファイルサンプル](./conf.jsonc)を元にうまいこと設定してください。
``` shell
# configファイルをrootのhomeディレクトリなど、非管理者から読めない場所に置いて編集
# (音泉のID/Passwordを書く必要があるため。音泉PREMIUMを使わないならどこでもいい)
sudo cp ./config.sample.json /root/vard_config.json
sudo vi /root/vard_config.json
```

## テスト実行とタイマー設定
テスト実行
``` shell
# 準備した設定ファイルで実行してみてみる (正常動作している場合は特に何も表示されない)
sudo pwsh /usr/local/bin/VoiceActorRadioDownloader/start.ps1 -ConfigurationFilePath "/root/vard_config.json"
# 放送ごとにディレクトリが出来ているはず
ls /var/www/html
```
タイマー設定
``` shell
# タイマー用serviceを作成
sudo vi /etc/systemd/system/VoiceActorRadioDownloader.service
```
``` ini
[Unit]
Description = VoiceActorRadioDownloader

[Service]
Type = oneshot
ExecStart = /usr/bin/pwsh /usr/local/bin/VoiceActorRadioDownloader/start.ps1 -ConfigurationFilePath "/root/vard_config.json"
```
``` shell
# タイマー (毎日09時,12時,15時に実行する。放送ごとに公開時刻が違うので時刻はよしなに調整)
sudo vi /etc/systemd/system/VoiceActorRadioDownloader.timer
```
``` ini
[Unit]
Description = VoiceActorRadioDownloader timer

[Timer]
OnCalendar = *-*-* 09,12,15:00:00

[Install]
WantedBy = timers.target
```

``` shell
# タイマー登録と起動
sudo systemctl daemon-reload
sudo systemctl enable VoiceActorRadioDownloader.timer
sudo systemctl start VoiceActorRadioDownloader.timer

# テストで単発実行してみる
sudo systemctl start VoiceActorRadioDownloader.service
```

## WebGUIがないと不便なのでAutoIndexする
``` shell
sudo vi /etc/nginx/conf.d/80-enable-autoindex.conf
```
``` ini
autoindex on;
```
``` shell
sudo systemctl restart nginx.service
```
* 対象のホストをWebブラウザで開けばファイル一覧が見られる。
* feed.rss をポッドキャストアプリに登録すると便利
