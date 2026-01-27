# コンテキスト付きgrep

```sh
java -jar y1grep.jar \
'.*GET.*' \
'.*HTTP/[0-9]\.[0-9].[0-9]{3}.*' \
'.*(http-outgoing-[0-9]*).*' \
./output-maven.log
```
