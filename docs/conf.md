# 設定ファイル詳細

以下サンプルを参照しjsonで作成してください。

``` jsonc
// configサンプル
// コメントは例示のためです。WindowsのPowerShell 5系ではコメントを使用できません。
// 実際のconfigファイルでは全てのコメントを削除してください。
// PowerShell Coreではコメントありでも問題ありません。
{
    // 響用の設定。不要な場合はHibiki以下を丸ごと削除
    "Hibiki": {
        // ダウンロードしたい放送の https://hibiki-radio.jp/description/<ここの文字列>/detail
        // カンマ区切り
        "AccessIds": [
            "llss",
            "llniji"
        ]
    },
    // 音泉用の設定。不要な場合はOnsen以下を丸ごと削除
    "Onsen": {
        // ダウンロードしたい放送の https://www.onsen.ag/program/<ここの文字列>
        // カンマ区切り
        "DirectoryNames": [
            "survey"
        ],
        // 音泉PREMIUMのID/Password情報。プレミアム未契約の場合は空文字のままでOK
        "Email": "",
        "Password": ""
    },
    // Radiko用の設定。不要な場合はRadiko以下を丸ごと削除
    "Radiko": {
        // 放送情報の配列
        "Programs": [
            {
                // 放送局。ダウンロードしたい放送の https://radiko.jp/#!/ts/<ここの文字列>/20210516223000
                "StationId": "QRR",
                // タイトル。この指定を元にダウンロードする放送を決定するため、放送情報のURLを見てコピペを推奨
                // 完全一致なので部分一致で引っ掛ける場合は両端にアスタリスクをつける
                "MatchTitle": "*FUN'S PROJECT LAB*",
                // ローカルに保存する時のサブディレクトリ名。なんでもいい
                "LocalDirectoryName": "fpl"
            },
            {
                "StationId": "LFR",
                "MatchTitle": "オードリーのオールナイトニッポン",
                "LocalDirectoryName": "ann_kw"
            }
        ]
    },
    // RadioTalk用の設定。不要な場合はRadioTalk以下を丸ごと削除
    "RadioTalk": {
        // ダウンロードしたい放送の https://radiotalk.jp/program/<ここの文字列>
        // カンマ区切り
        "ProgramIds": [
            "82485"
        ]
    },
    // 保存先フォルダ名。事前に作成しておく必要あり
    "DestinationPath": "/var/www/html",
    // 実行環境がWindowsの場合、以下のようにエスケープしながら指定
    // "DestinationPath": "C:\\Inetpub\\wwwroot\\"
    // Dockerで実行する場合は以下の通り
    // "DestinationPath": "/vard/data",

    // Podcastを配信するWebサーバのルートURL
    "PodcastBaseUrl": "http://localhost:8080/",
    // ffmpegとffprobeのパス。どちらもPATHが通っていれば空文字のままでOK
    "Ffmpeg": {
        "FfmpegPath": "",
        "FfprobePath": ""
    }
}
```
