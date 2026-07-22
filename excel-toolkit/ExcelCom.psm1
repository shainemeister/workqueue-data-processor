#requires -Version 5.1
<#
.SYNOPSIS
    Excel COM automation toolkit for Windows PowerShell 5.1.

.DESCRIPTION
    Professional helpers for creating, opening, editing, formatting, and closing
    Excel workbooks via the Excel.Application COM server. Also includes CSV
    import/export and an environment preflight check for dry-run / readiness tests.

    Target runtime: Windows PowerShell 5.1 (Windows PowerShell).
    Prerequisite: Microsoft Excel installed (Excel COM creatable).

.NOTES
    Project : workqueue-data-processor / excel-toolkit
    Module  : ExcelCom
    Compat  : PowerShell 5.1+ (written for 5.1; no PS 7-only syntax)
    Threading: Use one Excel.Application instance per script path; do not parallelize COM.

    COM cleanup: prefer Invoke-ExcelSafe or pair Stop-ExcelApplication /
    Close-ExcelWorkbook in finally blocks.

    Excel close policy (enterprise-friendly):
        Quit -> wait -> one Quit reattempt -> notify user if still open.
        Never force-kills EXCEL.EXE (no Stop-Process).

    File format constant for SaveAs .xlsx:
        51 = xlOpenXMLWorkbook (Excel 2007+ workbook)

    HUMAN EDIT: New-ExcelApplication -Visible defaults; close timeouts below.

.CHANGELOG
    1.0.0  Initial release - lifecycle, cells, sheets, format, CSV, preflight
    1.1.0  Enterprise harden: remove P/Invoke + force-kill; graceful Quit/retry/notify
    1.2.0  Optional workbook open/save password; support protected import/export fixtures
#>

Set-StrictMode -Version Latest

# --- HUMAN EDIT: seconds to wait after each Quit before reattempt / finish ---
$script:ExcelCloseTimeoutSec = 3

#region Private helpers

function ConvertTo-ExcelColumnLetter {
    <#
    .SYNOPSIS
        Convert a 1-based column index to an Excel column letter (1=A, 27=AA).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 16384)]
        [int]$Column
    )

    $dividend = $Column
    $columnName = ''
    while ($dividend -gt 0) {
        $modulo = ($dividend - 1) % 26
        # Cast char to string first - PS 5.1 treats [char]+'' as numeric, not concat
        $columnName = ([string][char](65 + $modulo)) + $columnName
        $dividend = [int][math]::Floor(($dividend - $modulo) / 26)
    }
    return $columnName
}

function ConvertFrom-ExcelAddress {
    <#
    .SYNOPSIS
        Parse an A1-style address into row and column integers.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Address
    )

    if ($Address -notmatch '^\s*([A-Za-z]+)(\d+)\s*$') {
        throw "Invalid Excel address '$Address'. Expected form like A1 or BC12."
    }

    $letters = $Matches[1].ToUpperInvariant()
    $row = [int]$Matches[2]
    $col = 0
    foreach ($ch in $letters.ToCharArray()) {
        $col = ($col * 26) + ([int][char]$ch - [int][char]'A' + 1)
    }

    return [pscustomobject]@{
        Row    = $row
        Column = $col
        Address = ('{0}{1}' -f $letters, $row)
    }
}

function Resolve-ExcelCellAddress {
    <#
    .SYNOPSIS
        Resolve either Address (A1) or Row+Column into a single A1 string.
    #>
    [CmdletBinding()]
    param(
        [string]$Address,
        [int]$Row,
        [int]$Column
    )

    if (-not [string]::IsNullOrWhiteSpace($Address)) {
        $parsed = ConvertFrom-ExcelAddress -Address $Address
        return $parsed.Address
    }

    if ($Row -lt 1 -or $Column -lt 1) {
        throw 'When -Address is omitted, -Row and -Column must both be >= 1.'
    }

    return ('{0}{1}' -f (ConvertTo-ExcelColumnLetter -Column $Column), $Row)
}

function Release-ComObjectSafe {
    <#
    .SYNOPSIS
        Best-effort COM release without throwing.

    .NOTES
        Prefer ReleaseComObject (not FinalReleaseComObject) for child objects
        like Range/Worksheet. Aggressive FinalRelease on Ranges can destabilize
        the Excel RCW and surface odd cast errors on later assignments.
        Application is still released in Stop-ExcelApplication.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $ComObject
    )

    if ($null -eq $ComObject) {
        return
    }

    try {
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($ComObject)
    }
    catch {
        Write-Verbose ("Release-ComObjectSafe: {0}" -f $_.Exception.Message)
    }
}

