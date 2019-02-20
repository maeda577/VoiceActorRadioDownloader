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
|loschool|れおぱーど・すくーる　～ Lesson2 ～|松元菜々海, 上石直行, 古賀陽菜|
|animania|あにまにあ|西尾ちあき（北陸放送アナウンサー）|
|hi-chan|アバロンスクールPresents!声優下和田／川原の褒めて伸ばすラジオ|下和田ヒロキ, 川原慶久, 杉野森玲奈（アバロン声優スクール）|
|ooimachi|大井町クリームソーダのシュワシュワオーバーフロー・エコータイム|入江玲於奈, 西山宏太朗, 谷口悠|
|alterna|おるらじ～キャプテン、聞いて下さい！～|安済知佳, 佳村はるか|
|kadoradi|カドラジ|河本啓佑, 加藤里保菜, 小日向茜|
|gfonpu|ガルフレ♪ラジオ｢明音と文緒の聖櫻学園放送室♪｣|佐藤利奈, 名塚佳織|
|kxm|喜多村英梨のradioキタエリ×モード||
|konosuba|この素晴らしいラジオに祝福を！|福島潤, 高橋李依|
|siegfeld|シークフェルトのえ～でるラジオ|野本ほたる, 工藤晴香|
|revuestarlight|少女☆歌劇ラジオスタァライト|小山百代, 佐藤日向|
|stapa|スタパレディオ|鈴木裕斗, 増田俊樹|
|symphogear-axz|戦姫絶笑シンフォギアRADIO|井口裕香, 高垣彩陽|
|shiroben|たなか久美の御城勉強ラヂオ||
|hanaso|千菅春香と種﨑敦美の「はなそ！」|千菅春香, 種﨑敦美|
|minorhythm|茅原実里radio minorhythm|茅原実里|
|chomipa|ちょうみりょうぱーてぃー|永野希, 藤川茜, 吉成由貴|
|joshikin|津田健次郎・大河元気のジョシ禁ラジオ!!|津田健次郎, 大河元気|
|tensura|転生したらスライムだった件 ジュラの森放送局|岡咲美保, 山本兼平|
|imas_cg|デレラジ☆|アイドルマスターシンデレラガールズ|
|imas_cg_live|デレラジ☆　生放送|アイドルマスターシンデレラガールズ|
|sora|徳井青空のまぁるくなぁれ！|徳井青空|
|kakegurui|徳武竜也と田中美海の賭ケグルイラジオ|田中美海, 徳武竜也|
|rakuon|仲村宗悟・Machicoのらくおん|仲村宗悟, Machico|
|ff|南條愛乃・エオルゼアより愛をこめて|南條愛乃|
|tsunradi|新田恵海のえみゅーじっく♪ろけっつ☆|新田恵海|
|garupa|バンドリ！ ガルパラジオ with Afterglow|三澤紗千香|
|poppin-radio|バンドリ！ポッピンラジオ！|愛美, 伊藤彩沙, 西本りみ, 大塚紗英, 大橋彩香|
|pakaradi|ぱかラジッ！～ウマ娘広報部～|和氣あず未, 高野麻里佳, Machico|
|pure|ピュアモンラジオ|桐生朱音, 富沢恵莉|
|priconne_re|プリコネチャンネルRe:Dive|Ｍ・Ａ・Ｏ, 伊藤美来, 立花理香|
|priparadio|プリパラジオ||
|madrigal|マドリガルRADIO|高岸美里亜, 宮木南美, 田嶌あさこ, 柘植れいか, 三浦愛恵, 高橋郁美, 奥田花子, 金城朱香, 三村亜光|
|moriya_radio|森谷里美の完パケラジオ！|森谷里美|
|eienshinken|悠久のユーフォリア　アガスティア異世界放送局|田中美海|
|midnightmake|夜中メイクが気になったから|千菅春香, 前田誠二, たかはし智秋|
|fagirl|ラジオ フレームアームズ・ガール 改|フレームアームズ・ガール|
|1000chan|RADIO 1000ちゃんねる|新田恵海, 渕上舞, 洲崎綾, 白石稔|
|ko|RADIO KNOCK OUT|村田晴郎, 橘田いずみ|
|rf-vg|ラジオファイト!! ヴァンガード|代永翼, 佐藤拓也|
|llss|ラブライブ！サンシャイン!! Aqours浦の星女学院RADIO!!! |斉藤朱夏, 小林愛香, 降幡愛|
|llniji|ラブライブ！虹ヶ咲学園 ～お昼休み放送室～|久保田未夢, 楠木ともり, 田中ちえ美|
|rgr|Run Girls, Radio！！|厚木那奈美, 森嶋優花, 	林鼓子|
|share|立花子＆悠里＆未涼のシェアラジオ|山口立花子, 秋場悠里, 日高未涼|
|aioke|RY'sのアイオケ♪RADIO||
|lumichari|Lumina Charisのルミカリキュラム！||
|ras|RAISE A SUILENのRADIO R･I･O･T|紡木吏佐, 倉知玲鳳|
|Roselia|RoseliaのRADIO SHOUT!|工藤晴香, 櫻川めぐ|
|workssezu|THE WORKS せず|桃井はるこ, ユカフィン|

***
<span id="1" style="font-size:small">ffmpeg: 持ってないならぐぐれ。Chocolateyを使ってインストールするとパスが勝手に通るので便利だとか。</span>
