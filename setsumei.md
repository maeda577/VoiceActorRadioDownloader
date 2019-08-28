## とりあえず実行
`Windows`キーに続いて`powershell`と打ち込んでpowershellを起動

ffmpeg<a href="#1">\*1</a>のパスが通ってないなら、
```powershell
$ffmpeg='C:\Program Files\...\ffmpeg.exe'
```
などとする。通っているなら何もしない。

そして、以下の一行を実行
```powershell
(Invoke-WebRequest https://gist.githubusercontent.com/CannoHarito/75acd6ac09edfa93b54864bdd6b4df3e/raw/save-hibiki-radio.ps1).Content|Invoke-Expression
```
`~/Music/records/`フォルダに録音されたm4aファイルが並んでいるはず。

自分の好きなラジオ番組を保存したいなら
```powershell
$access_ids=@('poppin-radio','hanaso','gfonpu')
(Invoke-WebRequest https://gist.githubusercontent.com/CannoHarito/75acd6ac09edfa93b54864bdd6b4df3e/raw/save-hibiki-radio.ps1).Content|Invoke-Expression
```
とかすればいいと思う。

## ダブルクリックで実行したい
毎週実行するなら、ダブルクリックで実行したい。
文字コードやセキュリティ設定の関係でダウンロードしたbatファイルには一手間必要。

`Windows`キーに続いて`notepad`と打ち込んでメモ帳を起動。

ブラウザでbatファイルの[Raw](https://gist.githubusercontent.com/CannoHarito/75acd6ac09edfa93b54864bdd6b4df3e/raw/save-hibiki-radio.bat)を表示し、`Ctrl+A`、`Ctrl+C`。

メモ帳に`Ctrl+V`して`Ctrl+S`で文字コードが`ANSI`になっていること確認して`ラジオ録音.bat`などと保存。

これをダブルクリックで実行できる。batファイル上部の`###`に挟まれた部分にある`$DEFO_xxx`への代入を好きなように書き換えよう。


## access_idの例
```powershell
$res=Invoke-RestMethod https://vcms-api.hibiki-radio.jp/api/v1//programs -UserAgent $useragent -Headers $headers
$res|Where-Object{$_.episode_updated_at -And((get-date $_.episode_updated_at)-gt (get-date).AddMonths(-1))}|%{"|"+$_.access_id + "|" +$_.name+"|"+$_.cast+"|"}>access_ids.txt
```

|access_id|name|cast|
--|--|--
|Septet|Septet Chords ～Radio Konzert～|石井孝英, 唐崎孝二, 安達勇人|
|loschool|れおぱーど・すくーる　～ Lesson3 ～|上高 涼楓, 上石直行, 古賀陽菜|
|animania|あにまにあ|西尾知亜紀（北陸放送アナウンサー）|
|argonavis|Argonavis ラジオライン|日向大輔, 前田誠二|
|ccsakura|WEBラジオ TVアニメカードキャプターさくら クリアカード編 ハピネスメモリーズ～ハピメモラジオ～|丹下桜|
|ooimachi|大井町クリームソーダのシュワシュワオーバーフロー・エコータイム|入江玲於奈, 西山宏太朗, 谷口悠|
|alterna|おるらじ～キャプテン、聞いて下さい！～|安済知佳, 佳村はるか|
|kadoradi|カドラジ|河本啓佑, 加藤里保菜, 小日向茜|
|gfonpu|ガルフレ♪ラジオ｢明音と文緒の聖櫻学園放送室♪｣|佐藤利奈, 名塚佳織|
|konosuba|この素晴らしいラジオに祝福を！|高橋李依, 福島潤|
|yuzuradi|小林裕介・石上静香のゆずラジ|小林裕介, 石上静香|
|nanjo|こんにちは！なんじょーさん!!|南條愛乃|
|siegfeld|シークフェルトのえ～でるラジオ|野本ほたる, 工藤晴香|
|revuestarlight|少女☆歌劇ラジオスタァライト|小山百代, 佐藤日向|
|ssp|Stray Sheep Paradise 放送部 超☆ルクルの部屋|永野愛理|
|symphogear|戦姫絶笑シンフォギアRADIO||
|shiroben|たなか久美の御城勉強ラヂオ||
|hanaso|千菅春香と種﨑敦美の「はなそ！」|千菅春香, 種﨑敦美|
|minorhythm|茅原実里radio minorhythm|茅原実里|
|chomipa|ちょうみりょうぱーてぃー|永野希, 藤川茜, 吉成由貴|
|joshikin|津田健次郎・大河元気のジョシ禁ラジオ!!|津田健次郎, 大河元気|
|imas_cg|デレラジ☆|アイドルマスターシンデレラガールズ|
|imas_cg_live|デレラジ☆　生放送|アイドルマスターシンデレラガールズ|
|sora|徳井青空のまぁるくなぁれ！|徳井青空|
|kawaii|中島由貴・武田羅梨沙多胡のかわいいラジオ|中島由貴, 武田羅梨沙多胡|
|rakuon|仲村宗悟・Machicoのらくおんf|仲村宗悟, Machico|
|ff|南條愛乃・エオルゼアより愛をこめて|南條愛乃|
|tsunradi|新田恵海のえみゅーじっく♪すぱいす☆|新田恵海|
|garupa|バンドリ！ ガルパラジオ with Afterglow|三澤紗千香|
|poppin-radio|バンドリ！ポッピンラジオ！|愛美, 伊藤彩沙, 西本りみ, 大塚紗英, 大橋彩香|
|pure|ピュアモンラジオ|柳木みり, 吉咲みゆ|
|priconne_re|プリコネチャンネルRe:Dive|Ｍ・Ａ・Ｏ, 伊藤美来, 立花理香|
|prichanradio|プリ☆チャンラジオ|	林鼓子|
|priparadio|プリパラジオ||
|golden-max|森嶋秀太・天野七瑠・鮎川太陽のゴールデンＭＡＸ||
|moriya_radio|森谷里美の完パケラジオ！|森谷里美|
|midnightmake|夜中メイクが気になったから|たかはし智秋, 前田誠二, 千菅春香|
|1000chan|RADIO 1000ちゃんねる|新田恵海, 渕上舞, 洲崎綾, 白石稔|
|rf-vg|ラジオファイト!! ヴァンガード|代永翼, 佐藤拓也|
|llss|ラブライブ！サンシャイン!! Aqours浦の星女学院RADIO!!! |斉藤朱夏, 小林愛香, 降幡愛|
|llniji|ラブライブ！虹ヶ咲学園 ～お昼休み放送室～|久保田未夢, 楠木ともり, 田中ちえ美|
|rgr|Run Girls, Radio！！|森嶋優花, 	林鼓子, 厚木那奈美|
|share|立花子＆悠里＆未涼のシェアラジオ|山口立花子, 秋場悠里, 日高未涼|
|lumichari|Lumina Charisのルミカリキュラム！||
|ras|RAISE A SUILENのRADIO R･I･O･T|紡木吏佐, 倉知玲鳳|
|lostdecade|ロストディケイドRADIO ～アウロラ通信～|佐々木未来, 愛美|
|Roselia|RoseliaのRADIO SHOUT!|工藤晴香, 櫻川めぐ|
|workssezu|THE WORKS せず|桃井はるこ, ユカフィン|
|wts|わきことせりこ|和氣あず未, 芹澤優|


***
<span id="1" style="font-size:small">ffmpeg: 持ってないならぐぐれ。Chocolateyを使ってインストールするとパスが勝手に通るので便利だとか。</span>
