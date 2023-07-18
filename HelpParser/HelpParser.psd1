@{
    RootModule = 'HelpParser.psm1'
    ModuleVersion = '0.1.2'
    GUID = 'f36e4dd6-6d0b-4184-8f20-405c9670138f'
    Author = 'Jon Carrier'
    CompanyName = 'Unknown'
    Copyright = '(c) Jon Carrier. All rights reserved.'
    Description = 'Provides a generic parser for well-formatted command-help output.'

    # CompatiblePSEditions = @()
    # PowerShellVersion = ''
    # RequiredModules = @()
    # ScriptsToProcess = @()
    # TypesToProcess = @()
    # FormatsToProcess = @()
    # NestedModules = @()

    FunctionsToExport = @(
        "Get-ParsedHelpParams",
        "Get-ParsedHelpFlags",
        "Get-ParsedHelpOptions",
        "Get-ParsedHelpParamValues",
        "New-ParsedHelpParamCompletionResult",
        "New-ParsedHelpValueCompletionResult"
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()

    # ModuleList = @()
    FileList = @(
        'HelpParser.psd1',
        'HelpParser.psm1'
    )

    PrivateData = @{

        PSData = @{
            Tags = @('Tab-Completion', 'CompletionResult', 'HelpDoc')
            LicenseUri = 'https://github.com/jjcarrier/PS-HelpParser/blob/main/LICENSE'
            ProjectUri = 'https://github.com/jjcarrier/PS-HelpParser'
            # IconUri = ''
            # ReleaseNotes = ''
            # Prerelease = ''
            # RequireLicenseAcceptance = $false
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfoURI = ''
    # DefaultCommandPrefix = ''
}
