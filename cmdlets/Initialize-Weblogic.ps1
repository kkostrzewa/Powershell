$BuildToolsFolder = 'C:\SVN\BuildConfigurations'

$Env:JAVA_HOME = Join-Path $BuildToolsFolder 'Java\jdk1.6.0_24'
$Env:CLASSPATH = (Join-Path $Env:JAVA_HOME 'lib')
$Env:ANT_HOME = Join-Path $BuildToolsFolder 'ant\apache-ant-1.8.2'

Add-Path (Join-Path $Env:JAVA_HOME 'bin')
Add-Path (Join-Path $Env:ANT_HOME 'bin')

