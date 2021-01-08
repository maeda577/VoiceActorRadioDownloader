$useragent = 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)'
$headers = @{
    'X-Requested-With' = 'XMLHttpRequest';
    'Origin'           = 'https://hibiki-radio.jp'
}
$bonus_part_name = '楽屋裏'
$feed_name = 'feed.rss'

function Get-HibikiProgram {
    Param(
        [Parameter(mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $HibikiAccessId
    )
    process {
        $url = "https://vcms-api.hibiki-radio.jp/api/v1/programs/$HibikiAccessId"
        return Invoke-RestMethod -Method Get -Uri $url -UserAgent $useragent -Headers $headers
    }
}

function Get-PlaylistUrl {
    Param(
        [Parameter(mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $VideoId
    )
    process {
        $url = "https://vcms-api.hibiki-radio.jp/api/v1/videos/play_check?video_id=$VideoId"
        (Invoke-RestMethod -Method Get -Uri $url -UserAgent $useragent -Headers $headers).playlist_url
    }
}
function Save-HibikiRadio {
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
        $FfmpegPath = "ffmpeg"
    )
    process {
        # 放送の詳細情報を取得
        $program = Get-HibikiProgram -HibikiAccessId $HibikiAccessId
        if (!$program.episode.video.id) {
            Write-Error "No episodes in $HibikiAccessId"
            return
        }

        # サブディレクトリを切る
        $output_sub_dir = Join-Path -Path $destinationPath -ChildPath $HibikiAccessId
        if (!(Test-Path $output_sub_dir)) {
            New-Item -Path $output_sub_dir -ItemType "Directory"
        }

        # ffmpegの引数(共通部)を作る
        $date = [System.DateTimeOffset]::Parse($program.episode.updated_at + " +0900")
        $track = (Select-String -InputObject $program.episode.name -Pattern "[0-9]+").Matches[0].Value

        $ffmepg_arg_base = @(
            "-n",                       #Do not overwrite output files, and exit immediately if a specified output file already exists.
            "-loglevel", "error",       #Show all errors, including ones which can be recovered from.
            "-acodec", "copy",          #Set the audio codec.
            "-bsf:a" , "aac_adtstoasc", #Set bitstream filters for matching streams.
            "-vn",                      #As an input option, blocks all video streams of a file from being filtered or being automatically selected or mapped for any output.
            "-metadata", "artist=`"$($program.cast)`"",
            "-metadata", "album=`"$($program.episode.program_name)`"",
            "-metadata", "track=`"$track`"",
            "-metadata", "genre=`"Web Radio`"",
            "-metadata", "date=`"$($date.Year)`"",
            "-metadata", "creation_time=`"$($date.ToString('u'))`"",
            "-metadata", "description=`"$($program.description.Trim())`"",
            "-metadata", "comment=`"$($program.episode.episode_parts[0].description.Trim())`"",
            "-metadata", "copyright=`"$($program.copyright)`""
        )

        # ffmpegの引数(本編)を作る
        $filename = "$HibikiAccessId-$($date.ToString("yyyyMMdd"))-$($program.episode.video.id).m4a"
        $ffmepg_arg_input = @(
            "-i", "`"$(Get-PlaylistUrl $program.episode.video.id)`""     #input file url
        )
        $ffmepg_arg_output = @(
            "-metadata", "title=`"$($program.episode.program_name) $($program.episode.name)`"", # タイトル
            "`"$(Join-Path -Path $output_sub_dir -ChildPath $filename)`""   # 出力ファイルのフルパス
        )

        # ダウンロード実行
        Start-Process -FilePath $ffmpegPath -ArgumentList ($ffmepg_arg_input + $ffmepg_arg_base + $ffmepg_arg_output) -Wait

        # 楽屋裏パートがあるか
        if (!$program.additional_video_flg) {
            return
        }
 
        # ffmpegの引数(楽屋裏)を作る
        $filename = "$HibikiAccessId-$($date.ToString("yyyyMMdd"))-$($program.episode.additional_video.id).m4a"
        $ffmepg_arg_input = @(
            "-i", "`"$(Get-PlaylistUrl $program.episode.additional_video.id)`""     #input file url
        )
        $ffmepg_arg_output = @(
            "-metadata", "title=`"$($program.episode.program_name) $($program.episode.name) $bonus_part_name`"", # タイトル
            "`"$(Join-Path -Path $output_sub_dir -ChildPath $filename)`""   # 出力ファイルのフルパス
        )

        # ダウンロード実行
        Start-Process -FilePath $ffmpegPath -ArgumentList ($ffmepg_arg_input + $ffmepg_arg_base + $ffmepg_arg_output) -Wait
    }
}

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
            Invoke-WebRequest -Uri $program.pc_image_url -OutFile $image_path
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
        $items = Get-ChildItem -Path $output_sub_dir -Filter '*.m4a'
        foreach ($item in $items) {
            # ffprobeでタグを読み取る
            $tmpFile = New-TemporaryFile
            $ffprobe_arg = @('-print_format', 'json', '-v', 'error', '-show_format', "`"$($item.FullName)`"")
            Start-Process -FilePath $ffprobe -ArgumentList $ffprobe_arg -RedirectStandardOutput $tmpFile.FullName -Wait
            $metadata = Get-Content -Path $tmpFile.FullName | ConvertFrom-Json
            Remove-Item -Path $tmpFile.FullName

            # 日付情報をパースしておく
            $date = [System.DateTimeOffset]::Parse($metadata.format.tags.creation_time)

            # テンプレをcloneしてから埋めていく
            $itemNode = $itemNodeTemplate.Clone()
            $itemNode.title = $metadata.format.tags.title
            $itemNode.pubDate = $date.ToString('R')
            $itemNode.episode = $metadata.format.tags.track
            $itemNode.description = $metadata.format.tags.comment

            # enclosureの属性も埋める
            $length_attribute = $feed.CreateAttribute('length')
            $length_attribute.Value = $metadata.format.size
            $itemNode.enclosure.Attributes.Append($length_attribute)
            $url_attribute = $feed.CreateAttribute('url')
            $url_attribute.Value = $PodcastBaseUrl + $HibikiAccessId + '/' + [System.Web.HttpUtility]::UrlEncode($item.Name)
            $itemNode.enclosure.Attributes.Append($url_attribute)

            $feed.rss.channel.AppendChild($itemNode)
        }

        # Podcast用feedを保存
        $feed_path = Join-Path -Path $output_sub_dir -ChildPath $feed_name
        $feed.Save($feed_path)
    }
}
