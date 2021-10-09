Import-Module -Force -Name $PSScriptRoot/Common.psm1
$cultureJp = [System.Globalization.CultureInfo]::GetCultureInfo("ja-jp")

function Save-RadioTalk {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $ProgramId,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [String]
        $DestinationPath,

        [Parameter()]
        [String]
        $FfmpegPath = "ffmpeg"
    )
    process {
        # サブディレクトリを切る
        $outputSubDir = New-DirectoryIfNotExists -ParentDirectory $DestinationPath -DirectoryName $ProgramId -WhatIf:$WhatIfPreference

        # 番組情報
        $programInfo = Invoke-RestMethod -Method Get -Uri "https://radiotalk.jp/api/programs/$ProgramId/talks"

        # 放送ごとにダウンロード
        foreach ($program in $programInfo) {
            # オーディオファイルのファイル名とフルパス
            $audioFileName = [System.IO.Path]::GetFileName($program.audioFileUrl)
            $audioFileFullPath = Join-Path -Path $outputSubDir.FullName -ChildPath $audioFileName
            # ファイルが無ければダウンロード
            $isAudioDownloaded = Invoke-DownloadItemIfNotExists -Uri $program.audioFileUrl -OutFile $audioFileFullPath -WhatIf:$WhatIfPreference
            # タグ付与
            if ($isAudioDownloaded) {
                # 日付をパース
                $createdAt = [System.DateTimeOffset]::ParseExact($program.createdAt, "yyyy-MM-dd HH:mm:ss", $cultureJp)
                # タグ書き込み後のオーディオファイルを置く一時ファイル
                $tempAudioFileFullPath = Join-Path -Path $outputSubDir.FullName -ChildPath "temp_$audioFileName"
                # ffmpegの引数
                $ffmepgArgs = @(
                    "-i", $audioFileFullPath, #input file url
                    "-loglevel", "error", #Show all errors, including ones which can be recovered from.
                    "-c", "copy",
                    "-metadata", "artist=`"$($program.userName)`"",
                    "-metadata", "album=`"$($program.programTitle)`"",
                    "-metadata", "genre=`"Web Radio`"",
                    "-metadata", "date=`"$($createdAt.Year)`"",
                    "-metadata", "creation_time=`"$($createdAt.ToString('u'))`"",
                    "-metadata", "comment=`"$($program.description)`"",
                    "-metadata", "title=`"$($program.title)`"",
                    "`"$tempAudioFileFullPath`""   # 出力ファイルのフルパス
                )
                if ($PSCmdlet.ShouldProcess($audioFileFullPath, "Update")) {
                    # ffmpeg実行
                    Start-Process -FilePath $ffmpegPath -ArgumentList $ffmepgArgs -Wait
                    # タグ付きファイルを元ファイルに上書きする
                    Move-Item -Path $tempAudioFileFullPath -Destination $audioFileFullPath -Force
                }
            }

            # 画像ファイルのファイル名とフルパス
            $imageFileName = [System.IO.Path]::GetFileNameWithoutExtension($program.audioFileUrl) + [System.IO.Path]::GetExtension($program.imageUrl)
            $imageFileFullPath = Join-Path -Path $outputSubDir.FullName -ChildPath $imageFileName
            # ファイルが無ければダウンロード
            $null = Invoke-DownloadItemIfNotExists -Uri $program.imageUrl -OutFile $imageFileFullPath -WhatIf:$WhatIfPreference
        }

        # 最新話の画像をカバー画像として使う
        $coverImageFileName = [System.IO.Path]::GetFileNameWithoutExtension($programInfo[0].audioFileUrl) + [System.IO.Path]::GetExtension($programInfo[0].imageUrl)

        # 放送情報を保存
        $infoFullPath = Join-Path -Path $outputSubDir.FullName -ChildPath "info.json"
        @{
            "title" = $programInfo[0].programTitle;
            "image" = $coverImageFileName;
            "link" = "https://radiotalk.jp/program/$ProgramId";
        } | ConvertTo-Json | Out-File -FilePath $infoFullPath -Encoding UTF8 -WhatIf:$WhatIfPreference
    }
}
