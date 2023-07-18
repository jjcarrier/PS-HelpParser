<#
.DESCRIPTION
	Parses a single line of help data for flag and option parameters.
#>
function Get-ParsedHelpLineElement {
	[CmdletBinding()]
	param (
		# The help data to parse.
		[Parameter(ValueFromPipeline)]
		[string]$HelpLine,

		# The regular expression to use to extract options and flags.
		[Parameter()]
		[string]$RegEx = "^\s*((-{1,2}|/)[a-zA-Z0-9#]{1}[a-zA-Z0-9\-#\[\]]*)[=\s,]?",

		# A pre-condition for qualifying the $HelpLine as a line containing
		# parameter elements.
		[Parameter()]
		[string]$PreConditionRegEx = "^\s*(-{1,2}|/)",

		# An output that indicates how many spaces the parameter was indented by.
		# This is mainly intended to provide a convinient way to remove indentation
		# of lines that follow the parameter's first line that provides additional
		# detail/context.
		[Parameter()]
		[ref]$IndentationCount
	)

	process {
		if (($HelpLine | Select-String $PreConditionRegEx).Matches.Count -eq 0) {
			return
		}

		if ($null -ne $IndentationCount) {
			$indent = ($HelpLine | Select-String '^\s+')
			if ($null -eq $indent) {
				$IndentationCount.Value = 0
			} else {
				$IndentationCount.Value = $indent.Matches[0].Length
			}
		}

		$elems = @($HelpLine.TrimStart().Split().TrimEnd(',; '))
		if ($elems.Count -eq 0) {
			return
		}

		$endIndex = $elems.IndexOf('')
		if ($endIndex -lt 0) {
			$endIndex = $elems.Count - 1
		}

		$elems[0..$endIndex] | Select-String -Pattern $RegEx -AllMatches | ForEach-Object { $_.Matches }
	}
}

<#
.DESCRIPTION
	Parses the provided help data for flag and option parameters.
#>
function Get-ParsedHelpParam {
	[CmdletBinding()]
	param (
		# The help data to parse.
		[Parameter(ValueFromPipeline)]
		[string]$HelpLine
	)

	begin {
		$lineNumber = 0
		$parsedParams = @()
	}
	process {
		$indentCount = 0
		$paramLineElems = Get-ParsedHelpLineElement -HelpLine $HelpLine  -IndentationCount ([ref]$indentCount)

		if ($null -ne $paramLineElems) {
			# TODO: check if the last processed paramLineElems had siblings, if so, copy the last sibling's $Tail to each of the other siblings.
			$sibling = [ref]$null
			$paramLineElems.Value | ForEach-Object {
				$param = $_
				$paramAlt = $null
				if ($param.IndexOf('[') -ge 0 -and $param.IndexOf(']') -ge 0) {
					# NOTE: This is a basic solution and may not cover more complex
					# scenarios where there are multiple sets of brackets in a param.
					$match = $param | Select-String -Pattern '\[([a-zA-Z0-9\-#]+)\]'
					$paramAlt = $param.Replace($match.Matches[0].Groups[0].Value, $match.Matches[0].Groups[1].Value)
					$param = $param.Replace($match.Matches[0].Groups[0].Value, '')
				}

				$item = [PSCustomObject]@{
					Param = $param.TrimEnd('[').Replace('[=','')
					Values = @()
					LineNumber = $lineNumber
					Line = $HelpLine
					Tail = @()
					TailEnd = $false
					Indent = $indentCount
					Sibling = $sibling
				}

				# TODO: support function argument to customize this?
				# CMAKE has format such as: "--log-level=<ERROR|WARNING|NOTICE|STATUS|VERBOSE|DEBUG|TRACE>"
				# Others use --option=[VALUE1|VALUE2] or --option[=VALUE1|VALUE2]
				$paramValues = @($item.Line | Select-String "(=\[|\[=)[a-zA-Z0-9\|<>]+\]")
				if ($paramValues.Count -gt 0) {
					$item.Values = @($paramValues.Matches[0].Value.Substring(2).TrimEnd(']').Split('|'))
				}

				$parsedParams += $item
				$sibling = [ref]($item)

				if ($null -ne $paramAlt) {
					$item = [PSCustomObject]@{
						Param = $paramAlt.TrimEnd('[').Replace('[=','')
						Values = @()
						LineNumber = $lineNumber
						Line = $HelpLine
						Tail = @()
						TailEnd = $false
						Indent = $indentCount
						Sibling = $sibling
					}
					$parsedParams += $item
					$sibling = [ref]($item)
				}
			}
		} elseif ($parsedParams.Count -gt 0) {
			if ([string]::IsNullOrWhiteSpace($HelpLine)) {
				$parsedParams[-1].TailEnd = $true
			} elseif (-not($parsedParams[-1].TailEnd)) {
				$parsedParams[-1].Tail += $HelpLine
			}
		}

		$lineNumber++
	}
	end {
		$parsedParams | Sort-Object -Property "Param" -CaseSensitive
	}
}

<#
.DESCRIPTION
	Parses the provided help data for flag parameters.
#>
function Get-ParsedHelpFlag {
	[CmdletBinding()]
	[OutputType([PSCustomObject])]
	param (
		# The help data to parse.
		[Parameter()]
		[string[]]$HelpData
	)

	process {
		$HelpData | Get-ParsedHelpParam | Where-object { -not $_.Param.StartsWith('--') }
	}
}

<#
.DESCRIPTION
	Parses the provided help data for option parameters.
