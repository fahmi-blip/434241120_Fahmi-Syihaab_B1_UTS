# Set Java 24 for Flutter builds
# Run this script before running flutter commands

$env:JAVA_HOME = "C:\Program Files\Java\jdk-24"
Write-Host "✓ JAVA_HOME set to: $env:JAVA_HOME" -ForegroundColor Green
Write-Host "✓ Java version:" -ForegroundColor Green
java -version

# Also set it for gradle
$env:GRADLE_USER_HOME = "$env:USERPROFILE\.gradle"
Write-Host "✓ GRADLE_USER_HOME set to: $env:GRADLE_USER_HOME" -ForegroundColor Green
