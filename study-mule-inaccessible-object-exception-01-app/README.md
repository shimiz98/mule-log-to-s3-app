# study-mule-inaccessible-object-exception-01-app
## 事象

log4j2.xmlにて、`<AsyncRoot>`を、デフォルトの`level="INFO"`から`level="TRACE"`にしたところ、Muleアプリ起動時に(Anypoint Studio)で、以下のエラーが発生したのを解析した。

### エラーメッセージ

```
java.lang.reflect.InaccessibleObjectException: 
  Unable to make field public static final java.lang.String org.mule.runtime.container.internal.ContainerClassLoaderFilterFactory$ContainerClassLoaderFilter.CLASS_PACKAGE_SPLIT_REGEX accessible: 
  module org.mule.runtime.container does not "opens org.mule.runtime.container.internal" to module org.apache.commons.lang3
```
※上記の実際は1行。見やすくするため改行を追記した。


### スタックトレース
```
java.lang.reflect.InaccessibleObjectException: Unable to make field public static final java.lang.String org.mule.runtime.container.internal.ContainerClassLoaderFilterFactory$ContainerClassLoaderFilter.CLASS_PACKAGE_SPLIT_REGEX accessible: module org.mule.runtime.container does not "opens org.mule.runtime.container.internal" to module org.apache.commons.lang3
	at java.base/java.lang.reflect.AccessibleObject.checkCanSetAccessible(AccessibleObject.java:354) ~[?:?]
	at java.base/java.lang.reflect.AccessibleObject.checkCanSetAccessible(AccessibleObject.java:297) ~[?:?]
	at java.base/java.lang.reflect.Field.checkCanSetAccessible(Field.java:178) ~[?:?]
	at java.base/java.lang.reflect.AccessibleObject.setAccessible(AccessibleObject.java:130) ~[?:?]
	at org.apache.commons.lang3@3.17.0/org.apache.commons.lang3.builder.ReflectionToStringBuilder.appendFieldsIn(ReflectionToStringBuilder.java:649) ~[commons-lang3-3.17.0.jar:?]
	at org.apache.commons.lang3@3.17.0/org.apache.commons.lang3.builder.ReflectionToStringBuilder.toString(ReflectionToStringBuilder.java:853) ~[commons-lang3-3.17.0.jar:?]
	at org.apache.commons.lang3@3.17.0/org.apache.commons.lang3.builder.ReflectionToStringBuilder.toString(ReflectionToStringBuilder.java:387) ~[commons-lang3-3.17.0.jar:?]
	at org.apache.commons.lang3@3.17.0/org.apache.commons.lang3.builder.ReflectionToStringBuilder.toString(ReflectionToStringBuilder.java:189) ~[commons-lang3-3.17.0.jar:?]
	at org.apache.commons.lang3@3.17.0/org.apache.commons.lang3.builder.ToStringBuilder.reflectionToString(ToStringBuilder.java:141) ~[commons-lang3-3.17.0.jar:?]
<1>	at org.mule.runtime.container@4.9.0/org.mule.runtime.container.internal.ContainerClassLoaderFilterFactory$ContainerClassLoaderFilter.toString(ContainerClassLoaderFilterFactory.java:147) ~[mule-module-container-4.9.0.jar:?]
<2>	at org.mule.runtime.artifact@4.9.0/org.mule.runtime.module.artifact.api.classloader.exception.NotExportedClassException.getMessage(NotExportedClassException.java:77) ~[mule-module-artifact-4.9.0.jar:?]
	at org.mule.runtime.artifact@4.9.0/org.mule.runtime.module.artifact.api.classloader.exception.CompositeClassNotFoundException.lambda$new$0(CompositeClassNotFoundException.java:48) ~[mule-module-artifact-4.9.0.jar:?]
	at java.base/java.util.stream.ReferencePipeline$3$1.accept(ReferencePipeline.java:197) ~[?:?]
～～～中略～～～
	at wrapper@3.5.51/org.tanukisoftware.wrapper.WrapperManager$11.run(WrapperManager.java:4537) [wrapper-3.5.51.jar:?]
```
※上記の番号<1>と<2>は実際は無く、見やすくするため追記したもの。

