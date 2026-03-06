param(
  [string]$Origin = "https://glad-interfaces-406959.framer.app",
  [string]$OutDir = "site"
)

$ErrorActionPreference = "Stop"

$originUri = [Uri]$Origin
$originHost = $originUri.Host
$allowedHosts = @($originHost, "framerusercontent.com")

$textExt = @(
  ".html", ".htm", ".mjs", ".js", ".css", ".json", ".svg", ".xml", ".txt", ".map"
)

$seedRoutes = @(
  "/",
  "/work",
  "/sales-platform",
  "/contact",
  "/404",
  "/work/website-prototyping",
  "/work/ai-receptionist",
  "/work/system-integration",
  "/article/clive-willow",
  "/article/raven-claw",
  "/article/clay-nicolas",
  "/article/gregory-lalle"
)

$visited = [System.Collections.Generic.HashSet[string]]::new()
$queue = [System.Collections.Generic.Queue[string]]::new()

function Normalize-Url([string]$url) {
  $u = [Uri]$url
  $builder = [System.UriBuilder]$u
  $builder.Fragment = ""
  return $builder.Uri.AbsoluteUri
}

function Enqueue-Url([string]$url) {
  try {
    $normalized = Normalize-Url $url
    $u = [Uri]$normalized
    if (-not ($allowedHosts -contains $u.Host)) { return }
    if (-not $visited.Contains($normalized)) {
      $queue.Enqueue($normalized)
    }
  } catch {
    # ignore malformed url candidates
  }
}

function Ensure-Parent([string]$path) {
  $parent = Split-Path -Parent $path
  if (-not [string]::IsNullOrWhiteSpace($parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }
}

function Get-LocalPath([string]$url) {
  $u = [Uri]$url

  if ($u.Host -eq $originHost) {
    $path = $u.AbsolutePath
    if ([string]::IsNullOrWhiteSpace($path) -or $path -eq "/") {
      return Join-Path $OutDir "index.html"
    }

    $trimmed = $path.TrimStart("/")
    if ($trimmed.Contains(".")) {
      return Join-Path $OutDir ($trimmed -replace "/", "\")
    }

    return Join-Path $OutDir ((Join-Path ($trimmed -replace "/", "\") "index.html"))
  }

  if ($u.Host -eq "framerusercontent.com") {
    $base = Join-Path $OutDir "vendor\framerusercontent.com"
    $remotePath = $u.AbsolutePath.TrimStart("/")
    if ([string]::IsNullOrWhiteSpace($remotePath)) {
      $remotePath = "index.html"
    }

    if ($remotePath.EndsWith("/")) {
      $remotePath = $remotePath + "index.html"
    }

    # Framer uses query params for image transforms. Static servers ignore query on disk lookup,
    # so store every transformed variant at the same base path.
    return Join-Path $base ($remotePath -replace "/", "\")
  }

  return $null
}

function Is-TextLike([string]$localPath, [string]$url) {
  $ext = [System.IO.Path]::GetExtension($localPath).ToLowerInvariant()
  if ($textExt -contains $ext) { return $true }

  $u = [Uri]$url
  if ($u.Host -eq $originHost -and -not $u.AbsolutePath.Contains(".")) {
    return $true
  }

  return $false
}

function Rewrite-Text([string]$text) {
  $rewritten = $text
  $rewritten = $rewritten -replace "https://framerusercontent\.com/", "/vendor/framerusercontent.com/"
  $rewritten = $rewritten -replace [regex]::Escape($Origin), ""
  $rewritten = $rewritten -replace "https://$originHost", ""
  return $rewritten
}

function Extract-Urls([string]$text, [string]$baseUrl) {
  $matches = [regex]::Matches($text, 'https?://[^\s"''`<>\\)]+')
  foreach ($m in $matches) {
    Enqueue-Url $m.Value
  }

  # Relative module imports commonly found in Framer bundles.
  $relMatches = [regex]::Matches($text, '(?:(?:from\s+)|(?:import\s*\())?["''](\.{1,2}/[^"'']+\.(?:mjs|js|css|json|map))["'']')
  foreach ($m in $relMatches) {
    $relative = $m.Groups[1].Value
    try {
      $abs = [Uri]::new([Uri]$baseUrl, $relative).AbsoluteUri
      Enqueue-Url $abs
    } catch {
      # ignore
    }
  }

  # CSS url(...) references.
  $cssRel = [regex]::Matches($text, 'url\(["'']?(\.{1,2}/[^"'')]+)["'']?\)')
  foreach ($m in $cssRel) {
    $relative = $m.Groups[1].Value
    try {
      $abs = [Uri]::new([Uri]$baseUrl, $relative).AbsoluteUri
      Enqueue-Url $abs
    } catch {
      # ignore
    }
  }
}

# Seed queue.
foreach ($route in $seedRoutes) {
  Enqueue-Url ([Uri]::new($originUri, $route).AbsoluteUri)
}

Write-Host "Mirroring from $Origin"

while ($queue.Count -gt 0) {
  $current = $queue.Dequeue()
  if ($visited.Contains($current)) { continue }
  $visited.Add($current) | Out-Null

  $localPath = Get-LocalPath $current
  if (-not $localPath) { continue }
  Ensure-Parent $localPath

  try {
    Invoke-WebRequest -Uri $current -OutFile $localPath -UseBasicParsing
  } catch {
    Write-Warning "Failed: $current"
    continue
  }

  if (Is-TextLike $localPath $current) {
    $raw = Get-Content -Raw -Path $localPath
    Extract-Urls -text $raw -baseUrl $current
    $rewritten = Rewrite-Text $raw
    Set-Content -Path $localPath -Value $rewritten -NoNewline
  }

  Write-Host "Saved $current -> $localPath"
}

Write-Host "Done. Mirrored $($visited.Count) URLs to $OutDir"
