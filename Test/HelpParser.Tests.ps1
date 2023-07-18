# Basic tests verification tests performed on various help output.

BeforeAll {
  Import-Module "$PSScriptRoot\..\HelpParser\HelpParser.psm1"
}

# TODO: Fix parsing these lines
# -h,-H,--help,-help,-usage,/? = Print usage information and exit.
# --version,-version,/V [<file>]
#

Describe 'Get-ParsedHelpFlag' {
  It "The supplied cmake help output contains 25 flags" {
    $flags = Get-ParsedHelpFlag -HelpData (Get-Content "$PSScriptRoot\TextTests\cmake.txt")
    # NOTE: Currently this implementation is only expected to expand "-L[A][H]" to two variants
    # (does not cover all permutations).
    $flags.Count | Should -Be 28
  }

  It "The supplied make help output contains 26 flags" {
    $flags = Get-ParsedHelpFlag -HelpData (Get-Content "$PSScriptRoot\TextTests\make.txt")
    $flags.Count | Should -Be 26
  }

  It "The supplied dfu-util help output contains 20 flags" {
    $flags = Get-ParsedHelpFlag -HelpData (Get-Content "$PSScriptRoot\TextTests\dfu-util.txt")
    $flags.Count | Should -Be 20
  }

  It "The supplied gcc help output contains 37 flags" {
    $flags = Get-ParsedHelpFlag -HelpData (Get-Content "$PSScriptRoot\TextTests\gcc.txt")
    $flags.Count | Should -Be 37
  }
}

Describe 'Get-ParsedHelpOption' {
  It "The supplied cmake help output contains 50 options" {
    $options = Get-ParsedHelpOption -HelpData (Get-Content "$PSScriptRoot\TextTests\cmake.txt")
    $options.Count | Should -Be 50
  }

  It "The supplied make help output contains 35 options" {
    $options = Get-ParsedHelpOption -HelpData (Get-Content "$PSScriptRoot\TextTests\make.txt")
    $options.Count | Should -Be 35
  }

  It "The supplied dfu-util help output contains 20 options" {
    $options = Get-ParsedHelpOption -HelpData (Get-Content "$PSScriptRoot\TextTests\dfu-util.txt")
    $options.Count | Should -Be 20
  }

  It "The supplied gcc help output contains 5 options" {
    $options = Get-ParsedHelpOption -HelpData (Get-Content "$PSScriptRoot\TextTests\gcc.txt")
    $options.Count | Should -Be 5
  }
}
