class ShutdownManager {
    [int]$idle = 0
    [string[]]$stdout
    [string[]]$stderr
    [string]$message = "shutting down in 30 minutes triggered off taskschd"
    [System.Diagnostics.Eventlog]$evt 
    [System.Diagnostics.ProcessStartInfo]$pinfo
    [System.Diagnostics.Process]$process

    ShutdownManager() {
        $this.evt = new-object System.Diagnostics.Eventlog("Application")
        $this.evt.Source = "ShutdownManager"
        $this.pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $this.pinfo.FileName = "shutdown"
        $this.pinfo.RedirectStandardError = $true
        $this.pinfo.RedirectStandardOutput = $true
        $this.pinfo.UseShellExecute = $false
        $this.process = New-Object System.Diagnostics.Process
        $this.process.StartInfo = $this.pinfo
    }
    shutdown() {
        $this.pinfo.Arguments = "-t 1800 -s" 
        $this.process.Start() | Out-Null
        $this.stdout = $this.process.StandardOutput.ReadToEnd()
        $this.stderr = $this.process.StandardError.ReadToEnd()
        $this.evt.WriteEntry("Shutdown initiated", [System.Diagnostics.EventLogEntryType]::Information, 500)
        $this.evt.WriteEntry($this.stdout, [System.Diagnostics.EventLogEntryType]::Information, 100)
        $this.evt.WriteEntry($this.stderr, [System.Diagnostics.EventLogEntryType]::Information, 100)
    }
    cancel() {
        $this.pinfo.Arguments = "-a" 
        $this.process.Start() | Out-Null
        # $this.process.WaitForExit()
        $this.stdout = $this.process.StandardOutput.ReadToEnd()
        $this.stderr = $this.process.StandardError.ReadToEnd()
        If(-Not ($this.stderr -Match '(1116)')) {
            # Unable to abort the system shutdown because no shutdown was in progress.(1116)
            $this.evt.WriteEntry("Shutdown canceled", [System.Diagnostics.EventLogEntryType]::Information, 600)
            $this.evt.WriteEntry($this.stdout, [System.Diagnostics.EventLogEntryType]::Information, 100)
            $this.evt.WriteEntry($this.stderr, [System.Diagnostics.EventLogEntryType]::Information, 100)
        }
    }
}


Class Quserwrapper {
    [int]$idle = 0
    [boolean]$error = $false
    [string[]]$stdout
    [string[]]$stderr
    [System.Diagnostics.Eventlog]$evt 
    [System.Diagnostics.ProcessStartInfo]$pinfo
    [System.Diagnostics.Process]$process

    Quserwrapper() {
        $this.evt = new-object System.Diagnostics.Eventlog("Application")
        $this.evt.Source = "Quserwrapper"
        $this.pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $this.pinfo.FileName = "quser"
        $this.pinfo.RedirectStandardError = $true
        $this.pinfo.RedirectStandardOutput = $true
        $this.pinfo.UseShellExecute = $false
        $this.process = New-Object System.Diagnostics.Process
        $this.process.StartInfo = $this.pinfo
    }

    GetIdle() {
        $quserRegex = $this.stdout | ForEach-Object -Process { $_ -replace '\s{2,}', ',' }
        $quserObject = $quserRegex | ConvertFrom-Csv
        $y = $quserObject."IDLE TIME"

        if ('.' -eq $y) {
            $this.idle = 0
            $this.evt.WriteEntry("$y interpreted as 0 minutes (currently active)", [System.Diagnostics.EventLogEntryType]::Information, 100)
            return
        }

        [Int32]$number = 0
        if ([Int32]::TryParse($y, [ref]$number)) {
            $this.idle = $number
            $this.evt.WriteEntry("$y interpreted as $($this.idle) minutes", [System.Diagnostics.EventLogEntryType]::Information, 200)
            return
        }

        try {
            $ts = [TimeSpan]$y
            $this.idle = $ts.TotalMinutes
            $this.evt.WriteEntry("$y interpreted as $($this.idle) minutes from $($this.stdout)", [System.Diagnostics.EventLogEntryType]::Information, 200)
            return
        }
        catch {
            $this.evt.WriteEntry("Can't cast $y into TimeSpan", [System.Diagnostics.EventLogEntryType]::Information, 300)
            $this.error = $true
        }

        $this.evt.WriteEntry("Unexpected idle time $y", [System.Diagnostics.EventLogEntryType]::Information, 300)
    }

    Check() {
        try {
            $this.process.Start() | Out-Null
            $this.process.WaitForExit()
            $this.stdout = $this.process.StandardOutput.ReadToEnd().split([Environment]::NewLine)
            $this.stderr = $this.process.StandardError.ReadToEnd().split([Environment]::NewLine)
        }
        catch [System.Management.Automation.MethodInvocationException] {
            Write-Host "Can't find $($this.pinfo.FileName) command"
        }
    }

}