※全量は memo ディレクトリを参照。

## 解析
### Mule Runtimeのソースコード

スタックトレースの<1>の箇所のソースでは、無条件に commons.lang3 を呼び出している。
これは事象と合致する。ただし再現条件の「log4j2.xmlのログレベルをINFOからTRACEで発生する」は、ここでは無い。

https://github.com/mulesoft/mule/blob/4.9.0/modules/container/src/main/java/org/mule/runtime/container/internal/ContainerClassLoaderFilterFactory.java#L147
https://github.com/mulesoft/mule/blob/8bb37a33f0884f056f096e1dcfadbf2d3bbc416c/modules/container/src/main/java/org/mule/runtime/container/internal/ContainerClassLoaderFilterFactory.java#L147
※Mule Runtime 4.9.0 で再現したため、対応する git tag 探して参照した。

スタックトレースの<2>の箇所のソースでは、logger.isTraceEnabled() ならば、toString()している。
これは、事象の「log4j2.xmlのログレベルをINFOからTRACEで発生する」と合致する。

https://github.com/mulesoft/mule/blob/4.9.0/modules/artifact/src/main/java/org/mule/runtime/module/artifact/api/classloader/exception/NotExportedClassException.java#L77


以下のmodule-info.javaに "opens org.mule.runtime.container.internal" to module org.apache.commons.lang3 が存在しないことも確認した。

https://github.com/mulesoft/mule/blob/4.9.0/modules/container/src/main/java/module-info.java


備忘: Mule Runtimeのgitレポジトリは複数に分かれている。
* https://github.com/mulesoft/mule
* https://github.com/mulesoft/mule-api
* https://github.com/mulesoft/mule-extensions-api
* https://github.com/mulesoft/mule-dsl-api
* https://github.com/mulesoft/mule-http-service

## JavaVMにロードされているClassのリスト

```sh
jcmd 19268 help VM.classloaders
jcmd 19268 VM.classloaders > output-jcmd-classloaders_default.txt
jcmd 19268 VM.classloaders show-classes=true > output-jcmd-classloaders_show-classes=true.txt
jcmd 19268 VM.classloaders verbose=true > output-jcmd-classloaders_verbose=true.txt
jcmd 19268 VM.classloaders fold=false > output-jcmd-classloaders_fold=false.txt
# ClassLoader自体のクラス名、および、ロードされたcommons.lang3のクラスを抽出した
sed -En '/^[ |]*\+/P;/lang3/P' './output-jcmd-classloaders-show-classes=true.txt'
```

help `jcmd 19268 help VM.classloaders`の出力を見て、「show-classes=true」を指定した。
```
19268:
VM.classloaders
Prints classloader hierarchy.

Impact: Medium: Depends on number of class loaders and classes loaded.

Permission: java.lang.management.ManagementPermission(monitor)

Syntax : VM.classloaders [options]

Options: (options must be specified using the <key> or <key>=<value> syntax)
        show-classes : [optional] Print loaded classes. (BOOLEAN, false)
        verbose : [optional] Print detailed information. (BOOLEAN, false)
        fold :  Show loaders of the same name and class as one. (BOOLEAN, true)
```

事象のcommons.lang3のクラスをロードしたClassLoaderは、以下。

```
+-- <bootstrap>
      +-- jdk.internal.reflect.DelegatingClassLoader
      ～～～中略～～～
      +-- "platform", jdk.internal.loader.ClassLoaders$PlatformClassLoader
            +-- "app", jdk.internal.loader.ClassLoaders$AppClassLoader
                  +-- jdk.internal.reflect.DelegatingClassLoader
                  ～～～中略～～～
                  +-- java.net.URLClassLoader
                  |     +-- jdk.internal.loader.Loader
                  |           |                        org.apache.commons.lang3.builder.ToStringBuilder
```

