$access_ids = @("assaultlily", "llss", "llniji", "anigasaki")
$output_dir = "/var/www/html/"
$base_url = "http://podcast01.local/"
#$ffmpeg = "/path/to/ffmpeg"
#$ffprobe = "/path/to/ffprobe"

. $PSScriptRoot/save-hibiki-radio.ps1
. $PSScriptRoot/update-hibiki-radio-feed.ps1

$access_ids | save-hibiki-radio
$access_ids | update-hibiki-radio-feed
