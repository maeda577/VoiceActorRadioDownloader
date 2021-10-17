## これは何
響 -HiBiKi Radio Station- を保存するPowerShellである [CannoHarito/save-hibiki-radio.bat](https://gist.github.com/CannoHarito/75acd6ac09edfa93b54864bdd6b4df3e) を独自に拡張したものです。ラジオを保存しつつPodcast用のXMLを出力するので、別途Webサーバを立てることで各種Podcastアプリでも聴けるようになります。

## おやくそく
* 作成したサーバは外部に公開しないでください

## 対応サービス
* [響 - HiBiKi Radio Station -](https://hibiki-radio.jp)
* [インターネットラジオステーション＜音泉＞](https://www.onsen.ag)
    * v0.3からPREMIUMに対応しました
    * アカウントはメールアドレスで作成してください。ソーシャルアカウント経由のOAuthには対応しません。
* [Radiko](https://radiko.jp/)
    * タイムフリーのみ対応です。ライブ放送は非対応です。
    * エリアフリーは非対応です。
* [RadioTalk](https://radiotalk.jp/)
    * 放送によっては既にPodcastとして公開されているものがあります。公開済みの場合はそちらを参照してください。

## 必要なもの
* PowerShellが動作する環境。以下で検証しています
    * Ubuntu20.04 + PowerShell Core 7.1
    * Windows10 + PowerShell 5.1
* 響のダウンロードしたい放送の access_id
    * 放送のURLを開き `https://hibiki-radio.jp/description/<ここの文字列>/detail` を調べておいてください
    * 複数指定可能です
* 音泉のダウンロードしたい放送の directory_name
    * 放送のURLを開き `https://www.onsen.ag/program/<ここの文字列>` を調べておいてください
    * 複数指定可能です
    * 響のaccess_idと音泉のdirectory_nameで同じものを指定すると多分うまく動きません
        * 例：llssを両方で指定すると、同じディレクトリに2つの配信サイトのmp4が保存されrssがよく分からない感じになります
* Radikoのダウンロードしたい放送の放送局station_idとタイトル
    * 放送のURLを開き `https://radiko.jp/#!/ts/<ここの文字列>/20210516223000` がstation_idです
    * 合わせて放送タイトルが必要なので同じURLから確認してください。ワイルドカードでの指定も可能です
    * 複数指定可能です
* RadioTalkのダウンロードしたい放送の program_id
    * 放送のURLを開き `https://radiotalk.jp/program/<ここの文字列>` を調べておいてください
    * 複数指定可能です

## インストール方法
* [Ubuntu 20.04 向け手順](./docs/setup_ubuntu.md)
* [Windows10 向け手順](./docs/setup_windows.md)
* [Docker 向け手順](./docs/setup_docker.md)

## 設定ファイルの作成
[設定ファイルサンプル](./docs/conf.md)を元にうまいこと設定してください。

## Podcastアプリからの購読
* 各ディレクトリにfeed.rssが出来ているので、そこへのURLを指定してあげてください
    * `http://<ip_address or hostname>/<access_id or directory_name>/feed.rss`
    * 例: `http://podcast01.local/llss/feed.rss`

## アップデート方法
スクリプトの保存先でgit checkoutしてください
``` shell
cd /usr/local/bin/VoiceActorRadioDownloader
sudo git fetch
sudo git checkout refs/tags/v0.5
```
