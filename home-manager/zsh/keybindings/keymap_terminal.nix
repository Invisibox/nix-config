{ terminalKeySequencesAttrSet, lib }:

let
  writeKeyAndSequence = keyName: sequence: "  ${keyName}  '${sequence}'";

  # pre-escape the only apostrophe char
  escapedTerminalKeySequencesAttrSet =
    terminalKeySequencesAttrSet // { a-apostrophe = "^[\\x27"; };

  terminalKeySequencesLines =
    builtins.concatStringsSep "\n"
      ( lib.attrsets.mapAttrsToList
          writeKeyAndSequence
          escapedTerminalKeySequencesAttrSet
      );
in

''
typeset -gA terminal_key_sequences=(
${terminalKeySequencesLines}
)
''