function ConvertFrom-SecureStringPlain {
    <#
    .SYNOPSIS
        Convert SecureString to plain text for Excel COM only. Caller should not log the result.
    #>
    [CmdletBinding()]
    param(
        [SecureString]$SecurePassword
    )

    if ($null -eq $SecurePassword -or $SecurePassword.Length -eq 0) {
        return ''
    }

    $bstr = [System.IntPtr]::Zero
    try {
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        if ($bstr -ne [System.IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

function ConvertTo-SecureStringPlain {
    <#
    .SYNOPSIS
        Build a SecureString from a plain password string (CLI edge). Empty/null -> $null.
    #>
    [CmdletBinding()]
    param(
        [string]$PlainPassword
    )

    if ([string]::IsNullOrEmpty($PlainPassword)) {
        return $null
    }

    $secure = New-Object System.Security.SecureString
    foreach ($ch in $PlainPassword.ToCharArray()) {
        $secure.AppendChar($ch)
    }
    $secure.MakeReadOnly()
    return $secure
}

function Test-ExcelPasswordRelatedError {
    <#
    .SYNOPSIS
        Heuristic: does an exception message suggest a workbook open password issue?
    #>
    [CmdletBinding()]
    param(
        [string]$Message
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return $false
    }

    return [bool]($Message -match 'password|passwd|protected|encrypt|0x800A03EC|0x800A1066')
}

#endregion Private helpers

#region Application lifecycle

function New-ExcelApplication {
    <#
    .SYNOPSIS
        Start a new Excel.Application COM instance.

    .DESCRIPTION
        Creates Excel with automation-friendly defaults (hidden, no alerts,
        screen updating off). Pass -Visible for interactive debugging.

    .PARAMETER Visible
        Show the Excel UI. Default is $false (headless automation).

    .PARAMETER DisplayAlerts
        Whether Excel shows prompts (overwrite, etc.). Default $false.

    .PARAMETER ScreenUpdating
        Whether Excel redraws during operations. Default $false for speed.

    .EXAMPLE
        $app = New-ExcelApplication
        $wb  = New-ExcelWorkbook -Application $app
        # ... work ...
        Stop-ExcelApplication -Application $app

    .NOTES
        Always call Stop-ExcelApplication when finished to avoid orphan EXCEL.EXE.
    #>
    [CmdletBinding()]
    param(
        # --- HUMAN EDIT: set $true while interactively debugging automation ---
        [switch]$Visible,

        [bool]$DisplayAlerts = $false,

        [bool]$ScreenUpdating = $false
    )

    Write-Verbose 'Creating Excel.Application COM object...'
    try {
        $app = New-Object -ComObject Excel.Application
    }
    catch {
        throw ("Failed to create Excel.Application. Is Microsoft Excel installed? {0}" -f $_.Exception.Message)
    }

    # Automation defaults - reduce popups and UI churn
    $app.Visible = [bool]$Visible
    $app.DisplayAlerts = $DisplayAlerts
    $app.ScreenUpdating = $ScreenUpdating

    # Suppress macros when automation opens workbooks (security-positive)
    try {
        $app.AutomationSecurity = 3  # msoAutomationSecurityForceDisable
    }
    catch {
        Write-Verbose 'AutomationSecurity property not available; continuing.'
    }

    Write-Verbose ("Excel started. Version={0} Visible={1}" -f $app.Version, $app.Visible)
    return $app
}

function New-ExcelWorkbook {
    <#
    .SYNOPSIS
        Create a new empty workbook in an Excel application.

    .PARAMETER Application
        Excel.Application instance from New-ExcelApplication.

    .PARAMETER SheetName
        Optional name for the first worksheet.

    .EXAMPLE
        $wb = New-ExcelWorkbook -Application $app -SheetName 'Data'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Application,

        [string]$SheetName
    )

    Write-Verbose 'Adding new workbook...'
    $workbook = $Application.Workbooks.Add()

    if (-not [string]::IsNullOrWhiteSpace($SheetName)) {
        $sheet = $workbook.Worksheets.Item(1)
        $sheet.Name = $SheetName
        Release-ComObjectSafe -ComObject $sheet
    }

    return $workbook
}

function Open-ExcelWorkbook {
    <#
    .SYNOPSIS
        Open an existing workbook from disk.

    .PARAMETER Application
        Excel.Application instance.

    .PARAMETER Path
        Full or relative path to .xlsx / .xls / etc.

    .PARAMETER ReadOnly
        Open read-only when $true.

    .PARAMETER Password
        Optional workbook open password (SecureString). Never log this value.
        Empty/null means no password.

    .EXAMPLE
        $wb = Open-ExcelWorkbook -Application $app -Path 'C:\temp\report.xlsx'

    .EXAMPLE
        $wb = Open-ExcelWorkbook -Application $app -Path '.\locked.xlsx' -Password $securePwd
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Application,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [switch]$ReadOnly,

        [SecureString]$Password
    )

    $fullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw ("Workbook not found: {0}" -f $fullPath)
    }

    $hasPassword = ($null -ne $Password -and $Password.Length -gt 0)
    Write-Verbose ("Opening workbook: {0} (ReadOnly={1}; PasswordSupplied={2})" -f $fullPath, [bool]$ReadOnly, $hasPassword)

    # Workbooks.Open(Filename, UpdateLinks, ReadOnly, Format, Password, ...)
    # Password is the 5th argument. Empty string = no password.
    $plainPassword = ConvertFrom-SecureStringPlain -SecurePassword $Password
    try {
        $workbook = $Application.Workbooks.Open(
            $fullPath,
            0,
            [bool]$ReadOnly,
            [Type]::Missing,
            $plainPassword
        )
    }
    finally {
        $plainPassword = $null
    }

    return $workbook
}

function Save-ExcelWorkbook {
    <#
    .SYNOPSIS
        Save a workbook (Save or SaveAs).

    .DESCRIPTION
        If -Path is supplied (or the workbook has never been saved), performs SaveAs
        as .xlsx (file format 51). Otherwise calls Save().

        Optional -Password sets the workbook open password on SaveAs only.
        Supports -WhatIf via SupportsShouldProcess.

    .PARAMETER Workbook
        Workbook COM object.

    .PARAMETER Path
        Destination path for SaveAs. Required if the workbook is new/unsaved.

    .PARAMETER Password
        Optional workbook open password (SecureString) applied on SaveAs.
        Never log this value. Empty/null = unprotected workbook.

    .EXAMPLE
        Save-ExcelWorkbook -Workbook $wb -Path 'C:\temp\out.xlsx'
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        $Workbook,

        [string]$Path,

        [SecureString]$Password
    )

    # xlOpenXMLWorkbook = 51 (.xlsx)
    $xlOpenXMLWorkbook = 51

    $hasPath = -not [string]::IsNullOrWhiteSpace($Path)
    if ($hasPath) {
        $fullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        $directory = Split-Path -Parent $fullPath
        if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory)) {
            Write-Verbose ("Creating directory: {0}" -f $directory)
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }

        $hasPassword = ($null -ne $Password -and $Password.Length -gt 0)
        if ($PSCmdlet.ShouldProcess($fullPath, 'SaveAs workbook')) {
            Write-Verbose ("SaveAs: {0} (PasswordSupplied={1})" -f $fullPath, $hasPassword)
            # SaveAs(Filename, FileFormat, Password)
            $plainPassword = ConvertFrom-SecureStringPlain -SecurePassword $Password
            try {
                if ($hasPassword) {
                    $Workbook.SaveAs($fullPath, $xlOpenXMLWorkbook, $plainPassword)
                }
                else {
                    $Workbook.SaveAs($fullPath, $xlOpenXMLWorkbook)
                }
            }
            finally {
                $plainPassword = $null
            }
        }
        return $fullPath
    }

    $existingPath = $null
    try {
        $existingPath = [string]$Workbook.FullName
    }
    catch {
        $existingPath = $null
    }

    if ([string]::IsNullOrWhiteSpace($existingPath) -or $existingPath -notmatch '[\\/]') {
        throw 'Workbook has no path yet. Provide -Path for SaveAs.'
    }

    if ($PSCmdlet.ShouldProcess($existingPath, 'Save workbook')) {
        Write-Verbose ("Save: {0}" -f $existingPath)
        $Workbook.Save()
    }

    return $existingPath
}

