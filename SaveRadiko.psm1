$headersAuth1 = @{
    'X-Radiko-App'         = 'pc_html5';
    'X-Radiko-App-Version' = '0.0.1';
    'X-Radiko-User'        = 'dummy_user';
    'X-Radiko-Device'      = 'pc';
}

$urlAuth1 = "https://radiko.jp/v2/api/auth1"
$urlAuth2 = "https://radiko.jp/v2/api/auth2"

$authKey = "bcd151073c03b352e1ef2fd66c32209da9ca0afa"

$trimStr = "`0`r`n ".ToCharArray()

$cultureJp = [System.Globalization.CultureInfo]::GetCultureInfo("ja-jp")

if ($PSVersionTable.PSEdition -eq "Core") {
    $httpClient = New-Object System.Net.Http.HttpClient
}

function Invoke-RadikoRequest {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $url
    )
    process {
        # PowerShell Coreだと巨大なXMLの場合Invoke-WebRequestが動かなかった
        if ($PSVersionTable.PSEdition -eq "Core") {
            return $httpClient.GetStringAsync($url).Result
        }
        else {
            $res = Invoke-WebRequest -Method Get -Uri $url -UseBasicParsing
            return [System.Text.Encoding]::UTF8.GetString($res.RawContentStream.GetBuffer()).Trim($trimStr)
        }
    }
}

function Connect-Radiko {
    Param(
        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $Session
    )
    process {
        # 認証1段目、authTokenを取得する
        $res1 = Invoke-WebRequest -Method Get -Uri $urlAuth1 -Headers $headersAuth1 -WebSession $Session -UseBasicParsing

        $authToken = $res1.Headers["X-Radiko-AuthToken"] | Select-Object -First 1
        $keyOffset = [int]::Parse($res1.Headers["X-Radiko-KeyOffset"])
        $keyLength = [int]::Parse($res1.Headers["X-Radiko-KeyLength"])

        $authSubStr = $authKey.Substring($keyOffset, $keyLength)
        $byteArray = [System.Text.Encoding]::UTF8.GetBytes($authSubStr)
        $base64Str = [System.Convert]::ToBase64String($byteArray)

        $headersAuth2 = @{
            'X-Radiko-AuthToken'  = $authToken;
            'X-Radiko-PartialKey' = $base64Str;
            'X-Radiko-User'       = 'dummy_user';
            'X-Radiko-Device'     = 'pc';
        }

        # 認証2段目、これでauthTokenが有効になる
        $res2 = Invoke-WebRequest -Method Get -Uri $urlAuth2 -Headers $headersAuth2 -WebSession $Session -UseBasicParsing
        # ContentはISO-8859-1になっていて文字化けするので自前でUTF8にする
        $contentStr = [System.Text.Encoding]::UTF8.GetString($res2.RawContentStream.GetBuffer()).Trim($trimStr)

        Write-Information -MessageData "Current Radiko area is: $contentStr" -InformationAction Continue

        # 現在のエリアで視聴できる放送局
        $areaId = $contentStr -split ',' | Select-Object -First 1
        $stationUrl = "http://radiko.jp/v3/station/list/$areaId.xml"
        $stationXml = [xml](Invoke-RadikoRequest($stationUrl))

        $stationIds = $stationXml.stations.station | Select-Object -ExpandProperty id

        return [PSCustomObject]@{
            AuthToken  = $authToken;
            AreaId     = $areaId;
            StationIds = $stationIds;
        }
    }
}

