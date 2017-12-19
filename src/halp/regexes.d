

module halp.regexes;

import std.regex;

/// Regex matching a (regular, non file) block definition.
public auto blockDefinitionRegex =
    ctRegex!(`^\s*⟨\s*` ~ blockName ~ `\s*⟩\s*` ~ blockDefinitionOperators ~ `\s*$`);

unittest
{
    // Normal case
    auto matches = "⟨Program that does stuff⟩ =".matchFirst(blockDefinitionRegex);
    assert(!matches.empty);
    assert(matches["blockName"] == "Program that does stuff");
    assert(matches["blockDefOp"] == "=");

    // No space before the `=` is OK
    matches = "⟨S'mth'ng⟩=".matchFirst(blockDefinitionRegex);
    assert(!matches.empty);
    assert(matches["blockName"] == "S'mth'ng");
    assert(matches["blockDefOp"] == "=");

    // Additional spaces are ignored
    matches = "  ⟨   Program that does stuff   ⟩  =     ".matchFirst(blockDefinitionRegex);
    assert(!matches.empty);
    assert(matches["blockName"] == "Program that does stuff");
    assert(matches["blockDefOp"] == "=");

    // Appending, clean case
    matches = "⟨Exit cleanly⟩ +=".matchFirst(blockDefinitionRegex);
    assert(!matches.empty);
    assert(matches["blockName"] == "Exit cleanly");
    assert(matches["blockDefOp"] == "+=");

    // Appending, with some extra spacing here and there
    matches = "⟨ Compute the GCD of `m` and `n`   ⟩+=".matchFirst(blockDefinitionRegex);
    assert(!matches.empty);
    assert(matches["blockName"] == "Compute the GCD of `m` and `n`");
    assert(matches["blockDefOp"] == "+=");

    // Missing brackets
    matches = "Stuff⟩+=".matchFirst(blockDefinitionRegex);
    assert(matches.empty);

    matches = "⟨Stuff =".matchFirst(blockDefinitionRegex);
    assert(matches.empty);

    matches = "Stuff =".matchFirst(blockDefinitionRegex);
    assert(matches.empty);

    // Missing or invalid operator
    matches = "⟨Stuff⟩ ".matchFirst(blockDefinitionRegex);
    assert(matches.empty);

    matches = "⟨Stuff⟩ ++".matchFirst(blockDefinitionRegex);
    assert(matches.empty);

    matches = "⟨Stuff⟩++".matchFirst(blockDefinitionRegex);
    assert(matches.empty);

    matches = "⟨Stuff⟩+==".matchFirst(blockDefinitionRegex);
    assert(matches.empty);

    matches = "⟨Stuff⟩+=+".matchFirst(blockDefinitionRegex);
    assert(matches.empty);
}

/// Regex matching a file block.
public auto fileDefinitionRegex =
    ctRegex!(`^\s*⟨\s*` ~ filePath ~ `\s*⟩\s*` ~ blockDefinitionOperators ~ `\s*$`);

unittest
{
    // Normal case
    auto matches = "⟨file:foo.ext⟩ =".matchFirst(fileDefinitionRegex);
    assert(!matches.empty);
    assert(matches["fileName"] == "foo.ext");
    assert(matches["blockDefOp"] == "=");

    // Appending, more complex path
    matches = "⟨file:../dir/foo.ext⟩ +=".matchFirst(fileDefinitionRegex);
    assert(!matches.empty);
    assert(matches["fileName"] == "../dir/foo.ext");
    assert(matches["blockDefOp"] == "+=");

    // Going wild with spaces
    matches = " ⟨   file:   ../dir/foo.ext  ⟩   = ".matchFirst(fileDefinitionRegex);
    assert(!matches.empty);
    assert(matches["fileName"] == "../dir/foo.ext");
    assert(matches["blockDefOp"] == "=");
}

/// Regex matching a Markdown opening code block.
public auto mdCodeBlockOpenRegex = ctRegex!("^\\s*```.*$");

unittest
{
    auto matches = "```".matchFirst(mdCodeBlockOpenRegex);
    assert(!matches.empty);

    matches = "  ```lang  ".matchFirst(mdCodeBlockOpenRegex);
    assert(!matches.empty);

    matches = "``".matchFirst(mdCodeBlockOpenRegex);
    assert(matches.empty);
}

/// Regex matching a Markdown closing code block.
public auto mdCodeBlockCloseRegex = ctRegex!("^(?P<extraCode>.*)```$");

unittest
{
    // This is the usual case
    auto matches = "```".matchFirst(mdCodeBlockCloseRegex);
    assert(!matches.empty);
    assert(matches["extraCode"] == "");

    // Some code before ``` is ugly but valid
    matches = "blah```".matchFirst(mdCodeBlockCloseRegex);
    assert(!matches.empty);
    assert(matches["extraCode"] == "blah");

    // Even backticks are valid before the triple backticks
    matches = "blah````".matchFirst(mdCodeBlockCloseRegex);
    assert(!matches.empty);
    assert(matches["extraCode"] == "blah`");

    matches = "`````".matchFirst(mdCodeBlockCloseRegex);
    assert(!matches.empty);
    assert(matches["extraCode"] == "``");

    // Some invalid cases
    matches = "``".matchFirst(mdCodeBlockCloseRegex);
    assert(matches.empty);

    matches = "```stuff after".matchFirst(mdCodeBlockCloseRegex);
    assert(matches.empty);
}

/// Regex matching a block reference.
public auto blockReferenceRegex =
    ctRegex!(`^(?P<prefixCode>[^⟨]*)⟨\s*` ~ blockName ~`\s*⟩(?P<postfixCode>.*)$`);