function Close-ExcelWorkbook {
    <#
    .SYNOPSIS
        Close a workbook, optionally saving first.

    .PARAMETER Workbook
        Workbook COM object.

    .PARAMETER Save
        If $true, save before close (uses existing path).

    .PARAMETER Path
        If provided with -Save, SaveAs to this path first.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Workbook,

        [switch]$Save,

        [string]$Path
    )

    if ($Save) {
        if (-not [string]::IsNullOrWhiteSpace($Path)) {
            Save-ExcelWorkbook -Workbook $Workbook -Path $Path | Out-Null
        }
        else {
            Save-ExcelWorkbook -Workbook $Workbook | Out-Null
        }
    }

    Write-Verbose 'Closing workbook...'
    # Close(SaveChanges) - we already handled save above
    $Workbook.Close($false)
    Release-ComObjectSafe -ComObject $Workbook
}

function Close-ExcelApplicationWorkbooks {
    param($Application)

    try {
        $Application.DisplayAlerts = $false
        $Application.ScreenUpdating = $false
    }
    catch {
        Write-Verbose ("DisplayAlerts/ScreenUpdating: {0}" -f $_.Exception.Message)
    }

    try {
        $count = 0
        try { $count = [int]$Application.Workbooks.Count } catch { $count = 0 }
        for ($i = $count; $i -ge 1; $i--) {
            try {
                $wb = $Application.Workbooks.Item($i)
                $wb.Close($false)
                Release-ComObjectSafe -ComObject $wb
            }
            catch {
                Write-Verbose ("Close workbook {0}: {1}" -f $i, $_.Exception.Message)
            }
        }
    }
    catch {
        Write-Verbose ("While closing workbooks: {0}" -f $_.Exception.Message)
    }
}

function Stop-ExcelApplication {
    <#
    .SYNOPSIS
        Quit Excel gracefully and release the Application COM object.

    .DESCRIPTION
        Enterprise-friendly close path (never force-kills EXCEL.EXE):

          1) Close workbooks and call Quit()
          2) Wait TimeoutSec for Excel to exit
          3) One reattempt: Quit() again + wait
          4) Release COM + light GC
          5) If Excel may still be running, Write-Warning (optional Read-Host)

    .PARAMETER Application
        Excel.Application instance.

    .PARAMETER TimeoutSec
        Seconds to wait after each Quit. Default 8 (module config).

    .PARAMETER PromptUser
        If $true, prompt user to press Enter after a failed clean close.
        Default $false (safe for tests/automation).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Application,

        [int]$TimeoutSec,

        [bool]$PromptUser = $false
    )

    if ($null -eq $Application) {
        return
    }

    if (-not $TimeoutSec -or $TimeoutSec -lt 1) {
        $TimeoutSec = [int]$script:ExcelCloseTimeoutSec
        if ($TimeoutSec -lt 1) { $TimeoutSec = 8 }
    }

    Write-Verbose ("Stopping Excel (Quit, wait {0}s, one reattempt; no force-kill)..." -f $TimeoutSec)

    $quitOk = $false

    # --- Attempt 1 ---
    Close-ExcelApplicationWorkbooks -Application $Application
    try {
        $Application.Quit()
        $quitOk = $true
        Write-Verbose 'Quit() attempt 1 OK'
    }
    catch {
        Write-Verbose ("Quit attempt 1: {0}" -f $_.Exception.Message)
    }

    Start-Sleep -Seconds $TimeoutSec

    # --- Attempt 2 (exactly one reattempt) ---
    $needRetry = $true
    try {
        # If COM is already dead, further Quit is unnecessary
        $null = $Application.Workbooks.Count
    }
    catch {
        $needRetry = $false
        $quitOk = $true
        Write-Verbose 'COM no longer responds after wait; treating as closed.'
    }

    if ($needRetry) {
        Write-Verbose 'Reattempting Quit once...'
        Close-ExcelApplicationWorkbooks -Application $Application
        try {
            $Application.Quit()
            $quitOk = $true
            Write-Verbose 'Quit() attempt 2 OK'
        }
        catch {
            Write-Verbose ("Quit attempt 2: {0}" -f $_.Exception.Message)
            $quitOk = $false
        }
        Start-Sleep -Seconds $TimeoutSec
    }

    # Release COM (simple; no FinalReleaseComObject, no Stop-Process)
    try {
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($Application)
    }
    catch {
        Write-Verbose ("Release Application: {0}" -f $_.Exception.Message)
    }

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()

    # Only warn when Quit did not succeed cleanly (do not scan all EXCEL processes -
    # the user may have a legitimate workbook open).
    if (-not $quitOk) {
        $msg = 'Excel did not report a clean Quit. If a file is locked, close Excel yourself. These tools do not force-kill Excel.'
        Write-Warning $msg
        if ($PromptUser) {
            try {
                $null = Read-Host 'Press Enter after you have closed Excel (or press Enter to continue)'
            }
            catch {
                Write-Verbose 'Read-Host not available.'
            }
        }
    }
}

