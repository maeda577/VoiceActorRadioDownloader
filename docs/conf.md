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
    "DestinationPath": "/var/www/html",
    "PodcastBaseUrl": "http://localhost/",
    "Ffmpeg": {
        "FfmpegPath": "",
        "FfprobePath": ""
    }
}
```

## パラメータ詳細
### Hibiki.AccessIds
* 響のダウンロードしたい放送の access_id
    * 放送のURLの `https://hibiki-radio.jp/description/<ここの文字列>/detail`
* 複数ある場合はカンマ区切り

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

### DestinationPath
* [必須]ダウンロードしたmp4ファイルの保存先
* 保存先ディレクトリはあらかじめ作成しておく必要あり。無い場合はスクリプトが起動しない。

### PodcastBaseUrl
* ダウンロードしたmp4をpodcastとして配布するサーバのURL。末尾の/は必須
    * サーバが192.168.0.100で動きhttpで配布するならば `http://192.168.0.100/`
    * mDNSでアクセスする場合は `http://podcast01.local/` のような表記も可能
* デフォルト値は `http://localhost/`

### Ffmpeg.FfmpegPath
* ffmpegのフルパス
    * ffmpegのパスが通っているならば指定不要

### Ffmpeg.FfprobePath
* ffprobeのフルパス
    * ffprobeのパスが通っているならば指定不要
