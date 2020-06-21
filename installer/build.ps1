mkdir -Force Work, Output | Out-Null

Copy-Item ../main.ps1 Work -Force
Copy-Item ../run_once.ps1 Work -Force
Copy-Item ../run_once.vbs Work -Force
Copy-Item ../quser.psm1 Work -Force

$guid1=(new-guid).guid
$guid2=(new-guid).guid

(Get-Content quserwrapper.wxs) `
 -replace 'Title="PUT-FEATURE-TITLE-HERE"', 'Title="Quserwrapper"' `
 -replace 'PUT-PRODUCT-NAME-HERE', 'Quserwrapper' `
 -replace 'PUT-COMPANY-NAME-HERE', 'Streambox' `
 -replace 'UpgradeCode="PUT-GUID-HERE"', "UpgradeCode=`"$guid1`"" `
 -replace 'Id="PUT-GUID-HERE"', "Id=`"$guid2`"" | Set-Content -Path quserwrapper.wxs
candle.exe -nologo quserwrapper.wxs 
light.exe -nologo -ext WixUIExtension quserwrapper.wixobj -out Output/quserwrapper.msi