function Save-Radiko {
    Param(
        [Parameter(Mandatory = $true)]
        [String]
        $AuthToken,

        [Parameter(Mandatory = $true)]
        [String]
        $StationId,

        [Parameter(Mandatory = $true)]
        [String]
        $MatchTitle,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [String]
        $DestinationPath,

        [Parameter(Mandatory = $true)]
        [String]
        $DestinationSubDir,

        [Parameter()]
        [String]
        $FfmpegPath = "ffmpeg",

        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $Session
    )
    process {
        # サブディレクトリを切る
        $output_sub_dir = Join-Path -Path $destinationPath -ChildPath $DestinationSubDir
        if ((Test-Path $output_sub_dir) -eq $false) {
            New-Item -Path $output_sub_dir -ItemType "Directory" > $null
        }

        # 番組表の取得
        $programUrl = "https://radiko.jp/v3/program/station/weekly/$StationId.xml"
        $programXml = [xml](Invoke-RadikoRequest($programUrl))

        $dateNowStr = (Get-Date).ToString("yyyyMMddHHmmss")

        $targetPrograms = $programXml.radiko.stations.station.progs |
        Select-Object -ExpandProperty prog | #放送情報が日付別に入っているのを全部フラットにする
        Where-Object -Property title -Like $MatchTitle | # タイトルで絞り込み
        Where-Object -Property to -lt $dateNowStr # 放送が終わっているもの

        foreach ($targetProgram in $targetPrograms) {
            # 開始時間
            $startTime = [System.DateTimeOffset]::ParseExact($targetProgram.ft, "yyyyMMddHHmmss", $cultureJp)

            # ファイル名(拡張子なし)
            $fileName = "$DestinationSubDir-$($targetProgram.ft)"
            # 画像のダウンロード
            if ($targetProgram.img) {
                $extension = [IO.Path]::GetExtension($targetProgram.img)
                
                $imageFullPath = Join-Path -Path $output_sub_dir -ChildPath ($fileName + $extension)
                if ((Test-Path -Path $imageFullPath) -eq $false) {
                    Invoke-WebRequest -Method Get -Uri $targetProgram.img -OutFile $imageFullPath -UseBasicParsing > $null
                }
            }

            # m3u8ファイルのURL
            $m3u8Url = "https://radiko.jp/v2/api/ts/playlist.m3u8?station_id=$StationId&l=15&ft=$($targetProgram.ft)&to=$($targetProgram.to)"

            # 出力ファイルのフルパス
            $fileFullPath = Join-Path -Path $output_sub_dir -ChildPath ($fileName + ".m4a")

            # ffmpegの引数
            $ffmepg_arg = @(
                "-headers", "`"X-Radiko-AuthToken: $AuthToken`"",
                "-i", $m3u8Url, #input file url
                "-loglevel", "error", #Show all errors, including ones which can be recovered from.
                "-acodec", "copy", #Set the audio codec.
                "-bsf:a" , "aac_adtstoasc", #Set bitstream filters for matching streams.
                "-vn", #As an input option, blocks all video streams of a file from being filtered or being automatically selected or mapped for any output.
                "-metadata", "artist=`"$($targetProgram.pfm)`"",
                "-metadata", "album=`"$($targetProgram.title)`"",
                "-metadata", "genre=`"Web Radio`"",
                "-metadata", "date=`"$($startTime.Year)`"",
                "-metadata", "creation_time=`"$($startTime.ToString('u'))`"",
                "-metadata", "description=`"$($targetProgram.info)`"",
                "-metadata", "comment=`"$($targetProgram.desc)`"",
                "-metadata", "title=`"$($targetProgram.title)`"", # タイトル
                "`"$fileFullPath`""   # 出力ファイルのフルパス
            )

            # ダウンロード実行
            if ((Test-Path -Path $fileFullPath) -eq $false) {
                Start-Process -FilePath $ffmpegPath -ArgumentList $ffmepg_arg -Wait
            }
        }

        # ダウンロードがコケて0byteのデータが残っていたら消す
        Get-ChildItem -Path $output_sub_dir -File | Where-Object { $_.Length -eq 0 } | Remove-Item

        # 放送情報をファイルに書き出す
        $targetPrograms | Select-Object -Last 1 | Update-RadikoProgramInfo -EpisodeDestinationPath $output_sub_dir
    }
}

function Update-RadikoProgramInfo {
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]
        $Program,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [String]
        $EpisodeDestinationPath
    )
    process {
        # カバー画像のファイル名
        $imageFileName = [IO.Path]::GetFileName($Program.img)

        # カバー画像がなければダウンロード
        $imageFullPath = Join-Path -Path $EpisodeDestinationPath -ChildPath $imageFileName
        if ((Test-Path $imageFullPath) -eq $false) {
            Invoke-WebRequest -Uri $Program.img -OutFile $imageFullPath > $null
        }

        $infoFullPath = Join-Path -Path $EpisodeDestinationPath -ChildPath "info.json"

        @{
            "title" = $Program.title;
            "description" = $Program.info;
            "image" = $imageFileName;
            "link" = $Program.url;
        } | ConvertTo-Json | Out-File -FilePath $infoFullPath -Encoding UTF8
    }
}
