mkdir -Force Work, Output | Out-Null

Copy-Item -Force product.wxs.tmpl product.wxs

Copy-Item ../psshutdown.exe Work -Force
Copy-Item ../main.ps1 Work -Force
Copy-Item ../main.vbs Work -Force
Copy-Item ../quser.psm1 Work -Force

$guid1=(new-guid).guid
$guid1='B976874A-AD4B-43EE-896D-078699660446' #UpgradeCode
$guid2=(new-guid).guid

(Get-Content product.wxs) `
 -replace 'Title="PUT-FEATURE-TITLE-HERE"', 'Title="MyFeatureTitleName"' `
 -replace 'PUT-PRODUCT-NAME-HERE', 'Quserwrapper' `
 -replace 'PUT-COMPANY-NAME-HERE', 'Taylorm' `
 -replace 'UpgradeCode="PUT-GUID-HERE"', "UpgradeCode=`"$guid1`"" `
 -replace 'Id="PUT-GUID-HERE"', "Id=`"$guid2`"" | Set-Content -Path product.wxs

heat dir Work `
 -nologo `
 -var var.SourceFilesDir `
 -out components.wxs `
 -cg MyComponentGroup `
 -dr APPLICATIONROOTDIRECTORY `
 -g1 `
 -ag `
 -srd

candle -nologo -dSourceFilesDir=Work components.wxs
candle -nologo product.wxs

light -nologo -ext WixUIExtension components.wixobj product.wixobj -out Output/product.msi
