$projectPaths = Get-Content "./project-paths.txt"
$rows = @()

foreach ($projectPath in $projectPaths) {
    if ([string]::IsNullOrWhiteSpace($projectPath)) {
        continue
    }

    Write-Host "Analyserar: $projectPath"

    $results = @{}

    git ls-files "$projectPath/*.cs" | ForEach-Object {
        $file = $_
        Write-Host "  Kollar $file"

        git blame --line-porcelain HEAD -- "$file" | ForEach-Object {
            if ($_ -like "author *") {
                $author = $_.Substring(7).Trim()

                if ($results.ContainsKey($author)) {
                    $results[$author]++
                }
                else {
                    $results[$author] = 1
                }
            }
        }
    }

    $totalLines = 0

    foreach ($value in $results.Values) {
        $totalLines += $value
    }

    foreach ($author in $results.Keys) {
        $lineCount = $results[$author]
        $percent = 0

        if ($totalLines -gt 0) {
            $percent = [math]::Round(($lineCount / $totalLines) * 100, 2)
        }

        $rows += [PSCustomObject]@{
            ProjectPath = $projectPath
            Student = $author
            FinalLines = $lineCount
            TotalLines = $totalLines
            Percent = $percent
        }
    }
}

$rows |
    Sort-Object ProjectPath, Student |
    Export-Csv -Path "./data/code_ownership.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Klar! data/code_ownership.csv skapad."