commons.lang3 は、1個のClassLoaderではなく、3個のClassLoaderでロードされていた。
`FilteringContainerClassLoader` と `MuleArtifactClassLoader` というクラス名から、Mule Runtime がロードしたか、Muleアプリがロードしたかの違いな気がする(未調査)。
```
$ sed -En '/^[ |]*\+/P;/lang3/P' './output-jcmd-classloaders_show-classes\=true.txt' | uniq
+-- <bootstrap>
      +-- jdk.internal.reflect.DelegatingClassLoader
      +-- "platform", jdk.internal.loader.ClassLoaders$PlatformClassLoader
            +-- "app", jdk.internal.loader.ClassLoaders$AppClassLoader
                  +-- jdk.internal.reflect.DelegatingClassLoader
                  +-- sun.reflect.misc.MethodUtil
                  |     +-- jdk.internal.reflect.DelegatingClassLoader
                  +-- jdk.internal.reflect.DelegatingClassLoader
                  +-- java.lang.Module$2
                  +-- java.net.URLClassLoader
                  |     +-- jdk.internal.loader.Loader
                  |           |                        org.apache.commons.lang3.JavaVersion
                  |           |                        org.apache.commons.lang3.SystemProperties
                  |           |                        org.apache.commons.lang3.SystemProperties$$Lambda$309/0x00000217812206a8
                  |           |                        org.apache.commons.lang3.StringUtils
                  |           |                        org.apache.commons.lang3.math.NumberUtils
                  |           |                        [Lorg.apache.commons.lang3.JavaVersion;
                  |           |                        org.apache.commons.lang3.SystemUtils
                  |           |                        org.apache.commons.lang3.function.Suppliers
                  |           |                        org.apache.commons.lang3.function.Suppliers$$Lambda$310/0x00000217812212b8
                  |           |                        org.apache.commons.lang3.SystemUtils$$Lambda$311/0x00000217812214d0
                  |           |                        org.apache.commons.lang3.ArrayUtils
                  |           |                        org.apache.commons.lang3.NotImplementedException
                  |           |                        org.apache.commons.lang3.CharUtils
                  |           |                        org.apache.commons.lang3.CharUtils$$Lambda$584/0x00000217813be7c8
                  |           |                        org.apache.commons.lang3.ArrayFill
                  |           |                        org.apache.commons.lang3.ClassUtils
                  |           |                        org.apache.commons.lang3.ClassUtils$$Lambda$595/0x00000217813de870
                  |           |                        org.apache.commons.lang3.ClassUtils$$Lambda$596/0x00000217813deb00
                  |           |                        org.apache.commons.lang3.ClassUtils$$Lambda$597/0x00000217813ded28
                  |           |                        org.apache.commons.lang3.ClassUtils$$Lambda$598/0x00000217813def60
                  |           |                        org.apache.commons.lang3.builder.Builder
                  |           |                        org.apache.commons.lang3.builder.HashCodeBuilder
                  |           |                        org.apache.commons.lang3.builder.HashCodeBuilder$$Lambda$1280/0x00000217819b15e0
                  |           |                        org.apache.commons.lang3.ObjectUtils
                  |           |                        org.apache.commons.lang3.exception.CloneFailedException
                  |           |                        org.apache.commons.lang3.ObjectUtils$Null
                  |           |                        org.apache.commons.lang3.tuple.Pair
                  |           |                        org.apache.commons.lang3.tuple.ImmutablePair
                  |           |                        [Lorg.apache.commons.lang3.tuple.Pair;
                  |           |                        [Lorg.apache.commons.lang3.tuple.ImmutablePair;
                  |           |                        org.apache.commons.lang3.CharSequenceUtils
                  |           |                        org.apache.commons.lang3.builder.ToStringStyle
                  |           |                        org.apache.commons.lang3.builder.ToStringStyle$DefaultToStringStyle
                  |           |                        org.apache.commons.lang3.builder.ToStringStyle$MultiLineToStringStyle
                  |           |                        org.apache.commons.lang3.builder.ToStringStyle$NoFieldNameToStringStyle
                  |           |                        org.apache.commons.lang3.builder.ToStringStyle$ShortPrefixToStringStyle
                  |           |                        org.apache.commons.lang3.builder.ToStringStyle$SimpleToStringStyle
                  |           |                        org.apache.commons.lang3.builder.ToStringStyle$NoClassNameToStringStyle
                  |           |                        org.apache.commons.lang3.builder.ToStringStyle$JsonToStringStyle
                  |           |                        org.apache.commons.lang3.builder.ToStringStyle$$Lambda$1763/0x0000021781b03ae8
                  |           |                        org.apache.commons.lang3.builder.ToStringBuilder
                  |           |                        org.apache.commons.lang3.builder.ReflectionToStringBuilder
                  |           |                        org.apache.commons.lang3.stream.Streams
                  |           |                        org.apache.commons.lang3.ArrayUtils$$Lambda$1764/0x0000021781b3f860
                  |           |                        org.apache.commons.lang3.builder.ReflectionToStringBuilder$$Lambda$1765/0x0000021781b3fab0
                  |           |                        org.apache.commons.lang3.ArraySorter
                  |           |                        org.apache.commons.lang3.Validate
                  |           |                        org.apache.commons.lang3.builder.EqualsBuilder
                  |           |                        org.apache.commons.lang3.builder.EqualsBuilder$$Lambda$2030/0x0000021781b90310
                  |           |                        org.apache.commons.lang3.exception.ExceptionUtils
                  |           +-- java.lang.Module$2
                  |           +-- jdk.internal.reflect.DelegatingClassLoader
                  |           +-- net.bytebuddy.utility.dispatcher.JavaDispatcher$DynamicClassLoader
                  |           +-- jdk.internal.reflect.DelegatingClassLoader
                  |           +-- jdk.internal.loader.Loader
                  |                 +-- java.lang.Module$2
                  |                 +-- jdk.internal.reflect.DelegatingClassLoader
                  +-- org.mule.runtime.container.internal.FilteringContainerClassLoader
                  |     +-- org.mule.runtime.module.artifact.api.classloader.MuleArtifactClassLoader
                  |     +-- jdk.internal.loader.Loader
                  |     |     +-- java.lang.Module$2
                  |     |     +-- org.mule.runtime.module.service.api.artifact.ServiceModuleLayerFactory$MuleServiceClassLoader
                  |     +-- jdk.internal.loader.Loader
                  |     |     |                        org.apache.commons.lang3.JavaVersion
                  |     |     |                        org.apache.commons.lang3.SystemProperties
                  |     |     |                        org.apache.commons.lang3.SystemProperties$$Lambda$922/0x00000217816d8b18
                  |     |     |                        org.apache.commons.lang3.StringUtils
                  |     |     |                        org.apache.commons.lang3.math.NumberUtils
                  |     |     |                        [Lorg.apache.commons.lang3.JavaVersion;
                  |     |     |                        org.apache.commons.lang3.SystemUtils
                  |     |     |                        org.apache.commons.lang3.function.Suppliers
                  |     |     |                        org.apache.commons.lang3.function.Suppliers$$Lambda$923/0x00000217816d9728
                  |     |     |                        org.apache.commons.lang3.SystemUtils$$Lambda$924/0x00000217816d9940
                  |     |     +-- jdk.internal.reflect.DelegatingClassLoader
                  |     +-- org.mule.runtime.module.artifact.api.classloader.RegionClassLoader
                  |     |     +-- org.mule.runtime.module.artifact.activation.internal.classloader.MuleSharedDomainClassLoader
                  |     |     +-- org.mule.runtime.module.artifact.api.classloader.RegionClassLoader
                  |     |           +-- org.mule.runtime.module.artifact.activation.internal.classloader.MuleApplicationClassLoader
                  |     |           +-- org.mule.runtime.module.artifact.internal.classloader.MulePluginClassLoader
                  |     +-- org.mule.runtime.module.artifact.api.classloader.MuleArtifactClassLoader
                  |           |                        org.apache.commons.lang3.math.NumberUtils
                  |           |                        org.apache.commons.lang3.StringUtils
                  |           |                        org.apache.commons.lang3.exception.ExceptionUtils
                  |           |                        org.apache.commons.lang3.ClassUtils
                  |           +-- jdk.internal.reflect.DelegatingClassLoader
                  |           +-- com.google.inject.internal.aop.ChildClassDefiner$ChildLoader
                  |           +-- jdk.internal.reflect.DelegatingClassLoader
                  +-- jdk.internal.reflect.DelegatingClassLoader
```