param(
  [string]$BaseUrl = 'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1'
)
$ErrorActionPreference = 'Stop'
foreach ($path in @('categories', 'products')) {
  $response = Invoke-RestMethod -Uri "$BaseUrl/$path" -Method Get
  if ($response.success -ne $true) { throw "$path did not return success=true" }
  if ($null -eq $response.data) { throw "$path did not return data" }
}
$products = Invoke-RestMethod -Uri "$BaseUrl/products" -Method Get
if ($products.data.Count -gt 0) {
  $id = $products.data[0].productPublicId
  $detail = Invoke-RestMethod -Uri "$BaseUrl/products/$id" -Method Get
  $images = Invoke-RestMethod -Uri "$BaseUrl/products/$id/images" -Method Get
  if ($detail.success -ne $true) { throw 'product detail did not return success=true' }
  if ($images.success -ne $true) { throw 'product images did not return success=true' }
}
Write-Output 'PUBLIC CATALOG HTTP: PASSED'
