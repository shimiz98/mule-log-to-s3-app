#
## 目的・問題

## まとめ

## 参考資料

https://maven.apache.org/docs/3.9.10/release-notes.html
> Potentially Breaking Core Changes (if migrating from 3.8.x)
> * The Maven Resolver transport has changed from Wagon to “native HTTP”, see Resolver Transport guide.

https://maven.apache.org/resolver-1.x/configuration.html
> * `aether.connector.http.retryHandler.serviceUnavailable`	Comma separated list of HTTP codes that should be handled as “too many requests”.	"429,503"

https://maven.apache.org/resolver/configuration.html
> * `aether.transport.http.retryHandler.serviceUnavailable`

https://maven.apache.org/maven-logging.html
> To configure logging with SLF4J Simple, edit the properties in the ${maven.home}/conf/logging/simplelogger.properties file. See the linked reference documentation for details.

file://${maven.home}/conf/logging/simplelogger.properties
> \# MNG-6181: mvn -X also prints all debug logging from HttpClient
> org.slf4j.simpleLogger.log.org.apache.http=off
> org.slf4j.simpleLogger.log.org.apache.http.wire=off

https://hc.apache.org/httpcomponents-client-5.6.x/logging.html
> The wire logger is used to log all data transmitted to and from servers when executing HTTP requests. The wire logger uses the org.apache.hc.client5.http.wire logger name.

## 詳細ログ
### Mavenのデフォルト設定
`.mvn/jvm.config`の内容
```
-javaagent:./lib/jSSLKeyLog-1.4.jar=./output-mvn-sslkeylog.log
```


```
$ mvn -U package
Logging all SSL session keys to: C:\mulesoft\workspace-7.21a\study-mule-maven-build-with-exchange\output-mvn-sslkeylog.log
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::staticFieldBase has been called by com.google.inject.internal.aop.HiddenClassDefiner (file:/C:/Users/sh98/.sdkman/candidates/maven/current/lib/guice-5.1.0-classes.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.inject.internal.aop.HiddenClassDefiner
WARNING: sun.misc.Unsafe::staticFieldBase will be removed in a future release
[INFO] Scanning for projects...
[INFO] 
[INFO] -------< com.mycompany:study-mule-maven-build-with-exchange-app >-------
[INFO] Building study-mule-maven-build-with-exchange-app 1.0.0-SNAPSHOT
[INFO]   from pom.xml
[INFO] --------------------------[ mule-application ]--------------------------
Downloading from anypoint-exchange-v3: https://maven.anypoint.mulesoft.com/api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
Downloading from mulesoft-releases: https://repository.mulesoft.org/releases/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
Downloading from central: https://repo.maven.apache.org/maven2/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
[WARNING] The POM for a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 is missing, no dependency information available
Downloading from anypoint-exchange-v3: https://maven.anypoint.mulesoft.com/api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar
Downloading from mulesoft-releases: https://repository.mulesoft.org/releases/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar
Downloading from central: https://repo.maven.apache.org/maven2/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  9.946 s
[INFO] Finished at: 2026-01-02T00:42:19+09:00
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal on project study-mule-maven-build-with-exchange-app: Could not resolve dependencies for project com.mycompany:study-mule-maven-build-with-exchange-app:mule-application:1.0.0-SNAPSHOT
[ERROR] dependency: a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 (compile)
[ERROR]         Could not find artifact a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 in anypoint-exchange-v3 (https://maven.anypoint.mulesoft.com/api/v3/maven)
[ERROR]         Could not find artifact a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 in mulesoft-releases (https://repository.mulesoft.org/releases/)
[ERROR]         Could not find artifact a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 in central (https://repo.maven.apache.org/maven2)
[ERROR]
[ERROR] -> [Help 1]
[ERROR]
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/DependencyResolutionException
```

```
00:42:13.398778	172.16.80.226	34.203.94.216	HTTP	457	GET /api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom HTTP/1.1 
00:42:18.448003	172.16.80.226	23.20.167.176	HTTP	449	GET /releases/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom HTTP/1.1 
00:42:18.707986	172.16.80.226	104.18.19.12	HTTP	454	GET /maven2/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom HTTP/1.1 
00:42:18.754201	172.16.80.226	34.203.94.216	HTTP	457	GET /api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar HTTP/1.1 
00:42:18.952510	172.16.80.226	23.20.167.176	HTTP	449	GET /releases/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar HTTP/1.1 
00:42:19.160838	172.16.80.226	104.18.19.12	HTTP	454	GET /maven2/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar HTTP/1.1 
```

