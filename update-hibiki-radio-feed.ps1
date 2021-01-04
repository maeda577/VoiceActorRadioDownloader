
############################################################################
$DEFO_access_ids = @"
ccsakura
Roselia
"@ -split "\s+"
$DEFO_output_dir = "$HOME\Music\records\"
$DEFO_ffprobe = "C:\Program_Free\ffmpeg\bin\ffprobe.exe"#pathが通っているなら書く必要はない
$DEFO_base_url = "http://localhost/"

Add-Type -AssemblyName System.Web
############################################################################
if (!$access_ids) {
    $access_ids = $DEFO_access_ids
}
if (!$ffprobe) {
    if (!!(Get-Command ffprobe 2>$null)) {
        $ffprobe = (Get-Command ffprobe).Definition
    }
    else {
        $ffprobe = $DEFO_ffprobe
    }
}
if (!$output_dir) {
    $output_dir = $DEFO_output_dir
}
if (!$base_url) {
    $base_url = $DEFO_base_url
}

function update-hibiki-radio-feed {
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $access_id = 'ccsakura'
    )
    process {
        $output_sub_dir = Join-Path -Path $output_dir -ChildPath $access_id
        $feed = [xml](Get-Content "$PSScriptRoot/template.xml")

        $program = get-program-detail $access_id

        $image_path = Join-Path -Path $output_sub_dir -ChildPath 'image.jpg'
        if (!(Test-Path $image_path)) {
            Invoke-WebRequest -Uri $program.pc_image_url -OutFile $image_path
        }

        $feed.rss.channel.title = $program.episode.program_name
        $feed.rss.channel.description = $program.description -replace '\s+',' '
        $feed.rss.channel.link = "https://hibiki-radio.jp/description/$access_id/detail"
        $image_attribute = $feed.CreateAttribute('href')
        $image_attribute.Value = $base_url + $access_id + '/image.jpg'
        $feed.rss.channel.image.Attributes.Append($image_attribute)

        $itemNodeTemplate = $feed.rss.channel.item
        $feed.rss.channel.RemoveChild($itemNodeTemplate)

        $items = Get-ChildItem -Path $output_sub_dir -Filter '*.m4a'
        foreach ($item in $items) {
            $tmpFile = New-TemporaryFile
            $ffprobe_arg = @('-print_format', 'json', '-v', 'error', '-show_format', "`"$($item.FullName)`"")
            Start-Process -FilePath $ffprobe -ArgumentList $ffprobe_arg -RedirectStandardOutput $tmpFile.FullName -Wait
            $metadata = Get-Content -Path $tmpFile.FullName | ConvertFrom-Json
            Remove-Item -Path $tmpFile.FullName

            $date = [System.DateTimeOffset]::Parse($metadata.format.tags.comment)

            $itemNode = $itemNodeTemplate.Clone()
            $itemNode.title = '#' + $metadata.format.tags.track + ' ' + $date.ToString("yyyyMMdd")
            $itemNode.pubDate = $metadata.format.tags.comment
            $itemNode.episode = $metadata.format.tags.track

            $length_attribute = $feed.CreateAttribute('length')
            $length_attribute.Value = $metadata.format.size
            $itemNode.enclosure.Attributes.Append($length_attribute)
            $url_attribute = $feed.CreateAttribute('url')
            $url_attribute.Value = $base_url + $access_id + '/' + [System.Web.HttpUtility]::UrlEncode($item.Name)
            $itemNode.enclosure.Attributes.Append($url_attribute)

            $feed.rss.channel.AppendChild($itemNode)
        }

        $feed_path = Join-Path -Path $output_sub_dir -ChildPath 'feed.rss'
        $feed.Save($feed_path)
    }
}
