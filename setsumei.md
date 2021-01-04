## これは何
響 -HiBiKi Radio Station- を保存するPowerShellである [CannoHarito/save-hibiki-radio.bat](https://gist.github.com/CannoHarito/75acd6ac09edfa93b54864bdd6b4df3e) を独自に拡張したものです。ラジオを保存しつつPodcast用のXMLを出力するので、iPhoneのPodcastアプリで聴けるようになります。

## おやくそく
* 作成したサーバは外部に公開しないでください

## 必要なもの
* 適当なLinuxサーバ
    * Ubuntu20.04で検証しています。その他のディストリビューションでは不明です
    * PowerShellなのでWindowsServerでも動くと思いますが未検証です
    * どちらも無い場合はラズパイでも買いましょう
* ダウンロードしたい放送の access_id
    * 放送のURLを開き `https://hibiki-radio.jp/description/<ここの文字列>/detail` を調べておいてください
    * 複数指定可能です

## インストール下準備
``` shell
# 諸々のパッケージ入れる
sudo apt update
sudo apt upgrade
sudo apt install git apache2 ffmpeg
sudo apt install avahi-daemon # サーバへhogehoge.localでアクセスしたい場合のみ

# PowerShell入れる
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install powershell
```

## インストールとタイマー起動の設定
``` shell
# スクリプト取得
sudo git clone https://gist.github.com/28b6fa3ea05f811fbd103cb8909af001.git /usr/local/bin/hibiki
# 各パラメータをいい感じに編集
sudo vi /usr/local/bin/hibiki/start.ps1
# 実行してみてエラーが無いことを確認
sudo pwsh /usr/local/bin/hibiki/start.ps1

# タイマー用service
sudo vi /etc/systemd/system/hibiki.service
```
``` ini
[Unit]
Description = HiBiKi downloader

[Service]
Type = oneshot
ExecStart = /usr/bin/pwsh /usr/local/bin/hibiki/start.ps1
```
``` shell
# タイマー (毎日12時に実行する。放送ごとに公開時刻が違うので時刻はよしなに調整)
sudo vi /etc/systemd/system/hibiki.timer
```
``` ini
[Unit]
Description = HiBiKi downloader timer

[Timer]
OnCalendar = *-*-* 12:00:00

[Install]
WantedBy = multi-user.target
```
``` shell
# タイマー登録
sudo systemctl enable hibiki.timer

# テストで単発実行してみる (数分かかる)
sudo systemctl start hibiki.service
# access_idごとにディレクトリが出来ているはず
ls /var/www/html
```

## Podcastアプリからの購読
* 各ディレクトリにfeed.rssが出来ているので、そこへのURLを指定してあげてください
    * `http://<ip_address or hostname>/<access_id>/feed.rss`
    * 例: `http://podcast01.local/llss/feed.rss`
