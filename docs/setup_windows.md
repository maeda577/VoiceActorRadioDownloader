# インストール方法(Windows10)
* OSはWindows10を想定しています。それ以外のOSでは適宜読み替えてください。
* 本手順では放送のダウンロードまでです。podcast配布の部分が必要な場合は適宜IISをインストールしてください。

## スクリプト取得
* バージョンは0.5、作業ディレクトリはデスクトップの前提です
* 以下作業はすべてPowerShellで行ってください
``` powershell
cd ~/Desktop/
# スクリプトをダウンロードして展開
Invoke-WebRequest -Uri https://github.com/maeda577/VoiceActorRadioDownloader/archive/refs/tags/v0.5.zip -UseBasicParsing -OutFile temp.zip
Expand-Archive -Path ./temp.zip -DestinationPath ./
cd ./VoiceActorRadioDownloader-0.5
```

## 設定
* [設定ファイルサンプル](./conf.jsonc)を元にうまいこと設定してください。
``` powershell
# サンプルconfigをコピー
Copy-Item -Path ./config.sample.json -Destination ./config.json
# メモ帳で編集
notepad.exe ./config.json
```

## テスト実行
``` powershell
# スクリプトが実行できないため一時的にExecutionPolicyを落とす(質問はYで応答)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted

# 実行
./start.ps1 -ConfigurationFilePath ./config.json
```

## タスクスケジューラに登録
``` powershell
# 必要なパスをフルパスにする
$ps1FullPath = (Resolve-Path ./start.ps1).Path
$confFullPath = (Resolve-Path ./config.json).Path

# 毎日13時に実行
$trigger = New-ScheduledTaskTrigger -Daily -At 13:00
# 実行するコマンド
$action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-ExecutionPolicy Unrestricted $ps1FullPath -ConfigurationFilePath $confFullPath"
# タスクスケジューラに登録
Register-ScheduledTask -TaskName "VoiceActorRadioDownloader" -Trigger $trigger -Action $action -User $env:UserName -Password "パスワード文字列" -Force

# 1回手動で実行してみる
Start-ScheduledTask -TaskName "VoiceActorRadioDownloader"
```
