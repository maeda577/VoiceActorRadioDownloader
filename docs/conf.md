# 設定ファイル詳細

## サンプル
``` json
{
    "Hibiki": {
        "AccessIds": [ "llss", "llniji" ]
    },
    "Onsen": {
        "DirectoryNames": [ "survey" ],
        "Email": "",
        "Password": ""
    },
    "Radiko": {
        "Programs": [
            {
                "StationId": "QRR",
                "MatchTitle": "*FUN'S PROJECT LAB",
                "LocalDirectoryName": "fpl"
            },
            {
                "StationId": "LFR",
                "MatchTitle": "オードリーのオールナイトニッポン",
                "LocalDirectoryName": "ann_kw"
            }
        ]
    },
    "DestinationPath": "/var/www/html",
    "PodcastBaseUrl": "http://localhost/",
    "Ffmpeg": {
        "FfmpegPath": "",
        "FfprobePath": ""
    }
}
```

## パラメータ詳細(響)
### Hibiki.AccessIds
* 響のダウンロードしたい放送の access_id
    * 放送のURLの `https://hibiki-radio.jp/description/<ここの文字列>/detail`
* 複数ある場合はカンマ区切り

## パラメータ詳細(音泉)
### Onsen.DirectoryNames
* 音泉のダウンロードしたい放送の directory_name
    * 放送のURLの `https://www.onsen.ag/program/<ここの文字列>`
* 複数ある場合はカンマ区切り

### Onsen.Email
* 音泉PREMIUMを契約しているアカウントのEメールアドレス
* 契約していない場合は空欄

### Onsen.Password
* 音泉PREMIUMを契約しているアカウントのパスワード
* 契約していない場合は空欄

## パラメータ詳細(Radikoタイムフリー)
### Radiko.Programs
* 以下放送情報の配列
* 複数ある場合はカンマ区切り(末尾のカンマ、通称ケツカンマをつけないように注意して下さい)

### Radiko放送情報.StationId
* ダウンロードしたい放送の放送局のID
    * 放送のURLの `https://radiko.jp/#!/ts/<ここの文字列>/20210516223000`

### Radiko放送情報.MatchTitle
* ダウンロードしたい放送のタイトル
* 完全一致です。放送のURLを開きコピペしてください。
* ワイルドカードでの指定も可能です。部分一致でひっかけたい場合はアスタリスクを使ってください

### Radiko放送情報.LocalDirectoryName
* ダウンロードした放送を保存するサブディレクトリの名前
* 分かりやすく短い名前を適当につけてください

## パラメータ詳細(共通部)
### DestinationPath
* [必須]ダウンロードしたmp4ファイルの保存先
    * Windowsの場合の例：C:\\Inetpub\\wwwroot\\
    * Linuxの場合の例：/var/www/html/
* 保存先ディレクトリはあらかじめ作成しておく必要があります。無い場合はスクリプトが起動しません。

### PodcastBaseUrl
* ダウンロードしたmp4をpodcastとして配布するサーバのURL
    * サーバが192.168.0.100で動きhttpで配布するならば `http://192.168.0.100/`
    * mDNSでアクセスする場合は `http://podcast01.local/` のような表記も可能です
* デフォルト値は `http://localhost/`

### Ffmpeg.FfmpegPath
* ffmpegへのパス
    * ffmpegのパスが通っているならば指定不要
    * 絶対パスでの指定を推奨。相対パスでも可能

### Ffmpeg.FfprobePath
* ffprobeのへのパス
    * ffprobeのパスが通っているならば指定不要
    * 絶対パスでの指定を推奨。相対パスでも可能