function Invoke-ExcelSafe {
    <#
    .SYNOPSIS
        Run a script block with an Excel app and always clean up.

    .DESCRIPTION
        Creates Excel, invokes -ScriptBlock with $app as the first argument,
        then stops Excel even if the block throws.

    .PARAMETER ScriptBlock
        Code that receives the Excel.Application as its first argument.

    .PARAMETER Visible
        Pass-through to New-ExcelApplication.

    .EXAMPLE
        Invoke-ExcelSafe -ScriptBlock {
            param($app)
            $wb = New-ExcelWorkbook -Application $app
            Set-ExcelCell -Worksheet $wb.Worksheets.Item(1) -Address 'A1' -Value 'Hi'
            Save-ExcelWorkbook -Workbook $wb -Path 'C:\temp\hi.xlsx'
            Close-ExcelWorkbook -Workbook $wb
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [switch]$Visible
    )

    $app = $null
    try {
        $app = New-ExcelApplication -Visible:$Visible
        & $ScriptBlock $app
    }
    finally {
        if ($null -ne $app) {
            Stop-ExcelApplication -Application $app
        }
    }
}

#endregion Application lifecycle

#region Worksheets

function Get-ExcelWorksheet {
    <#
    .SYNOPSIS
        Get a worksheet by 1-based index or by name.

    .PARAMETER Workbook
        Parent workbook.

    .PARAMETER Index
        1-based sheet index.

    .PARAMETER Name
        Sheet name (case-insensitive match via Excel).
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByIndex')]
    param(
        [Parameter(Mandatory = $true)]
        $Workbook,

        [Parameter(ParameterSetName = 'ByIndex')]
        [ValidateRange(1, 255)]
        [int]$Index = 1,

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
        [string]$Name
    )

    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        Write-Verbose ("Get worksheet by name: {0}" -f $Name)
        return $Workbook.Worksheets.Item($Name)
    }

    Write-Verbose ("Get worksheet by index: {0}" -f $Index)
    return $Workbook.Worksheets.Item($Index)
}

function Add-ExcelWorksheet {
    <#
    .SYNOPSIS
        Add a worksheet to a workbook.

    .PARAMETER Workbook
        Parent workbook.

    .PARAMETER Name
        Optional sheet name.

    .PARAMETER After
        Optional existing sheet object after which to insert.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Workbook,

        [string]$Name,

        $After
    )

    Write-Verbose 'Adding worksheet...'
    if ($null -ne $After) {
        $sheet = $Workbook.Worksheets.Add([Type]::Missing, $After)
    }
    else {
        # Add after the last sheet
        $last = $Workbook.Worksheets.Item($Workbook.Worksheets.Count)
        $sheet = $Workbook.Worksheets.Add([Type]::Missing, $last)
        Release-ComObjectSafe -ComObject $last
    }

    if (-not [string]::IsNullOrWhiteSpace($Name)) {
        $sheet.Name = $Name
    }

    return $sheet
}

function Rename-ExcelWorksheet {
    <#
    .SYNOPSIS
        Rename a worksheet.

    .PARAMETER Worksheet
        Sheet COM object.

    .PARAMETER NewName
        New sheet name (Excel limit: 31 chars, no specials \ / ? * [ ]).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Worksheet,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 31)]
        [string]$NewName
    )

    Write-Verbose ("Renaming sheet to: {0}" -f $NewName)
    $Worksheet.Name = $NewName
    # Do not return the COM worksheet - callers already hold $Worksheet, and
    # returning it dumps a huge property list to the host when uncaptured.
}

#endregion Worksheets

#region Cells and ranges

