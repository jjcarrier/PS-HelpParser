# Basic tests verification tests performed on various help output.

BeforeAll {
  Import-Module "$PSScriptRoot\..\HelpParser\HelpParser.psm1"

  class MockCommandAst {
    [array]$CommandElements

    MockCommandAst([string]$command) {
      $this.CommandElements = $command.Split()
    }

    [string]ToString() {
      return $this.CommandElements -join ' '
    }
  }
}

Describe 'Get-ParsedHelpFlag' {
  It "parses 28 flags from the supplied cmake help output" {
    $flags = Get-ParsedHelpFlag -HelpData (Get-Content "$PSScriptRoot\TextTests\cmake.txt")
    # NOTE: Currently this implementation is only expected to expand "-L[A][H]" to two variants
    # (does not cover all permutations).
    $expectedFlags = @(
      '-A',
      '-B',
      '-C',
      '-D',
      '-E',
      '-G',
      '-h',
      '-H',
      '-help',
      '-L',
      '-LAH',
      '-N',
      '-P',
      '-S',
      '-T',
      '-U',
      '-usage',
      '-version',
      '-Wdeprecated',
      '-Wdev',
      '-Werror=',
      '-Werror=',
      '-Wno-deprecated',
      '-Wno-dev',
      '-Wno-error=',
      '-Wno-error=',
      '/?',
      '/V'
    )

    $flags.Count | Should -Be $expectedFlags.Count
    ($flags.Param -join ' ') -eq ($expectedFlags -join ' ') | Should -Be $true
  }

  It "parses 26 flags from the supplied make help output" {
    $flags = Get-ParsedHelpFlag -HelpData (Get-Content "$PSScriptRoot\TextTests\make.txt")
    $flags.Count | Should -Be 26
  }

  It "parses 20 flags from the supplied dfu-util help output" {
    $flags = Get-ParsedHelpFlag -HelpData (Get-Content "$PSScriptRoot\TextTests\dfu-util.txt")
    $flags.Count | Should -Be 20
  }

  It "parses 37 flags from the supplied gcc help output" {
    $flags = Get-ParsedHelpFlag -HelpData (Get-Content "$PSScriptRoot\TextTests\gcc.txt")
    $flags.Count | Should -Be 37
  }
}

Describe 'Get-ParsedHelpOption' {
  It "parses 50 options from the supplied cmake help output" {
    $options = Get-ParsedHelpOption -HelpData (Get-Content "$PSScriptRoot\TextTests\cmake.txt")
    $options.Count | Should -Be 50
  }

  It "parses 35 options from the supplied make help output" {
    $options = Get-ParsedHelpOption -HelpData (Get-Content "$PSScriptRoot\TextTests\make.txt")
    $expectedOptions = @(
      '--always-make',
      '--assume-new=',
      '--assume-old=',
      '--check-symlink-times',
      '--debug',
      '--directory=',
      '--dry-run',
      '--environment-overrides',
      '--file=',
      '--help',
      '--ignore-errors',
      '--include-dir=',
      '--jobs',
      '--just-print',
      '--keep-going',
      '--load-average',
      '--makefile=',
      '--max-load',
      '--new-file=',
      '--no-builtin-rules',
      '--no-builtin-variables',
      '--no-keep-going',
      '--no-print-directory',
      '--old-file=',
      '--print-data-base',
      '--print-directory',
      '--question',
      '--quiet',
      '--recon',
      '--silent',
      '--stop',
      '--touch',
      '--version',
      '--warn-undefined-variables',
      '--what-if='
    )
    $options.Count | Should -Be $expectedOptions.Count
    ($options.Param -join ' ') -eq ($expectedOptions -join ' ') | Should -Be $true
  }

  It "parses 20 options from the supplied dfu-util help output" {
    $options = Get-ParsedHelpOption -HelpData (Get-Content "$PSScriptRoot\TextTests\dfu-util.txt")
    $options.Count | Should -Be 20
  }

  It "parses 5 options from the supplied gcc help output" {
    $options = Get-ParsedHelpOption -HelpData (Get-Content "$PSScriptRoot\TextTests\gcc.txt")
    $options.Count | Should -Be 5
  }
}

Describe 'Get-ParsedHelpParamValue' {
  It "parses 8 values from the supplied gcc help line" {
    $commandAst = [MockCommandAst]::new("gcc --help=")
    $expectedValues = @(
        'common',
        'optimizers',
        'params',
        'target',
        'warnings',
        'joined',
        'separate',
        'undocumented')
    $resultPrefix = ''
    $values = Get-ParsedHelpParamValue `
      -HelpLine "--help={common|optimizers|params|target|warnings|[^]{joined|separate|undocumented}}[,...]" `
      -WordToComplete $commandAst.CommandElements[-1] `
      -CommandAst $commandAst `
      -CursorPosition $commandAst.ToString().Length `
      -ParamValueAssignment `
		  -ResultPrefix ([ref]$resultPrefix)

    $values.Count | Should -Be $expectedValues.Count
    ($values -join ' ') -eq ($expectedValues -join ' ') | Should -Be $true
  }
}
