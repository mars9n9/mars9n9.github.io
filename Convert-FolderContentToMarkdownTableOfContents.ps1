using namespace System.Collections.Generic

function Convert-FolderContentToMarkdownTableOfContents {  
	param (
		[string]$BaseFolder,
		[string]$FiletypeFilter,
		[int]$Level = 0
	)
 
	$nl = [System.Environment]::NewLine
	$TOC = ""
	
	$repoFolderStructure = Get-ChildItem -Path $BaseFolder -Directory | Where-Object Name -NotMatch "_site|pics|_posts|styles|_layouts"
 
	foreach ($dir in ($repoFolderStructure | Sort-Object -Property Name)) {
		
		
		# Check if ix.md exists in the current directory
		$ixFile = Get-ChildItem -Path $dir.FullName -Filter "ix.md" -ErrorAction SilentlyContinue

  if ($ixFile) {
			$relativePath = $ixFile.Directory.ToString().Replace((Get-Item $BaseFolder).Parent.FullName, "").TrimStart("\").Replace("\", "/")
			if ($Level -eq 0) {
				$suffix = "https://mars9n9.github.io" + $($ixFile.Directory.ToString().Replace($BaseFolder, [string]::Empty)).Replace("\", "/")
			}
			else {
				$suffix = "https://mars9n9.github.io/$relativePath"
			}

			$TOC += "$(""  " * $Level)* [$($dir.Name)]($([uri]::EscapeUriString(""$suffix/ix.html"")))$nl"
		}
		else {
			# If ix.md does not exist, show the folder name as plain text
			$TOC += "$(""  " * $Level)* $($dir.Name)$nl"
		}
		$TOC += Convert-FolderContentToMarkdownTableOfContents -BaseFolder $dir.FullName -FiletypeFilter $FiletypeFilter -Level $($Level + 1)
		$repoStructure = Get-ChildItem -Path $dir.FullName -Filter $FiletypeFilter
		$pages = [list[PSObject]]::new()
 
		foreach ($md in ($repoStructure | Where-Object Name -NotMatch "ix.md" | Sort-Object -Property Name)) {
			$file_data = Get-Content "$($md.Directory.ToString())\$($md.Name)"  -Encoding UTF8
			# Find the first line starting with '#'
			$fileName = $file_data | Where-Object { $_ -match "^#" } | Select-Object -First 1
			if ($null -eq $fileName) {
				# If no line starts with '#', default to the file name
				$fileName = $($md.Name)
			}
			else {
				# Remove the '#' and any leading/trailing spaces
				$fileName = $fileName -replace "^#\s*", ""
			}
			$relativePath = $md.Directory.ToString().Replace((Get-Item $BaseFolder).Parent.FullName, "").TrimStart("\").Replace("\", "/")
			if ($Level -eq 0) {
				$suffix = "https://mars9n9.github.io" + $($md.Directory.ToString().Replace($BaseFolder, [string]::Empty)).Replace("\", "/")
			}
			else {
				$suffix = "https://mars9n9.github.io/$relativePath"
			}
			$page = [PSCustomObject]@{
				name = $fileName
				path = "$($([uri]::EscapeUriString(""$suffix/$($md.Name.Replace(".md", ".html"))"")))"
   }	
			$pages.Add($page)
		}
		$pages = $pages | sort-object { $_.name }
		foreach ($item in $pages) {
			$TOC += "$(""  ""*$($Level+1))* [$($item.name)]($($item.path))$nl"
  }
	}
 
	return $TOC
}

# Get the current directory and check if it contains a 'docs' folder
$currentDirectory = Get-Location
$docsFolder = Join-Path $currentDirectory "docs"

if (Test-Path $docsFolder) {
	# If 'docs' folder exists, generate the Table of Contents
	Convert-FolderContentToMarkdownTableOfContents -BaseFolder $docsFolder -BaseURL "" -FiletypeFilter "*.md" | Out-File (Join-Path $docsFolder "index.markdown") -Encoding UTF8
}
else {
	Write-Host "No 'docs' folder found in the current directory."
}
