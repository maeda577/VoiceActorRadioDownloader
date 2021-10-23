# インストール方法(Docker)

DockerとDockerCompose導入済の環境での実行方法です。Ubuntu20.04で検証しています。

## コンテナ構築
* コンテナ内にffmpegをインストールするため、`dokcer-compose up --no-start`でそれなりの時間がかかります
* conf.jsoncの中身は[設定ファイル詳細](./conf.md)を参照してください

``` shell
# 作業ディレクトリ作成
# ディレクトリ名を変える場合はdocker-compose.ymlも修正
mkdir ~/vard
cd ~/vard

# docker-compose.ymlをダウンロードし、必要に応じて中身を修正
wget https://raw.githubusercontent.com/maeda577/VoiceActorRadioDownloader/main/docker/docker-compose.yml
vi ./docker-compose.yml

# コンフィグ作成
# コンフィグ名を変える場合はdocker-compose.ymlも修正
vi ~/vard/conf.jsonc

# コンテナ起動
sudo docker-compose up --detach
```

* http://<DockerホストのIPアドレス>:8080/ へアクセスしindexが見られることを確認
* 翌日もう一回見てPodcastが出来ている事を確認
    * なにかおかしい場合は`docker exec -it VoiceActorRadioDownloader bash`で中身を見る

## バージョンアップ

``` shell
# 作業ディレクトリへ移動
cd ~/vard

# イメージの再ビルド
sudo docker-compose build --pull vard
# apacheを更新する場合はpull
sudo docker-compose pull httpd

# コンテナ再作成
sudo dokcer-compose down
sudo dokcer-compose up --detach
```
