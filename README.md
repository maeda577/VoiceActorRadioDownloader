## これは何
響 -HiBiKi Radio Station- を保存するPowerShellである [CannoHarito/save-hibiki-radio.bat](https://gist.github.com/CannoHarito/75acd6ac09edfa93b54864bdd6b4df3e) を独自に拡張したものです。ラジオを保存しつつPodcast用のXMLを出力するので、iPhoneのPodcastアプリで聴けるようになります。ついでに音泉にも対応しています。

## おやくそく
* 作成したサーバは外部に公開しないでください

## 対応サービス
* [響 - HiBiKi Radio Station -](https://hibiki-radio.jp)
* [インターネットラジオステーション＜音泉＞](https://www.onsen.ag)
    * 無料で視聴できるもののみ。PREMIUM限定放送は非対応です。

## 必要なもの
* 適当なLinuxサーバ
    * Ubuntu20.04で検証しています。その他のディストリビューションでは不明です
    * PowerShellなのでWindowsServerでも動くと思いますが未検証です
    * どちらも無い場合はラズパイでも買いましょう
* 響のダウンロードしたい放送の access_id
    * 放送のURLを開き `https://hibiki-radio.jp/description/<ここの文字列>/detail` を調べておいてください
    * 複数指定可能です
* 音泉のダウンロードしたい放送の directory_name
    * 放送のURLを開き `https://www.onsen.ag/program/<ここの文字列>` を調べておいてください
    * 複数指定可能です
    * 響のaccess_idと音泉のdirectory_nameで同じものを指定すると多分うまく動きません
        * 例：llssを両方で指定すると、同じディレクトリに2つの配信サイトのmp4が保存されrssがよく分からない感じになります

## インストール下準備
``` shell
# 諸々のパッケージ入れる
sudo apt update
sudo apt upgrade
sudo apt install git apache2 ffmpeg
sudo apt install avahi-daemon # サーバへhogehoge.localでアクセスしたい場合のみ

# PowerShell入れる(URLはUbuntu20.04のものなので、他のディストリビューションでは適宜変更)
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install powershell

# timezoneとホスト名直す
sudo timedatectl set-timezone Asia/Tokyo
sudo hostnamectl set-hostname podcast01
```

## パラメータの準備
* -HibikiAccessIds
    * 集めておいた響の access_id
        * 複数ある場合はカンマ区切りで指定できます
    * 例： "llss,llniji,anigasaki"
* -OnsenDirectoryNames
    * 集めておいた音泉の directory_name
        * 複数ある場合はカンマ区切りで指定できます
    * 例： "battle,survey"
* -DestinationPath
    * [必須]ラジオの保存先ディレクトリ
        * ディレクトリが存在しない場合は失敗します。Apacheでホストされているディレクトリを指定するとPodcastで聞けます
    * 例： "/var/www/html/"
* -PodcastBaseUrl
    * このスクリプトが動くサーバーへのUrl
        * rssに書かれるため、誤った値を入れるとpodcast経由で聴くときに失敗します
    * 例： "http://podcast01.local/"
* -FfmpegPath
    * ffmpegへのフルパス
        * 既にPathが通っているなら指定不要です
* -FfprobePath
    * ffprobeへのフルパス
        * 既にPathが通っているなら指定不要です

## インストールとタイマー起動の設定
``` shell
# スクリプト取得
sudo git clone https://github.com/maeda577/VoiceActorRadioDownloader.git /usr/local/bin/VoiceActorRadioDownloader/
cd /usr/local/bin/VoiceActorRadioDownloader/
git pull origin v0.2
# 準備したパラメータで実行してみてエラーが無いことを確認 (ダウンロード完了まで数分かかる)
sudo pwsh /usr/local/bin/VoiceActorRadioDownloader/start.ps1 -HibikiAccessIds "llss,llniji,anigasaki" -OnsenDirectoryNames "battle,survey" -DestinationPath "/var/www/html/" -PodcastBaseUrl "http://podcast01.local/"

# タイマー用serviceを作成
sudo vi /etc/systemd/system/VoiceActorRadioDownloader.service
```
``` ini
[Unit]
Description = VoiceActorRadioDownloader

[Service]
Type = oneshot
ExecStart = /usr/bin/pwsh /usr/local/bin/VoiceActorRadioDownloader/start.ps1 -HibikiAccessIds "llss,llniji,anigasaki" -OnsenDirectoryNames "battle,survey" -DestinationPath "/var/www/html/" -PodcastBaseUrl "http://podcast01.local/"
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
WantedBy = multi-user.target
```
``` shell
# タイマー登録と起動
sudo systemctl daemon-reload
sudo systemctl enable VoiceActorRadioDownloader.timer
sudo systemctl start VoiceActorRadioDownloader.timer

# テストで単発実行してみる
sudo systemctl start VoiceActorRadioDownloader.service
# 放送ごとにディレクトリが出来ているはず
ls /var/www/html
```

## Podcastアプリからの購読
* 各ディレクトリにfeed.rssが出来ているので、そこへのURLを指定してあげてください
    * `http://<ip_address or hostname>/<access_id>/feed.rss`
    * 例: `http://podcast01.local/llss/feed.rss`

## アップデート方法
スクリプトの保存先でgit pullしてください
``` shell
cd /usr/local/bin/VoiceActorRadioDownloader
sudo git pull origin v0.2
```

## ダウンロード対象の追加
serviceファイルを編集してdaemon-reloadしてください
``` shell
sudo vi /etc/systemd/system/VoiceActorRadioDownloader.service
sudo systemctl daemon-reload
```