unittest
{
    // Simple case
    auto matches = "⟨Do stuff⟩".matchFirst(blockReferenceRegex);
    assert(!matches.empty);
    assert(matches["prefixCode"] == "");
    assert(matches["postfixCode"] == "");
    assert(matches["blockName"] == "Do stuff");

    // Indented case (perhaps the typical one)
    matches = "    ⟨Do stuff⟩".matchFirst(blockReferenceRegex);
    assert(!matches.empty);
    assert(matches["prefixCode"] == "    ");
    assert(matches["postfixCode"] == "");
    assert(matches["blockName"] == "Do stuff");

    // Both prefix and postfix
    matches = "    <li>⟨List items⟩</li>".matchFirst(blockReferenceRegex);
    assert(!matches.empty);
    assert(matches["prefixCode"] == "    <li>");
    assert(matches["postfixCode"] == "</li>");
    assert(matches["blockName"] == "List items");
}


// Building blocks for the public regexes

private enum validFileNameChars = `[a-zA-Z0-9 _./]`;
private enum validFileNameCharsButNotSpace = `[a-zA-Z0-9_./]`;
private enum filePath = `file:\s*(?P<fileName>` ~ validFileNameChars ~ `*` ~ validFileNameCharsButNotSpace ~`)\s*`;

unittest
{
    auto re = ctRegex!("^" ~ filePath ~ "$");

    // Just a file name
    auto matches = "file:file.ext".matchFirst(re);
    assert(!matches.empty);
    assert(matches["fileName"] == "file.ext");

    // File name and path
    matches = "file:foo/bar.ext".matchFirst(re);
    assert(!matches.empty);
    assert(matches["fileName"] == "foo/bar.ext");

    // Spaces and dots and relative paths are OK
    matches = "file:../path with spaces/file.with.dotted.name".matchFirst(re);
    assert(!matches.empty);
    assert(matches["fileName"] == "../path with spaces/file.with.dotted.name");

    // Missing initial "file:"
    matches = "file.ext".matchFirst(re);
    assert(matches.empty);

    matches = "fil:file.ext".matchFirst(re);
    assert(matches.empty);

    matches = "files:file.ext".matchFirst(re);
    assert(matches.empty);

    // Missing file name
    matches = "file:".matchFirst(re);
    assert(matches.empty);

    // Invalid characters
    matches = "file:file*ext".matchFirst(re);
    assert(matches.empty);

    matches = "file:file,ext".matchFirst(re);
    assert(matches.empty);

    matches = "file:file!ext".matchFirst(re);
    assert(matches.empty);

    matches = "file:file?ext".matchFirst(re);
    assert(matches.empty);

    matches = "file:file:ext".matchFirst(re);
    assert(matches.empty);
}

private enum validBlockNameChars = `[\w\s\p{Ps}\p{Pc}\p{Pd}\p{pE}\p{Pi}\p{Pf}\p{Po}\p{Sm}\p{Sc}\p{Sk}\p{So}--⟨⟩…]`;
private enum validBlockNameCharsButNotSpaces = `[\w\p{Ps}\p{Pc}\p{Pd}\p{pE}\p{Pi}\p{Pf}\p{Po}\p{Sm}\p{Sc}\p{Sk}\p{So}--⟨⟩…]`;
private enum blockName = `(?P<blockName>` ~ validBlockNameChars ~ `*` ~ validBlockNameCharsButNotSpaces ~ `)`;

unittest
{
    auto re = ctRegex!("^" ~ blockName ~ "$");

    // One-word name
    auto input = "doStuff";
    auto matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches["blockName"] == input);

    // Underscores are OK
    input = "do_stuff";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches["blockName"] == input);

    // Sentence-like name
    input = "Do stuff until end of file. Or maybe not.";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches["blockName"] == input);

    // Funny characters
    input = `Aproximate π. Ou, em (mal) "português": âprôxímã pí! ‘N'est pas?’`;
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches["blockName"] == input);

    // More funny characters
    input = `$+÷×¥€→∀`;
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches["blockName"] == input);

    // Block name cannot be empty
    matches = ``.matchFirst(re);
    assert(matches.empty);

    // Angle brackets are not acceptable
    matches = `⟩`.matchFirst(re);
    assert(matches.empty);

    matches = `⟨`.matchFirst(re);
    assert(matches.empty);

    matches = `⟨⟩`.matchFirst(re);
    assert(matches.empty);

    matches = `⟨foo`.matchFirst(re);
    assert(matches.empty);

    matches = `foo⟩`.matchFirst(re);
    assert(matches.empty);

    matches = `⟨foo⟩`.matchFirst(re);
    assert(matches.empty);

    // Ellipsis are reserved :-)
    matches = `…`.matchFirst(re);
    assert(matches.empty);
}

enum blockDefinitionOperators = `(?P<blockDefOp>[+]?=)`;

unittest
{
    auto re = ctRegex!("^" ~ blockDefinitionOperators ~ "$");

    // Valid operators
    auto input = "=";
    auto matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches["blockDefOp"] == input);

    input = "+=";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches["blockDefOp"] == input);

    // Some invalid things
    input = "";
    matches = input.matchFirst(re);
    assert(matches.empty);

    input = "=+";
    matches = input.matchFirst(re);
    assert(matches.empty);

    input = "+=+";
    matches = input.matchFirst(re);
    assert(matches.empty);

    input = "+";
    matches = input.matchFirst(re);
    assert(matches.empty);

    input = "obviously invalid";
    matches = input.matchFirst(re);
    assert(matches.empty);
}
