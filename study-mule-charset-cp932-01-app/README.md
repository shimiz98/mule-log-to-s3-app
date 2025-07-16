# 
## 目的
機種依存文字を含むShift-JISのjsonを受け取りたい。
その際に、素直に「Shift-JIS」だと機種依存文字はUnicodeへの変換対象外になってしまうので、Windows-31Jを指定する必要がある。
その辺りの、Muleアプリでの挙動を調べる。

## 調査結果
### content-typeのcharsetがshift-jisだと、いわゆる機種依存文字が豆腐になる。
```
$ curl -v -H 'content-type: application/json; charset=shift-jis' -d @sjis-8740-①-unicode-2460.txt http://localhost:8081/01-default-charset
* Connected to localhost (127.0.0.1) port 8081 (#0)
> POST /01-default-charset HTTP/1.1
> Host: localhost:8081
> User-Agent: curl/7.87.0
> Accept: */*
> content-type: application/json; charset=shift-jis
> Content-Length: 14
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200
< Content-Type: application/json; charset=UTF-8
< Transfer-Encoding: chunked
<
{
  "value": "\ufffd@",
  "UTF-16": "FFFD0040"
}
```

### windows-31jを指定すれば、解消する。
```
curl -v -H 'content-type: application/json; charset=windows-31j' -d @sjis-8740-①-unicode-2460.txt http://localhost:8081/01-default-charset
* Connected to localhost (127.0.0.1) port 8081 (#0)
> POST /01-default-charset HTTP/1.1
> Host: localhost:8081
> User-Agent: curl/7.87.0
> Accept: */*
> content-type: application/json; charset=windows-31j
> Content-Length: 14
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200
< Content-Type: application/json; charset=UTF-8
< Transfer-Encoding: chunked
<
{
  "value": "①",
  "UTF-16": "2460"
}
```

### 処理の先頭でwindows-31j固定にすることでも、解消する。
```
curl -v -H 'content-type: application/json; charset=shift-jis' -d @sjis-8740-①-unicode-2460.txt http://localhost:8081/02-fixed-charset
* Connected to localhost (127.0.0.1) port 8081 (#0)
> POST /02-fixed-charset HTTP/1.1
> Host: localhost:8081
> User-Agent: curl/7.87.0
> Accept: */*
> content-type: application/json; charset=shift-jis
> Content-Length: 14
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200
< Content-Type: application/json; charset=UTF-8
< Transfer-Encoding: chunked
<
{
  "value": "①",
  "UTF-16": "2460"
}
```

### ヘッダがcharset=utf-8で、中身もutf-8のHTTPボディは変換できないので、入力値チェックをする。
```
curl -v -H 'content-type: application/json; charset=utf-8' -d @sjis-8740-①-unicode-2460.txt http://localhost:8081/03-validate-charset
* Connected to localhost (127.0.0.1) port 8081 (#0)
> POST /03-validate-charset HTTP/1.1
> Host: localhost:8081
> User-Agent: curl/7.87.0
> Accept: */*
> content-type: application/json; charset=utf-8
> Content-Length: 14
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 500 Server Error
< Content-Type: text/plain; charset=UTF-8
< Content-Length: 62
< Connection: close
<
mime charset is not shift-jis: application/json; charset=utf-8
```

## curlでファイルをHTTPのリクエストボディとして使う場合

* -d, --data <data>
  * 欠点: 0x0d(CR)と、0x00が削除される。
  * 欠点: 先頭の`@`が必要なので、bashでファイル名補完できない。
* --data-ascii <data>
  * 欠点: `-d`と同義なので、そちらの方が短い。
* --data-binary <data>
  * 長所: 長いが、URL末尾に余計なファイル目が付加されないので確実。
  * 欠点: 先頭の`@`が必要なので、bashでファイル名補完できない。
* --data-raw <data>
  * 欠点: ファイルを指定できない。
* -T, --upload-file <file>
  * 長所: シンプル。
  * 欠点: URL末尾にファイル名が付加される。
  * 欠点: Expect: 100-continueが送信される。