function Get-ExcelCell {
    <#
    .SYNOPSIS
        Read a single cell value (Value2).

    .PARAMETER Worksheet
        Target sheet.

    .PARAMETER Address
        A1-style address (e.g. B2). Mutually preferred over Row/Column.

    .PARAMETER Row
        1-based row if Address not used.

    .PARAMETER Column
        1-based column if Address not used.

    .EXAMPLE
        $v = Get-ExcelCell -Worksheet $ws -Address 'A1'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Worksheet,

        [string]$Address,

        [int]$Row,

        [int]$Column
    )

    $a1 = Resolve-ExcelCellAddress -Address $Address -Row $Row -Column $Column
    $coords = ConvertFrom-ExcelAddress -Address $a1
    $cell = $Worksheet.Cells.Item($coords.Row, $coords.Column)
    try {
        # Value2: raw underlying value (fewer locale/currency quirks than Text)
        return $cell.Value2
    }
    finally {
        Release-ComObjectSafe -ComObject $cell
    }
}

function Set-ExcelCell {
    <#
    .SYNOPSIS
        Write a single cell value.

    .PARAMETER Worksheet
        Target sheet.

    .PARAMETER Value
        Value to write (string, number, date, $null, etc.).

    .PARAMETER Address
        A1-style address.

    .PARAMETER Row
        1-based row.

    .PARAMETER Column
        1-based column.

    .EXAMPLE
        Set-ExcelCell -Worksheet $ws -Address 'A1' -Value 'Header'

    .NOTES
        Uses Cells.Item(row,col) assignment rather than Range.Value2 setter.
        PowerShell's COM binder can throw InvalidCastException (Int32->String)
        when assigning numbers to Range.Value2 in some module/StrictMode contexts.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Worksheet,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $Value,

        [string]$Address,

        [int]$Row,

        [int]$Column
    )

    $a1 = Resolve-ExcelCellAddress -Address $Address -Row $Row -Column $Column
    $coords = ConvertFrom-ExcelAddress -Address $a1
    Write-Verbose ("Set {0} (R{1}C{2}) = {3}" -f $a1, $coords.Row, $coords.Column, $Value)

    # Direct Cells.Item default-property assignment is the most reliable write path from PS 5.1
    $Worksheet.Cells.Item($coords.Row, $coords.Column) = $Value
}

function Get-ExcelRange {
    <#
    .SYNOPSIS
        Read a rectangular range as a PowerShell jagged array (rows of values).

    .PARAMETER Worksheet
        Target sheet.

    .PARAMETER StartAddress
        Top-left A1 address.

    .PARAMETER EndAddress
        Bottom-right A1 address.

    .NOTES
        Single-cell ranges return a one-element outer array with one value.
        Excel COM returns a 2D array for multi-cell ranges (1-based bounds).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Worksheet,

        [Parameter(Mandatory = $true)]
        [string]$StartAddress,

        [Parameter(Mandatory = $true)]
        [string]$EndAddress
    )

    $range = $Worksheet.Range($StartAddress, $EndAddress)
    try {
        $raw = $range.Value2
        if ($null -eq $raw) {
            return ,@()
        }

        # Single cell: scalar
        if ($raw -isnot [Array]) {
            return ,@($raw)
        }

        # Multi-cell: 2D array, 1-based in COM
        $rank = $raw.Rank
        if ($rank -eq 2) {
            $rowCount = $raw.GetLength(0)
            $colCount = $raw.GetLength(1)
            $rows = New-Object System.Collections.Generic.List[object]
            for ($r = 1; $r -le $rowCount; $r++) {
                $line = New-Object object[] $colCount
                for ($c = 1; $c -le $colCount; $c++) {
                    $line[$c - 1] = $raw.GetValue($r, $c)
                }
                $rows.Add($line)
            }
            return ,$rows.ToArray()
        }

        # 1D fallback
        return ,@($raw)
    }
    finally {
        Release-ComObjectSafe -ComObject $range
    }
}

function Set-ExcelRange {
    <#
    .SYNOPSIS
        Write a rectangular block of values starting at a top-left cell.

    .DESCRIPTION
        Accepts:
          - A rectangular object[][] / jagged array of rows
          - A flat object[] written as a single row
          - A 2D System.Array

        Values are written via Value2 in one COM call when possible.

    .PARAMETER Worksheet
        Target sheet.

    .PARAMETER StartAddress
        Top-left A1 address (e.g. A1).

    .PARAMETER Values
        Data grid to write.

    .EXAMPLE
        Set-ExcelRange -Worksheet $ws -StartAddress 'A1' -Values @(
            @('Name','Score'),
            @('Ada', 99)
        )
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Worksheet,

        [Parameter(Mandatory = $true)]
        [string]$StartAddress,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        $Values
    )

    if ($null -eq $Values) {
        throw 'Values cannot be null.'
    }

    # Normalize to list of rows (each row is object[])
    $rowList = New-Object System.Collections.Generic.List[object]
    if ($Values -is [System.Array] -and $Values.Rank -eq 2) {
        $rCount = $Values.GetLength(0)
        $cCount = $Values.GetLength(1)
        $base0 = ($Values.GetLowerBound(0) -eq 0)
        for ($r = 0; $r -lt $rCount; $r++) {
            $line = New-Object object[] $cCount
            for ($c = 0; $c -lt $cCount; $c++) {
                if ($base0) {
                    $line[$c] = $Values.GetValue($r, $c)
                }
                else {
                    $line[$c] = $Values.GetValue($r + 1, $c + 1)
                }
            }
            $rowList.Add($line)
        }
    }
    else {
        $asArray = @($Values)
        if ($asArray.Count -eq 0) {
            Write-Verbose 'Set-ExcelRange: empty values; nothing to write.'
            return
        }

        # If first element is array/list, treat as rows; else single row
        $first = $asArray[0]
        if ($first -is [System.Array] -or $first -is [System.Collections.IList]) {
            foreach ($row in $asArray) {
                $rowList.Add(@($row))
            }
        }
        else {
            $rowList.Add($asArray)
        }
    }

    $rowCount = $rowList.Count
    $colCount = 1
    foreach ($row in $rowList) {
        $len = @($row).Count
        if ($len -gt $colCount) {
            $colCount = $len
        }
    }

    # Build 0-based 2D array for Value2 assignment (Excel accepts 0-based .NET arrays)
    $grid = New-Object 'object[,]' $rowCount, $colCount
    for ($r = 0; $r -lt $rowCount; $r++) {
        $row = @($rowList[$r])
        for ($c = 0; $c -lt $colCount; $c++) {
            if ($c -lt $row.Count) {
                $grid[$r, $c] = $row[$c]
            }
            else {
                $grid[$r, $c] = $null
            }
        }
    }

    $start = ConvertFrom-ExcelAddress -Address $StartAddress
    $endColLetter = ConvertTo-ExcelColumnLetter -Column ($start.Column + $colCount - 1)
    $endRow = $start.Row + $rowCount - 1
    $endAddress = ('{0}{1}' -f $endColLetter, $endRow)

    Write-Verbose ("Set-ExcelRange {0}:{1} ({2}x{3})" -f $start.Address, $endAddress, $rowCount, $colCount)
    $range = $Worksheet.Range($start.Address, $endAddress)
    try {
        $range.Value2 = $grid
    }
    finally {
        Release-ComObjectSafe -ComObject $range
    }
}