```
$ mvn -U package
Logging all SSL session keys to: C:\mulesoft\workspace-7.21a\study-mule-maven-build-with-exchange\output-mvn-sslkeylog.log
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::staticFieldBase has been called by com.google.inject.internal.aop.HiddenClassDefiner (file:/C:/Users/sh98/.sdkman/candidates/maven/current/lib/guice-5.1.0-classes.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.inject.internal.aop.HiddenClassDefiner
WARNING: sun.misc.Unsafe::staticFieldBase will be removed in a future release
[INFO] Scanning for projects...
[INFO] 
[INFO] -------< com.mycompany:study-mule-maven-build-with-exchange-app >-------
[INFO] Building study-mule-maven-build-with-exchange-app 1.0.0-SNAPSHOT
[INFO]   from pom.xml
[INFO] --------------------------[ mule-application ]--------------------------
Downloading from anypoint-exchange-v3: https://maven.anypoint.mulesoft.com/api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
Downloading from mulesoft-releases: https://repository.mulesoft.org/releases/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
Downloading from central: https://repo.maven.apache.org/maven2/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
[WARNING] The POM for a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 is missing, no dependency information available
Downloading from anypoint-exchange-v3: https://maven.anypoint.mulesoft.com/api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar
Downloading from mulesoft-releases: https://repository.mulesoft.org/releases/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar
Downloading from central: https://repo.maven.apache.org/maven2/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  5.043 s
[INFO] Finished at: 2026-01-02T00:17:13+09:00
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal on project study-mule-maven-build-with-exchange-app: Could not resolve dependencies for project com.mycompany:study-mule-maven-build-with-exchange-app:mule-application:1.0.0-SNAPSHOT
[ERROR] dependency: a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 (compile)
[ERROR]         Could not find artifact a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 in anypoint-exchange-v3 (https://maven.anypoint.mulesoft.com/api/v3/maven)
[ERROR]         Could not find artifact a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 in mulesoft-releases (https://repository.mulesoft.org/releases/)
[ERROR]         Could not find artifact a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 in central (https://repo.maven.apache.org/maven2)
[ERROR]
[ERROR] -> [Help 1]
[ERROR]
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/DependencyResolutionException
```

### 404エラーでリトライする設定の場合
※Mavenのデフォルトは「429,503」でリトライするので、404を設定に加えた。

`.mvn/jvm.config`の内容
```
-javaagent:./lib/jSSLKeyLog-1.4.jar=./output-mvn-sslkeylog.log
-Daether.connector.http.retryHandler.serviceUnavailable=404,429,503
```

Mavenのコンソール出力
```
$ mvn -U package
Logging all SSL session keys to: C:\mulesoft\workspace-7.21a\study-mule-maven-build-with-exchange\output-mvn-sslkeylog.log
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::staticFieldBase has been called by com.google.inject.internal.aop.HiddenClassDefiner (file:/C:/Users/sh98/.sdkman/candidates/maven/current/lib/guice-5.1.0-classes.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.inject.internal.aop.HiddenClassDefiner
WARNING: sun.misc.Unsafe::staticFieldBase will be removed in a future release
[INFO] Scanning for projects...
[INFO] 
[INFO] -------< com.mycompany:study-mule-maven-build-with-exchange-app >-------
[INFO] Building study-mule-maven-build-with-exchange-app 1.0.0-SNAPSHOT
[INFO]   from pom.xml
[INFO] --------------------------[ mule-application ]--------------------------
Downloading from anypoint-exchange-v3: https://maven.anypoint.mulesoft.com/api/v3/maven/dummy/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
Downloading from mulesoft-releases: https://repository.mulesoft.org/releases/dummy/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
Downloading from central: https://repo.maven.apache.org/maven2/dummy/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
[WARNING] The POM for dummy:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 is missing, no dependency information available
Downloading from anypoint-exchange-v3: https://maven.anypoint.mulesoft.com/api/v3/maven/dummy/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar
Downloading from mulesoft-releases: https://repository.mulesoft.org/releases/dummy/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar
Downloading from central: https://repo.maven.apache.org/maven2/dummy/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  03:14 min
[INFO] Finished at: 2026-01-01T22:37:51+09:00
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal on project study-mule-maven-build-with-exchange-app: Could not resolve dependencies for project com.mycompany:study-mule-maven-build-with-exchange-app:mule-application:1.0.0-SNAPSHOT
[ERROR] dependency: dummy:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 (compile)
[ERROR]         Could not find artifact dummy:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 in anypoint-exchange-v3 (https://maven.anypoint.mulesoft.com/api/v3/maven)
[ERROR]         Could not find artifact dummy:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 in mulesoft-releases (https://repository.mulesoft.org/releases/)
[ERROR]         Could not find artifact dummy:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 in central (https://repo.maven.apache.org/maven2)
[ERROR]
[ERROR] -> [Help 1]
[ERROR]
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/DependencyResolutionException
```
### anypoint-exchange-v3の404エラーでリトライする設定の場合

