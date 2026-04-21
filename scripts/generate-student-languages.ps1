$projectPaths = Get-Content "./project-paths.txt"
$rows = @()

function Get-LanguageFromFile($filePath) {
    if ([string]::IsNullOrWhiteSpace($filePath)) {
        return "Other"
    }

    $filePath = $filePath.Trim()

    if ($filePath.EndsWith(".cs")) { return "C#" }
    if ($filePath.EndsWith(".cshtml")) { return "Razor" }
    if ($filePath.EndsWith(".js")) { return "JavaScript" }
    if ($filePath.EndsWith(".ts")) { return "TypeScript" }
    if ($filePath.EndsWith(".tsx")) { return "TypeScript React" }
    if ($filePath.EndsWith(".jsx")) { return "JavaScript React" }
    if ($filePath.EndsWith(".css")) { return "CSS" }
    if ($filePath.EndsWith(".scss")) { return "SCSS" }
    if ($filePath.EndsWith(".html")) { return "HTML" }
    if ($filePath.EndsWith(".json")) { return "JSON" }
    if ($filePath.EndsWith(".xml")) { return "XML" }
    if ($filePath.EndsWith(".yml")) { return "YAML" }
    if ($filePath.EndsWith(".yaml")) { return "YAML" }
    if ($filePath.EndsWith(".md")) { return "Markdown" }

    return "Other"
}

foreach ($projectPath in $projectPaths) {
    if ([string]::IsNullOrWhiteSpace($projectPath)) {
        continue
    }

    Write-Host "Analyserar commits i: $projectPath"

    $results = @()

    $commitShas = git log --pretty=format:"%H" -- "$projectPath"

    foreach ($sha in $commitShas) {
        $author = git show -s --format="%an" $sha

        git show --numstat --format="" --no-renames $sha -- "$projectPath" | ForEach-Object {
            $line = $_.Trim()

            if ([string]::IsNullOrWhiteSpace($line)) {
                return
            }

            $parts = $line -split "`t"

            if ($parts.Length -ne 3) {
                return
            }

            $additions = $parts[0]
            $deletions = $parts[1]
            $file = $parts[2]

            if ($additions -notmatch '^\d+$') {
                return
            }

            if ($deletions -notmatch '^\d+$') {
                return
            }

            $language = Get-LanguageFromFile $file
            $changedLines = [int]$additions + [int]$deletions

            $results += [PSCustomObject]@{
                ProjectPath = $projectPath
                Student = $author.Trim()
                Language = $language
                ChangedLines = $changedLines
            }
        }
    }

    $groupedResults = $results |
        Group-Object ProjectPath, Student, Language |
        ForEach-Object {
            [PSCustomObject]@{
                ProjectPath = $_.Group[0].ProjectPath
                Student = $_.Group[0].Student
                Language = $_.Group[0].Language
                ChangedLines = ($_.Group | Measure-Object ChangedLines -Sum).Sum
            }
        }

    $rows += $groupedResults
}

$rows |
    Sort-Object ProjectPath, Student, Language |
    Export-Csv -Path "./data/student_languages.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Klar! data/student_languages.csv skapad."