$feed_name = "feed.rss"

$audioExtensions = @(".m4a", ".mp4")
$imageExtensions = @(".jpg", ".jpeg", ".png", ".webp")

function Update-RadioFeed {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.IO.FileInfo]
        $ProgramInfoJson,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [String]
        $DestinationPath,

        [Parameter()]
        [String]
        $PodcastBaseUrl = "http://localhost/",

        [Parameter()]
        [String]
        $FfprobePath = "ffprobe"
    )
    begin {
        # baseURLをオブジェクト化しておく
        $baseUri = [Uri]::new($PodcastBaseUrl)
    }
    process {
        # カレントディレクトリを出力先のルートに切り替える
        Push-Location $DestinationPath

        # メタ情報jsonを読み取る
        $programInfo = Get-Content -Path $ProgramInfoJson.FullName | ConvertFrom-Json

        # Podcast用feedを組み立てる
        $feed = [xml](Get-Content -Path "$PSScriptRoot/template.xml" -Encoding UTF8)

        # チャンネル情報
        if ($programInfo.title) {
            $feed.rss.channel.title = $programInfo.title
        }
        if ($programInfo.description) {
            $feed.rss.channel.description = $programInfo.description
        }
        if ($programInfo.link) {
            $feed.rss.channel.link = $programInfo.link
        }
        if ($programInfo.copyright) {
            $feed.rss.channel.copyright = $programInfo.copyright
        }

        # チャンネルのカバー画像
        if ($programInfo.image) {
            $imageFullPath = Join-Path -Path $ProgramInfoJson.Directory -ChildPath $programInfo.image
            $imageAttribute = $feed.CreateAttribute('href')
            $imageAttribute.Value = [Uri]::new($baseUri, (Resolve-Path -Path $imageFullPath -Relative)).ToString()
            $feed.rss.channel.image.Attributes.Append($imageAttribute) > $null
        }

        # 各放送ごとに作るelementのテンプレを取得しclone用に取っておく
        $itemNodeTemplate = $feed.rss.channel.item
        $feed.rss.channel.RemoveChild($itemNodeTemplate) > $null

        # 放送ごとの情報
        $items = Get-ChildItem -Path $ProgramInfoJson.Directory | Where-Object -FilterScript { $_.Extension -in $audioExtensions } | Sort-Object -Property Name -Descending
        foreach ($item in $items) {
            # 放送用ノードをclone
            $itemNode = $itemNodeTemplate.Clone()

            # ffprobeでタグを読み取る
            $tmpFile = New-TemporaryFile
            $ffprobe_arg = @('-print_format', 'json', '-v', 'error', '-show_format', '-show_streams', $item.FullName)
            Start-Process -FilePath $FfprobePath -ArgumentList $ffprobe_arg -RedirectStandardOutput $tmpFile.FullName -Wait > $null
            $metadata = Get-Content -Path $tmpFile.FullName -Encoding UTF8 | ConvertFrom-Json
            Remove-Item -Path $tmpFile.FullName > $null

            # テンプレを埋めていく
            if ($metadata.format.tags.title) {
                $itemNode.title = $metadata.format.tags.title
            }
            if ($metadata.format.tags.track) {
                $itemNode.episode = $metadata.format.tags.track
            }
            if ($metadata.format.tags.comment) {
                $itemNode.description = $metadata.format.tags.comment
            }

            # 放送日があればRFC1123形式で入れる
            if ($metadata.format.tags.creation_time) {
                # PowerShell 5.1だと文字列のまま、PowerShell CoreだとDateTimeになっている
                if ($metadata.format.tags.creation_time -is [System.String]) {
                    $itemNode.pubDate = [DateTimeOffset]::Parse($metadata.format.tags.creation_time).ToString("R")
                }
                else {
                    $itemNode.pubDate = $metadata.format.tags.creation_time.ToString("R")
                }
            }

            # 放送ごとのカバー画像
            $itemNameBase = [System.IO.Path]::GetFileNameWithoutExtension($item.Name)
            $itemImage = Get-ChildItem -Path $ProgramInfoJson.Directory -Filter "$itemNameBase*" | Where-Object -FilterScript { $_.Extension -in $imageExtensions } | Select-Object -First 1
            if ($itemImage) {
                $itemImageAttribute = $feed.CreateAttribute('href')
                $itemImageAttribute.Value = [Uri]::new($baseUri, (Resolve-Path -Path $itemImage.FullName -Relative)).ToString()
                $itemNode.image.Attributes.Append($itemImageAttribute) > $null
            }

            # enclosureの属性も埋める
            $length_attribute = $feed.CreateAttribute('length')
            $length_attribute.Value = $metadata.format.size
            $itemNode.enclosure.Attributes.Append($length_attribute) > $null
            $url_attribute = $feed.CreateAttribute('url')
            $url_attribute.Value = [Uri]::new($baseUri, (Resolve-Path -Path $item.FullName -Relative)).ToString()
            $itemNode.enclosure.Attributes.Append($url_attribute) > $null

            # 映像があるか
            $video_streams = $metadata.streams | Where-Object -Property codec_type -EQ "video"
            $type_atrribute = $feed.CreateAttribute('type')
            if ($video_streams) {
                $type_atrribute.Value = "video/x-m4v"
            }
            else {
                $type_atrribute.Value = "audio/x-m4a"
            }
            $itemNode.enclosure.Attributes.Append($type_atrribute) > $null

            # 放送用ノードを追加
            $feed.rss.channel.AppendChild($itemNode) > $null
        }

        # Podcast用feedを保存
        $feedPath = Join-Path -Path $ProgramInfoJson.Directory -ChildPath $feed_name
        $feed.Save($feedPath)

        # カレントディレクトリを戻す
        Pop-Location
    }
}
