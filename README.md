# HelpParser PowerShell Module

![PSGallery](https://img.shields.io/powershellgallery/p/HelpParser)
[![CI](https://github.com/jjcarrier/HelpParser/actions/workflows/ci.yml/badge.svg)](https://github.com/jjcarrier/HelpParser/actions/workflows/ci.yml)

__This is a work in progress.__

There are known flaws, but it is in a very much usable state.

## Description

Provides a generic solution for parsing a given command's `help` command output.
This is primarily intended as a helper for quickly providing tab-completion
support for arbitrary cmd/bash-centric CLI tools.

## Installation

Initialize the repository:

Add the following to `$PROFILE` replacing `$PathToHelpParserPsm1` with the path
to the HelpParser `.psm1` file:

```pwsh
Import-Module $PathToHelpParserPsm1
```

Alternatively, this module may be installed in the [$PSModulePath](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath?view=powershell-7.3)

## Usage

Below is a simple example of providing basic tab completion to `gcc`. This serves
as a template which can be reused for many other commands supporting well-structured
help documentation. In such cases, it is likely sufficient to replace the
occurrences of `gcc` found below with the desired command. Some commands output
to stderr instead of stdout for help documentation, in such cases IO-redirection
(i.e. `2>&1` must be used) before piping the output to the `HelpParser` cmdlets.

```pwsh
$gccScriptBlock = {
    param($wordToComplete, $commandAst, $cursorPosition)

    $helpData = gcc --help
    $paramValueAssign = $wordToComplete.Contains('=') -and $wordToComplete.IndexOf("=") -lt $cursorPosition
    if ($wordToComplete.StartsWith("--") -and -not $paramValueAssign) {
        Get-ParsedHelpOptions -HelpData $helpData |
            New-ParsedHelpParamCompletionResult -WordToComplete $wordToComplete
    } elseif ($wordToComplete.StartsWith("-") -and -not $paramValueAssign) {
        Get-ParsedHelpFlags -HelpData $helpData |
            New-ParsedHelpParamCompletionResult -WordToComplete $wordToComplete
    } else {
        $resultPrefix = ''
        $values = $helpData |
            Get-ParsedHelpParamValues `
                -WordToComplete $wordToComplete `
                -CommandAst $commandAst `
                -CursorPosition $cursorPosition `
                -ParamValueAssignment:$paramValueAssign `
                -ResultPrefix ([ref]$resultPrefix)
        $values | New-ParsedHelpValueCompletionResult -ResultPrefix $resultPrefix
    }
}

Register-ArgumentCompleter -CommandName gcc -Native -ScriptBlock $gccScriptBlock
```

> NOTE: The above could be customized further to use `gcc -v --help` to obtain
  even more tab completion results, but this comes at the expense of processing
  time. In a future, version of this module a feature may be introduced to
  cache the processed tab-completion results to a file which could be
  deserialized instead of re-parsing the help data every time. This should
  improve responsiveness in such cases. For such an implementation, is would be
  advisable to at a minimum check the tool's version to determine if caches
  should be invalidated.

For a repository containing many examples utilizing this module (among other methods
of tab completion) see:


### Shortcomings

One major flaw for this approach of tab completion is that it is a very much
manual process of defining/registering argument completers (via `Register-ArgumentCompleter`)
for all of the utilities one may use. This gets to be a bit laborious since,
many of such tools tend to be very similar in command help documentation format
and can utilize the same logic for parsing.

TODO: Add a helper script `New-HelpParserArgumentCompleter` which will create a
new file containing the command of interest. This would require:

* Input for the command to execute to request the help-output for a given command and will assume
  the first word/argument in the command is the command to register.
* A destination where to save the new module.

Another significant limitation of this module is that it currently does not have
a way to dig deeper into a sub-command's help documentation, this feature may be
added later on, but may require significant rework of the underlying parsing
logic.

## Known Issues

These are the currently known issues:

* Help lines like those found in cmake such as the below are not parsed correctly:
  `-h,-H,--help,-help,-usage,/? = Print usage information and exit.`
* Parameter values seen in programs like cmake that use `<` and `>` to both indicate
  a variable substitution and enumerated values for a parameter are not supported.
  Unfortunately, it seems there is not even a consistency with casing to differentiate
  between the two. It may be possible to solve this issue by providing a feature
  where the user can explicitly supply a parameter value list for a given parameter.
* Parameter values seen in programs like rustc do not work:
  `--crate-type [bin|lib|rlib|dylib|cdylib|staticlib|proc-macro]`

## Testing

Basic tests are available via [Pester](https://pester.dev/). With Pester setup, run:

```pwsh
Invoke-Pester
```