#endregion Cells and ranges

#region Formatting

function Set-ExcelHeaderStyle {
    <#
    .SYNOPSIS
        Apply basic header styling to a row (bold; optional freeze).

    .PARAMETER Worksheet
        Target sheet.

    .PARAMETER HeaderRow
        1-based header row number. Default 1.

    .PARAMETER ColumnCount
        Number of columns to style. If omitted, uses UsedRange column count when possible.

    .PARAMETER Freeze
        Freeze panes below the header row when $true.

    .EXAMPLE
        Set-ExcelHeaderStyle -Worksheet $ws -HeaderRow 1 -ColumnCount 10 -Freeze
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Worksheet,

        [ValidateRange(1, 1048576)]
        [int]$HeaderRow = 1,

        [int]$ColumnCount,

        [switch]$Freeze
    )

    if (-not $ColumnCount -or $ColumnCount -lt 1) {
        try {
            $used = $Worksheet.UsedRange
            $ColumnCount = [int]$used.Columns.Count
            Release-ComObjectSafe -ComObject $used
        }
        catch {
            $ColumnCount = 1
        }
    }

    $endLetter = ConvertTo-ExcelColumnLetter -Column $ColumnCount
    $headerRangeAddr = ('A{0}:{1}{0}' -f $HeaderRow, $endLetter)
    Write-Verbose ("Header style on {0}" -f $headerRangeAddr)

    $range = $Worksheet.Range($headerRangeAddr)
    try {
        $range.Font.Bold = $true
    }
    finally {
        Release-ComObjectSafe -ComObject $range
    }

    if ($Freeze) {
        # Freeze below header row
        $Worksheet.Application.ActiveWindow.SplitRow = $HeaderRow
        $Worksheet.Application.ActiveWindow.FreezePanes = $true
    }
}

function Set-ExcelAutoFit {
    <#
    .SYNOPSIS
        Auto-fit columns for the used range (or a specific column span).

    .PARAMETER Worksheet
        Target sheet.

    .PARAMETER ColumnCount
        Optional fixed number of columns starting at A.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Worksheet,

        [int]$ColumnCount
    )

    if ($ColumnCount -and $ColumnCount -gt 0) {
        $endLetter = ConvertTo-ExcelColumnLetter -Column $ColumnCount
        $addr = ('A:{0}' -f $endLetter)
        Write-Verbose ("AutoFit columns {0}" -f $addr)
        $cols = $Worksheet.Range($addr).EntireColumn
        try {
            $cols.AutoFit() | Out-Null
        }
        finally {
            Release-ComObjectSafe -ComObject $cols
        }
        return
    }

    Write-Verbose 'AutoFit UsedRange columns'
    $used = $Worksheet.UsedRange
    try {
        $used.Columns.AutoFit() | Out-Null
    }
    finally {
        Release-ComObjectSafe -ComObject $used
    }
}

#endregion Formatting

#region CSV import / export