`.mvn/jvm.config`の内容
```
-javaagent:./lib/jSSLKeyLog-1.4.jar=./output-mvn-sslkeylog.log
-Daether.connector.http.retryHandler.serviceUnavailable.anypoint-exchange-v3=404,429,503
```

```
$ mvn -U package
Logging all SSL session keys to: C:\mulesoft\workspace-7.21a\study-mule-maven-build-with-exchange\output-mvn-sslkeylog.log
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::staticFieldBase has been called by com.google.inject.internal.aop.HiddenClassDefiner (file:/C:/Users/sh98/.sdkman/candidates/maven/current/lib/guice-5.1.0-classes.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.inject.internal.aop.HiddenClassDefiner
WARNING: sun.misc.Unsafe::staticFieldBase will be removed in a future release
[INFO] Scanning for projects...
[INFO] 
[INFO] -------< com.mycompany:study-mule-maven-build-with-exchange-app >-------
[INFO] Building study-mule-maven-build-with-exchange-app 1.0.0-SNAPSHOT
[INFO]   from pom.xml
[INFO] --------------------------[ mule-application ]--------------------------
Downloading from anypoint-exchange-v3: https://maven.anypoint.mulesoft.com/api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
Downloading from mulesoft-releases: https://repository.mulesoft.org/releases/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
Downloading from central: https://repo.maven.apache.org/maven2/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
[WARNING] The POM for a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 is missing, no dependency information available
Downloading from anypoint-exchange-v3: https://maven.anypoint.mulesoft.com/api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar
Downloading from mulesoft-releases: https://repository.mulesoft.org/releases/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar
Downloading from central: https://repo.maven.apache.org/maven2/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  01:10 min
[INFO] Finished at: 2026-01-01T22:48:12+09:00
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal on project study-mule-maven-build-with-exchange-app: Could not resolve dependencies for project com.mycompany:study-mule-maven-build-with-exchange-app:mule-application:1.0.0-SNAPSHOT
[ERROR] dependency: a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 (compile)
[ERROR]         Could not find artifact a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 in anypoint-exchange-v3 (https://maven.anypoint.mulesoft.com/api/v3/maven)
[ERROR]         Could not find artifact a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 in mulesoft-releases (https://repository.mulesoft.org/releases/)
[ERROR]         Could not find artifact a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 in central (https://repo.maven.apache.org/maven2)
[ERROR]
[ERROR] -> [Help 1]
[ERROR]
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/DependencyResolutionException
```

```
22:47:06.366325	172.16.80.226	98.89.225.51	HTTP	457	GET /api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom HTTP/1.1 
22:47:12.062910	172.16.80.226	98.89.225.51	HTTP	457	GET /api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom HTTP/1.1 
22:47:22.767264	172.16.80.226	98.89.225.51	HTTP	457	GET /api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom HTTP/1.1 
22:47:38.485894	172.16.80.226	98.89.225.51	HTTP	457	GET /api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom HTTP/1.1 
22:47:39.313767	172.16.80.226	23.20.167.176	HTTP	449	GET /releases/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom HTTP/1.1 
22:47:39.568584	172.16.80.226	104.18.18.12	HTTP	454	GET /maven2/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom HTTP/1.1 
22:47:39.785051	172.16.80.226	98.89.225.51	HTTP	457	GET /api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar HTTP/1.1 
22:47:45.491112	172.16.80.226	98.89.225.51	HTTP	457	GET /api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar HTTP/1.1 
22:47:56.194001	172.16.80.226	98.89.225.51	HTTP	457	GET /api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar HTTP/1.1 
22:48:12.027830	172.16.80.226	98.89.225.51	HTTP	457	GET /api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar HTTP/1.1 
22:48:12.242269	172.16.80.226	23.20.167.176	HTTP	449	GET /releases/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar HTTP/1.1 
22:48:12.446887	172.16.80.226	104.18.18.12	HTTP	454	GET /maven2/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.jar HTTP/1.1 
```

