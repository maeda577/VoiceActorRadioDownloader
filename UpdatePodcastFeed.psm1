Import-Module -Force $PSScriptRoot/SaveHibikiRadio.psm1
Import-Module -Force $PSScriptRoot/SaveOnsenRadio.psm1

$feed_name = "feed.rss"

function Update-HibikiRadioFeed {
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline = $true)]
        [String]
        $HibikiAccessId,

        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [String]
        $DestinationPath,

        [Parameter()]
        [String]
        $PodcastBaseUrl = "http://localhost/",
    
        [Parameter()]
        [String]
        $FfprobePath = "ffprobe"
    )
    process {
        # 出力ディレクトリ
        $output_sub_dir = Join-Path -Path $DestinationPath -ChildPath $HibikiAccessId

        # 放送の詳細情報を取得
        $program = Get-HibikiProgram -HibikiAccessId $HibikiAccessId

        # 画像が無ければ取得する
        $image_path = Join-Path -Path $output_sub_dir -ChildPath 'image.jpg'
        if (!(Test-Path $image_path)) {
            Invoke-WebRequest -Uri $program.pc_image_url -OutFile $image_path  > $null
        }

        # Podcast用feedを組み立てる
        $feed = [xml](Get-Content "$PSScriptRoot/template.xml")
        $feed.rss.channel.title = $program.episode.program_name
        $feed.rss.channel.description = $program.description.Trim()
        $feed.rss.channel.link = "https://hibiki-radio.jp/description/$HibikiAccessId/detail"
        $feed.rss.channel.copyright = $program.copyright
        $image_attribute = $feed.CreateAttribute('href')
        $image_attribute.Value = $PodcastBaseUrl + $HibikiAccessId + '/image.jpg'
        $feed.rss.channel.image.Attributes.Append($image_attribute)

        # 各放送ごとに作るelementのテンプレを取得しclone用に取っておく
        $itemNodeTemplate = $feed.rss.channel.item
        $feed.rss.channel.RemoveChild($itemNodeTemplate)

        # 各mp4ごとにitemを作って足していく
        $items = Get-ChildItem -Path $output_sub_dir -Filter '*.mp4' | Sort-Object -Property Name -Descending
        foreach ($item in $items) {
            $itemNode = $itemNodeTemplate.Clone()

            Set-PodcastItem -AudioFileInfo $item -ItemNode $itemNode -PodcastItemDirUrl ($PodcastBaseUrl + $HibikiAccessId) -FfprobePath $FfprobePath > $null

            $feed.rss.channel.AppendChild($itemNode)
        }

        # Podcast用feedを保存
        $feed_path = Join-Path -Path $output_sub_dir -ChildPath $feed_name
        $feed.Save($feed_path)
    }
}

function Update-OnsenRadioFeed {
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline = $true)]
        [String]
        $OnsenDirectoryName,

        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [String]
        $DestinationPath,

        [Parameter()]
        [String]
        $PodcastBaseUrl = "http://localhost/",
    
        [Parameter()]
        [String]
        $FfprobePath = "ffprobe"
    )
    process {
        # 出力ディレクトリ
        $output_sub_dir = Join-Path -Path $DestinationPath -ChildPath $OnsenDirectoryName

        # 放送の詳細情報を取得
        $program = Get-OnsenProgram -OnsenDirectoryName $OnsenDirectoryName

        # 画像が無ければ取得する
        $image_path = Join-Path -Path $output_sub_dir -ChildPath 'image.jpg'
        if (!(Test-Path $image_path)) {
            Invoke-WebRequest -Uri $program.program_info.image.url -OutFile $image_path  > $null
        }

        # Podcast用feedを組み立てる
        $feed = [xml](Get-Content "$PSScriptRoot/template.xml")
        $feed.rss.channel.title = $program.program_info.title
        $feed.rss.channel.description = $program.program_info.description
        $feed.rss.channel.link = "https://www.onsen.ag/program/$OnsenDirectoryName"
        $feed.rss.channel.copyright = $program.program_info.copyright
        $image_attribute = $feed.CreateAttribute('href')
        $image_attribute.Value = $PodcastBaseUrl + $OnsenDirectoryName + '/image.jpg'
        $feed.rss.channel.image.Attributes.Append($image_attribute)

        # 各放送ごとに作るelementのテンプレを取得しclone用に取っておく
        $itemNodeTemplate = $feed.rss.channel.item
        $feed.rss.channel.RemoveChild($itemNodeTemplate)

        # 各mp4ごとにitemを作って足していく
        $items = Get-ChildItem -Path $output_sub_dir -Filter '*.mp4' | Sort-Object -Property Name -Descending
        foreach ($item in $items) {
            $itemNode = $itemNodeTemplate.Clone()

            Set-PodcastItem -AudioFileInfo $item -ItemNode $itemNode -PodcastItemDirUrl ($PodcastBaseUrl + $OnsenDirectoryName) -FfprobePath $FfprobePath > $null

            $feed.rss.channel.AppendChild($itemNode)
        }

        # Podcast用feedを保存
        $feed_path = Join-Path -Path $output_sub_dir -ChildPath $feed_name
        $feed.Save($feed_path)
    }
}

function Set-PodcastItem {
    Param(
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]
        $AudioFileInfo,

        [Parameter(Mandatory=$true)]
        [System.Xml.XmlElement]
        $ItemNode,

        [Parameter()]
        [String]
        $PodcastItemDirUrl,
    
        [Parameter()]
        [String]
        $FfprobePath = "ffprobe"
    )
    process {
        # ffprobeでタグを読み取る
        $tmpFile = New-TemporaryFile
        $ffprobe_arg = @('-print_format', 'json', '-v', 'error', '-show_format', '-show_streams', "`"$($item.FullName)`"")
        Start-Process -FilePath $FfprobePath -ArgumentList $ffprobe_arg -RedirectStandardOutput $tmpFile.FullName -Wait > $null
        $metadata = Get-Content -Path $tmpFile.FullName | ConvertFrom-Json
        Remove-Item -Path $tmpFile.FullName > $null

        # テンプレを埋めていく
        $itemNode.title = $metadata.format.tags.title
        $itemNode.episode = $metadata.format.tags.track
        $itemNode.description = $metadata.format.tags.comment

        # 日付があれば入れる
        if ($metadata.format.tags.creation_time) {
            $date = [System.DateTimeOffset]::Parse($metadata.format.tags.creation_time)
            $itemNode.pubDate = $date.ToString('R')
        }

        # enclosureの属性も埋める
        $length_attribute = $feed.CreateAttribute('length')
        $length_attribute.Value = $metadata.format.size
        $itemNode.enclosure.Attributes.Append($length_attribute)
        $url_attribute = $feed.CreateAttribute('url')
        $url_attribute.Value = $PodcastItemDirUrl + '/' + [System.Web.HttpUtility]::UrlEncode($item.Name)
        $itemNode.enclosure.Attributes.Append($url_attribute)

        # 映像があるか
        $video_streams = $metadata.streams | Where-Object -Property codec_type -EQ "video"
        $type_atrribute = $feed.CreateAttribute('type')
        if ($video_streams) {
            $type_atrribute.Value = "video/x-m4v"
        }
        else {
            $type_atrribute.Value = "audio/x-m4a"
        }
        $itemNode.enclosure.Attributes.Append($type_atrribute)

        return $itemNode
    }
}