function Import-CsvToWorksheet {
    <#
    .SYNOPSIS
        Import a CSV file (or in-memory objects) into a worksheet.

    .DESCRIPTION
        Reads with Import-Csv (or uses -InputObject), writes a header row then
        data rows starting at -StartAddress (default A1).

    .PARAMETER Worksheet
        Target sheet.

    .PARAMETER Path
        Path to CSV file.

    .PARAMETER InputObject
        Alternative to Path: collection of PSObjects (e.g. from Import-Csv).

    .PARAMETER StartAddress
        Top-left cell for the header. Default A1.

    .PARAMETER HeaderMap
        Optional hashtable mapping property names to display headers.
        Keys = property names on the objects; values = header labels.

    .EXAMPLE
        Import-CsvToWorksheet -Worksheet $ws -Path '.\data.csv' -StartAddress 'A1'
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory = $true)]
        $Worksheet,

        [Parameter(ParameterSetName = 'Path', Mandatory = $true)]
        [string]$Path,

        [Parameter(ParameterSetName = 'InputObject', Mandatory = $true)]
        [object[]]$InputObject,

        [string]$StartAddress = 'A1',

        [hashtable]$HeaderMap
    )

    if ($PSCmdlet.ParameterSetName -eq 'Path') {
        $fullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        if (-not (Test-Path -LiteralPath $fullPath)) {
            throw ("CSV not found: {0}" -f $fullPath)
        }
        Write-Verbose ("Importing CSV: {0}" -f $fullPath)
        $rows = @(Import-Csv -LiteralPath $fullPath)
    }
    else {
        $rows = @($InputObject)
    }

    if ($rows.Count -eq 0) {
        Write-Warning 'Import-CsvToWorksheet: no data rows to import.'
        return [pscustomobject]@{
            RowCount    = 0
            ColumnCount = 0
            Headers     = @()
        }
    }

    # Property order from first object
    $props = @($rows[0].PSObject.Properties | ForEach-Object { $_.Name })
    $headers = foreach ($p in $props) {
        if ($null -ne $HeaderMap -and $HeaderMap.ContainsKey($p)) {
            $HeaderMap[$p]
        }
        else {
            $p
        }
    }

    $grid = New-Object System.Collections.Generic.List[object]
    $grid.Add(@($headers))
    foreach ($row in $rows) {
        $line = foreach ($p in $props) {
            $row.$p
        }
        $grid.Add(@($line))
    }

    Set-ExcelRange -Worksheet $Worksheet -StartAddress $StartAddress -Values $grid.ToArray()

    return [pscustomobject]@{
        RowCount    = $rows.Count
        ColumnCount = $props.Count
        Headers     = @($headers)
        PropertyNames = @($props)
    }
}

function Export-WorksheetToCsv {
    <#
    .SYNOPSIS
        Export a worksheet used range (or explicit range) to a CSV file.

    .PARAMETER Worksheet
        Source sheet.

    .PARAMETER Path
        Destination CSV path.

    .PARAMETER StartAddress
        Optional top-left (with EndAddress). If omitted, uses UsedRange.

    .PARAMETER EndAddress
        Optional bottom-right.

    .EXAMPLE
        Export-WorksheetToCsv -Worksheet $ws -Path 'C:\temp\out.csv'
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        $Worksheet,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$StartAddress,

        [string]$EndAddress
    )

    $fullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $directory = Split-Path -Parent $fullPath
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $useExplicit = (-not [string]::IsNullOrWhiteSpace($StartAddress)) -and (-not [string]::IsNullOrWhiteSpace($EndAddress))

    if ($useExplicit) {
        $data = Get-ExcelRange -Worksheet $Worksheet -StartAddress $StartAddress -EndAddress $EndAddress
    }
    else {
        $used = $Worksheet.UsedRange
        try {
            if ($null -eq $used) {
                throw 'Worksheet has no UsedRange to export.'
            }
            $addr = $used.Address($false, $false)
            # Address may be like $A$1:$C$10 or Sheet!$A$1:$C$10 - strip $
            $clean = $addr -replace '\$', ''
            if ($clean -match '([^!]+!)?([A-Za-z]+\d+):([A-Za-z]+\d+)') {
                $data = Get-ExcelRange -Worksheet $Worksheet -StartAddress $Matches[2] -EndAddress $Matches[3]
            }
            elseif ($clean -match '([^!]+!)?([A-Za-z]+\d+)$') {
                $data = Get-ExcelRange -Worksheet $Worksheet -StartAddress $Matches[2] -EndAddress $Matches[2]
            }
            else {
                # Fallback: read via Value2 directly
                $raw = $used.Value2
                if ($null -eq $raw) {
                    $data = @()
                }
                elseif ($raw -isnot [Array]) {
                    $data = ,@($raw)
                }
                else {
                    $rowCount = $raw.GetLength(0)
                    $colCount = $raw.GetLength(1)
                    $list = New-Object System.Collections.Generic.List[object]
                    for ($r = 1; $r -le $rowCount; $r++) {
                        $line = New-Object object[] $colCount
                        for ($c = 1; $c -le $colCount; $c++) {
                            $line[$c - 1] = $raw.GetValue($r, $c)
                        }
                        $list.Add($line)
                    }
                    $data = $list.ToArray()
                }
            }
        }
        finally {
            Release-ComObjectSafe -ComObject $used
        }
    }

    if (-not $PSCmdlet.ShouldProcess($fullPath, 'Export worksheet to CSV')) {
        return $fullPath
    }

    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($row in @($data)) {
        $cells = @($row)
        $encoded = foreach ($cell in $cells) {
            $text = if ($null -eq $cell) { '' } else { [string]$cell }
            # RFC-style CSV quoting when needed
            if ($text -match '[,"\r\n]') {
                '"' + ($text -replace '"', '""') + '"'
            }
            else {
                $text
            }
        }
        $lines.Add(($encoded -join ','))
    }

    # UTF8 without BOM for broad compatibility on PS 5.1
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines($fullPath, $lines.ToArray(), $utf8NoBom)
    Write-Verbose ("Exported CSV: {0} ({1} lines)" -f $fullPath, $lines.Count)
    return $fullPath
}

#endregion CSV import / export

#region Preflight / dry-run

