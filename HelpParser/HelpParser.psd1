@{
    RootModule = 'HelpParser.psm1'
    ModuleVersion = '0.3.3'
    GUID = 'f36e4dd6-6d0b-4184-8f20-405c9670138f'
    Author = 'Jon Carrier'
    CompanyName = 'Unknown'
    Copyright = '(c) Jon Carrier. All rights reserved.'
    Description = 'Provides a generic parser for well-formatted command-help documentation. This module is intended to be used to easily/quickly create tab-completion scripts for a wide variety of CLI tools.'

    # CompatiblePSEditions = @()
    # PowerShellVersion = ''
    # RequiredModules = @()
    # ScriptsToProcess = @()
    # TypesToProcess = @()
    # FormatsToProcess = @()
    # NestedModules = @()

    FunctionsToExport = @(
        "Get-ParsedHelpParam",
        "Get-ParsedHelpFlag",
        "Get-ParsedHelpOption",
        "Get-ParsedHelpParamValue",
        "New-ParsedHelpParamCompletionResult",
        "New-ParsedHelpValueCompletionResult",
        "New-HelpParserTabCompleter"
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
            Tags = @('Windows', 'MacOS', 'Linux', 'Tab-Completion', 'CompletionResult', 'HelpDoc')
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