#>
function Get-ParsedHelpOption {
	[CmdletBinding()]
	[OutputType([PSCustomObject])]
	param (
		# The help data to parse.
		[Parameter()]
		[string[]]$HelpData
	)

	process {
		$HelpData | Get-ParsedHelpParam | Where-object { $_.Param.StartsWith('--') }
	}
}

<#
.DESCRIPTION
	Creates a new tab completion ParameterName result using the provided
	parameter information.
#>
function New-ParsedHelpParamCompletionResult
{
	[CmdletBinding(SupportsShouldProcess)]
	[OutputType([System.Management.Automation.CompletionResult])]
	param (
		# Metadata for the currently processed parameter to determine whether it
		# is a relevant tab-completion result.
		[Parameter(ValueFromPipeline)]
		[object]$ParamInfo,

		# The word to provide tab-completion results for.
		[Parameter(Mandatory)]
		[string]$WordToComplete
	)
	process {
		if ( $ParamInfo.Param -like "$WordToComplete*" ) {
			$toolTip = $ParamInfo.Line
			$toolTip += "$( if ($ParamInfo.Tail.Count -gt 0) { [System.Environment]::NewLine + ($ParamInfo.Tail -join [System.Environment]::NewLine) } )"


			# This is a workaround for when two flags are identical except for their casing.
			# This should be improved on further for multi-character flags/options share
			# the same issue. In this case, it may be best to store a list of all parameter
			# strings and determine if another entry exists that would introduce this problem.
			$listItem = $ParamInfo.Param
			if ($ParamInfo.Param.StartsWith('-') -and $ParamInfo.Param.Length -eq 2 -and $ParamInfo.Param[1] -cmatch '[A-Z]') {
				$listItem += ' '
			}

			if ($PSCmdlet.ShouldProcess("New $($ParamInfo.Param) CompletionResult")) {
				[System.Management.Automation.CompletionResult]::new(
					$ParamInfo.Param,
					$listItem,
					"ParameterName",
					$toolTip)
			}
		}
	}
}

<#
.DESCRIPTION
	Gets the previous parameter in the command's abstract syntax tree object.
#>
function Get-ParsedHelpPrevParam
{
	param (
		# The AST for the completion result's current command line state.
		$CommandAst,

		# The current cusror position.
		$CursorPosition
	)

	$c = $CommandAst.ToString()
	$prev = $CommandAst.CommandElements[-1].ToString()

	if ($CursorPosition -le $c.Length) {
		$r = $c.LastIndexOf(" ", $CursorPosition)
		$l = $c.LastIndexOf(" ", $r - 1)

		while ($c[$r - 1] -eq ' ') {
			$r = $r - 1
		}

		$prev = $c.Substring($l + 1, $r - $l - 1)
	}

	$prev
}

<#
.DESCRIPTION
	Creates a new tab completion ParameterValue result using the provided
	parameter information.
#>
function New-ParsedHelpValueCompletionResult
{
	[CmdletBinding(SupportsShouldProcess)]
	[OutputType([System.Management.Automation.CompletionResult])]
	param (
		# The value to create a completion result for.
		[Parameter(ValueFromPipeline)]
		[string]$ParamValue,

		# Represents the data to paste prior to the accepted completion result.
		# This may for instance be the parameter name followed by '='
		[Parameter()]
		[string]$ResultPrefix
	)

	process {
		if ($PSCmdlet.ShouldProcess("New $($ParamInfo.Param) CompletionResult")) {
			[System.Management.Automation.CompletionResult]::new(
				"$ResultPrefix$ParamValue",
				$ParamValue,
				"ParameterValue",
				'Enumerated Parameter Value')
		}
	}
}

<#
.DESCRIPTION
	Parses the provided help data for accepted values for previously specified
	parameter in the command line's AST.
#>
function Get-ParsedHelpParamValue
{
	[CmdletBinding()]
	param (
		# Help line(s) to parse for parameter values.
		[Parameter(ValueFromPipeline)]
		[string]$HelpLine,

		# The word to complete for tab-completion.
		[Parameter()]
		[string]$WordToComplete,

		# The command abstract syntax tree used to extract the previous token
		# in order to resolve the parameter name context.
		[Parameter()]
		[object]$CommandAst,

		# Where the cursor is positioned in the $WordToComplete.
		[Parameter()]
		[int]$CursorPosition,

		# To be set when the word to complete contains the equals symbol.
		# This indicates that the parameter value completion exists in the same
		# token as the parameter name.
		[Parameter()]
		[switch]$ParamValueAssignment,

		# Reference which will be updated with the appropriate string to be passed
		# into New-ParsedHelpValueCompletionResult.
		[Parameter()]
		[ref]$ResultPrefix
	)

	begin {
		if ($ParamValueAssignment) {
			$paramElems = $WordToComplete.Split('=')
			$paramName = $paramElems[0]
			$paramValue = $paramElems[-1]
			if ($null -ne $ResultPrefix) {
				$ResultPrefix.Value = "$paramName="
			}
		} else {
			$paramName = Get-ParsedHelpPrevParam -CommandAst $CommandAst -CursorPosition $CursorPosition
			$paramValue = $wordToComplete
			if ($null -ne $ResultPrefix) {
				$ResultPrefix.Value = ""
			}
		}
	}

	process {
		if ($paramName.Contains('=')) { return }

		$HelpLine |
			Get-ParsedHelpParam |
			Where-Object { ($_.Param -match "^$paramName=?$") -and ($_.Values.Count -gt 0) } |
			ForEach-Object { $_.Values } |
			Where-Object { $_ -like "$paramValue*" }
	}
}