### Mavenのコマンドライン引数「-X」を付けても、ダウンロードのリトライの有無はログ出力されなかった
```
$ mvn -U -X package
～～～中略～～～
[DEBUG] =======================================================================
[DEBUG] Resolving artifact a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:pom:1.0.0 from [anypoint-exchange-v3 (https://maven.anypoint.mulesoft.com/api/v3/maven, default, releases+snapshots), mulesoft-releases (https://repository.mulesoft.org/releases/, default, releases+snapshots), central (https://repo.maven.apache.org/maven2, default, releases)]
[DEBUG] Resolving artifact a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:pom:1.0.0 from [anypoint-exchange-v3 (https://maven.anypoint.mulesoft.com/api/v3/maven, default, releases+snapshots), mulesoft-releases (https://repository.mulesoft.org/releases/, default, releases+snapshots), central (https://repo.maven.apache.org/maven2, default, releases)]
[DEBUG] Using transporter HttpTransporter from ClassRealm[extension>org.mule.tools.maven:mule-maven-plugin:4.3.0, parent: jdk.internal.loader.ClassLoaders$AppClassLoader@15db9742] with priority 5.0 for https://maven.anypoint.mulesoft.com/api/v3/maven
[DEBUG] Using connector BasicRepositoryConnector with priority 0.0 for https://maven.anypoint.mulesoft.com/api/v3/maven
Downloading from anypoint-exchange-v3: https://maven.anypoint.mulesoft.com/api/v3/maven/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
[DEBUG] Writing tracking file 'C:\Users\sh98\.m2\repository\a81c52fe-cb9e-4acb-8e3a-284b26c4f12e\study-mule-maven-build-with-exchange-lib1\1.0.0\study-mule-maven-build-with-exchange-lib1-1.0.0.pom.lastUpdated'
[DEBUG] Using transporter HttpTransporter from ClassRealm[extension>org.mule.tools.maven:mule-maven-plugin:4.3.0, parent: jdk.internal.loader.ClassLoaders$AppClassLoader@15db9742] with priority 5.0 for https://repository.mulesoft.org/releases/
[DEBUG] Using connector BasicRepositoryConnector with priority 0.0 for https://repository.mulesoft.org/releases/
Downloading from mulesoft-releases: https://repository.mulesoft.org/releases/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
[DEBUG] Writing tracking file 'C:\Users\sh98\.m2\repository\a81c52fe-cb9e-4acb-8e3a-284b26c4f12e\study-mule-maven-build-with-exchange-lib1\1.0.0\study-mule-maven-build-with-exchange-lib1-1.0.0.pom.lastUpdated'
[DEBUG] Using transporter HttpTransporter from ClassRealm[extension>org.mule.tools.maven:mule-maven-plugin:4.3.0, parent: jdk.internal.loader.ClassLoaders$AppClassLoader@15db9742] with priority 5.0 for https://repo.maven.apache.org/maven2
[DEBUG] Using connector BasicRepositoryConnector with priority 0.0 for https://repo.maven.apache.org/maven2
Downloading from central: https://repo.maven.apache.org/maven2/a81c52fe-cb9e-4acb-8e3a-284b26c4f12e/study-mule-maven-build-with-exchange-lib1/1.0.0/study-mule-maven-build-with-exchange-lib1-1.0.0.pom
[DEBUG] Writing tracking file 'C:\Users\sh98\.m2\repository\a81c52fe-cb9e-4acb-8e3a-284b26c4f12e\study-mule-maven-build-with-exchange-lib1\1.0.0\study-mule-maven-build-with-exchange-lib1-1.0.0.pom.lastUpdated'
[WARNING] The POM for a81c52fe-cb9e-4acb-8e3a-284b26c4f12e:study-mule-maven-build-with-exchange-lib1:jar:1.0.0 is missing, no dependency information available
～～～以下略～～～
```