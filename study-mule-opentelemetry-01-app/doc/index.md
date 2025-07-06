# Anypoint Platform の OpenTelemetry 対応状況

## 図解
![](img/mule-opentelemetry-対応状況.drawio.svg)

## (1) 第3者のlibrary(avioconsultingさん) から New Relic
New Relic のtracesのトップページ
![New Relic のtracesのトップページ](img/2025-06-30%2002_08_05-traces.png)

![New Relic のtraceの1種類](img/2025-06-30%2002_11_50-trace.png)

![New Relic のtraceのmap](img/2025-06-30%2002_14_02-map.png)

![New Relic のtraceのtimeline](img/2025-06-30%2002_14_45-timeline.png)

![New Relic のtraceのlatency](img/2025-06-30%2002_17_14-latency.png)

## (1)と(3) 第3者のlibrary(avioconsultingさん) → 自作中継Muleアプリ → AWS CloudWatch
![](img/2025-07-07T01_30_13-Clipboard.png)<br>
![](img/2025-07-07T01_33_04-Clipboard.png)

名前が表示されるspanの詳細<br>
![](img/2025-07-07T01_38_58-CloudWatch.png)
![](img/2025-07-07T01_39_07-CloudWatch.png)
![](img/2025-07-07T01_39_13-CloudWatch.png)
![](img/2025-07-07T01_39_18-CloudWatch.png)

名前が「UnknownRemoteService」のspanの詳細<br>
![](img/2025-07-07T01_39_32-CloudWatch.png)
![](img/2025-07-07T01_39_38-CloudWatch.png)
![](img/2025-07-07T01_39_44-CloudWatch.png)
![](img/2025-07-07T01_39_51-CloudWatch.png)