function Test-ExcelComEnvironment {
    <#
    .SYNOPSIS
        Preflight checks for Excel COM automation readiness (dry-run friendly).

    .DESCRIPTION
        Validates PowerShell version, temp folder writability, and that
        Excel.Application can be created and quit cleanly. Optionally checks
        for sample data files. Does not create permanent workbooks.

    .PARAMETER CsvPath
        Optional CSV path to verify exists/readable.

    .PARAMETER SchemaPath
        Optional JSON schema path to verify exists/readable.

    .PARAMETER SkipExcelProbe
        Skip the live COM create/quit probe (path-only checks).

    .EXAMPLE
        Test-ExcelComEnvironment -CsvPath .\wq_data.csv -Verbose

    .OUTPUTS
        PSCustomObject with Passed (bool), Checks (array of results).
    #>
    [CmdletBinding()]
    param(
        [string]$CsvPath,

        [string]$SchemaPath,

        [switch]$SkipExcelProbe
    )

    $checks = New-Object System.Collections.Generic.List[object]
    $allPassed = $true

    # PowerShell version
    $ver = $PSVersionTable.PSVersion
    $psOk = ($ver.Major -gt 5) -or ($ver.Major -eq 5 -and $ver.Minor -ge 1)
    $checks.Add([pscustomobject]@{
        Name   = 'PowerShellVersion'
        Passed = $psOk
        Detail = ("{0} (target: 5.1+)" -f $ver)
    })
    if (-not $psOk) { $allPassed = $false }

    # Temp writable
    $tempFile = $null
    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        'ok' | Set-Content -LiteralPath $tempFile -Encoding ASCII
        $tempOk = Test-Path -LiteralPath $tempFile
        $checks.Add([pscustomobject]@{
            Name   = 'TempWritable'
            Passed = $tempOk
            Detail = [System.IO.Path]::GetTempPath()
        })
        if (-not $tempOk) { $allPassed = $false }
    }
    catch {
        $checks.Add([pscustomobject]@{
            Name   = 'TempWritable'
            Passed = $false
            Detail = $_.Exception.Message
        })
        $allPassed = $false
    }
    finally {
        if ($tempFile -and (Test-Path -LiteralPath $tempFile)) {
            Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
        }
    }

    # Optional CSV
    if (-not [string]::IsNullOrWhiteSpace($CsvPath)) {
        $csvFull = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CsvPath)
        $csvOk = Test-Path -LiteralPath $csvFull
        $detail = $csvFull
        if ($csvOk) {
            try {
                $null = Get-Content -LiteralPath $csvFull -TotalCount 1 -ErrorAction Stop
                $detail = "{0} (readable)" -f $csvFull
            }
            catch {
                $csvOk = $false
                $detail = $_.Exception.Message
            }
        }
        $checks.Add([pscustomobject]@{
            Name   = 'CsvPath'
            Passed = $csvOk
            Detail = $detail
        })
        if (-not $csvOk) { $allPassed = $false }
    }

    # Optional schema
    if (-not [string]::IsNullOrWhiteSpace($SchemaPath)) {
        $schemaFull = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SchemaPath)
        $schemaOk = Test-Path -LiteralPath $schemaFull
        $detail = $schemaFull
        if ($schemaOk) {
            try {
                $null = Get-Content -LiteralPath $schemaFull -Raw -ErrorAction Stop
                $detail = "{0} (readable)" -f $schemaFull
            }
            catch {
                $schemaOk = $false
                $detail = $_.Exception.Message
            }
        }
        $checks.Add([pscustomobject]@{
            Name   = 'SchemaPath'
            Passed = $schemaOk
            Detail = $detail
        })
        if (-not $schemaOk) { $allPassed = $false }
    }

    # Excel COM probe (use full lifecycle helpers so process cleanup is consistent)
    if (-not $SkipExcelProbe) {
        $excelOk = $false
        $excelDetail = ''
        $probeApp = $null
        try {
            $probeApp = New-ExcelApplication
            $excelDetail = ("Excel version {0}" -f $probeApp.Version)
            $excelOk = $true
        }
        catch {
            $excelDetail = $_.Exception.Message
            $excelOk = $false
        }
        finally {
            if ($null -ne $probeApp) {
                try { Stop-ExcelApplication -Application $probeApp } catch { }
            }
        }
        $checks.Add([pscustomobject]@{
            Name   = 'ExcelCom'
            Passed = $excelOk
            Detail = $excelDetail
        })
        if (-not $excelOk) { $allPassed = $false }
    }

    foreach ($c in $checks) {
        if ($c.Passed) {
            Write-Verbose ("[PASS] {0}: {1}" -f $c.Name, $c.Detail)
        }
        else {
            Write-Verbose ("[FAIL] {0}: {1}" -f $c.Name, $c.Detail)
        }
    }

    return [pscustomobject]@{
        Passed = $allPassed
        Checks = $checks.ToArray()
    }
}

#endregion Preflight / dry-run

#region Module exports

Export-ModuleMember -Function @(
    'New-ExcelApplication',
    'New-ExcelWorkbook',
    'Open-ExcelWorkbook',
    'Save-ExcelWorkbook',
    'Close-ExcelWorkbook',
    'Stop-ExcelApplication',
    'Invoke-ExcelSafe',
    'Get-ExcelWorksheet',
    'Add-ExcelWorksheet',
    'Rename-ExcelWorksheet',
    'Get-ExcelCell',
    'Set-ExcelCell',
    'Get-ExcelRange',
    'Set-ExcelRange',
    'Set-ExcelHeaderStyle',
    'Set-ExcelAutoFit',
    'Import-CsvToWorksheet',
    'Export-WorksheetToCsv',
    'Test-ExcelComEnvironment',
    'ConvertTo-SecureStringPlain',
    'Test-ExcelPasswordRelatedError'
)

#endregion Module exports
