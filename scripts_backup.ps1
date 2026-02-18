# Define the backup path
$backupPath = Join-Path $PSScriptRoot "VR-compagent_backup.zip"

# Define the root directory to search for scripts
$rootDir = $PSScriptRoot

# Define script file patterns to include
$scriptIncludePatterns = @(
    "*.gd",
    "*.py",
    "*.cs" # Add any other script extensions if needed
)

# Define directories/patterns to exclude entirely (e.g., large asset folders, build outputs, git)
$excludeDirPatterns = @(
    ".git",
    ".gitignore",
    ".gitattributes",
    "*.git",
    ".idea",
    ".vscode",
    "*.iml",
    ".cursor",
    ".gemini",
    ".windsurf",
    "__pycache__",
    "*.pyc",
    "*.egg-info",
    ".pytest_cache",
    ".mypy_cache",
    "venv",
    ".venv",
    "env",
    "docker-compose.yml",
    ".dockerignore",
    "*.zip", # Exclude existing backups if they are in the same dir
    "ollama_data",
    ".ollama",
    "redis-data",
    "code/godot/vrcompagent/assets", # Exclude the entire assets folder
    "code/godot/vrcompagent/build",  # Exclude build folders
    "code/unity/bin",               # Common Unity build output
    "code/unity/Library",           # Unity Library folder (large, can be regenerated)
    "code/unity/obj",               # Unity obj folder
    "code/unity/Temp"               # Unity Temp folder
)

# Get all files recursively, filter by script patterns, and exclude specific directories
$filesToCompress = Get-ChildItem -Path $rootDir -Recurse -Include $scriptIncludePatterns -File | Where-Object {
    $filePath = $_.FullName
    $isExcluded = $false
    foreach ($excludePattern in $excludeDirPatterns)
    {
        # Check if the file path is within any of the excluded directories
        if ($filePath.StartsWith((Join-Path $rootDir $excludePattern), [System.StringComparison]::OrdinalIgnoreCase))
        {
            $isExcluded = $true
            break
        }
    }
    # If the file is not excluded, and its extension is in the include patterns, keep it.
    # The -Include parameter on Get-ChildItem already filters by extension,
    # so we just need to ensure it wasn't excluded by directory.
    -not $isExcluded
}

# Create the archive with the selected files
if ($filesToCompress)
{
    Compress-Archive -Path $filesToCompress.FullName -DestinationPath $backupPath -Force -CompressionLevel Optimal
    Write-Host "Backup created successfully at: $backupPath"
} else
{
    Write-Warning "No script files found to include in the backup."
}
