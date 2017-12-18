

module halp.regexes;

import std.regex;

public auto blockDefinition = ctRegex!(`[\s]*⟨` ~ blockName ~ `⟩`);


// Building blocks for the public regexes

private enum validFileNameChars = `[a-zA-Z0-9 _./]`;
private enum filePath = `(` ~ validFileNameChars ~ `+)`;

unittest
{
    auto re = ctRegex!("^" ~ filePath ~ "$");

    // Just a file name
    auto input = "file.ext";
    auto matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // File name and path
    input = "foo/bar.ext";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // Spaces and dots and relative paths are OK
    input = "../path with spaces/file.with.dotted.name";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // Invalid characters
    matches = "file*ext".matchFirst(re);
    assert(matches.empty);

    matches = "file,ext".matchFirst(re);
    assert(matches.empty);

    matches = "file!ext".matchFirst(re);
    assert(matches.empty);

    matches = "file?ext".matchFirst(re);
    assert(matches.empty);
}

private enum validBlockNameChars = `[\w\s\p{Ps}\p{Pc}\p{Pd}\p{pE}\p{Pi}\p{Pf}\p{Po}\p{Sm}\p{Sc}\p{So}--⟨⟩]`;
private enum blockName = `(` ~ validBlockNameChars ~ `+)`;

unittest
{
    auto re = ctRegex!("^" ~ blockName ~ "$");

    // One-word name
    auto input = "doStuff";
    auto matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // Underscores are OK
    input = "do_stuff";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // Sentence-like name
    input = "Do stuff until end of file. Or maybe not.";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // Funny characters
    input = `Aproximate π. Ou, em (mal) "português": âprôxímã pí! ‘N'est pas?’`;
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // More funny characters
    input = `$+÷×¥€→∀`;
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // Name cannot be empty
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
}

private enum validFlagCharacters = `[a-zA-Z0-9_]`;
private enum oneFlag = validFlagCharacters ~ `+`;
private enum flagSeparator = `[\s]*,[\s]*`;
private enum flagList = `([\s]*(?:` ~ oneFlag ~ `(?:` ~ flagSeparator ~ oneFlag ~ `)*)?[\s]*)`;

unittest
{
    auto re = ctRegex!("^" ~ flagList ~ "$");

    // Empty list
    auto input = "";
    auto matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // One flag
    input = "myFlag";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // One flag, with underscore and extra spaces
    input = "   my_flag ";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // Two flags, different variations
    input = "flag1,flag2";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    input = "flag_1, flag2";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    input = "  flag_1   , flag_2";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    input = "flag1,  flag_2   ";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // Longer list
    input = "abc, cDe,xyz   , _foo  ,BAR,_baz   ";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // Cannot start by comma
    input = ",flag";
    matches = input.matchFirst(re);
    assert(matches.empty);

    // Comma is required to separate flags
    input = "flag1 flag2";
    matches = input.matchFirst(re);
    assert(matches.empty);

    // Funny characters are invalid
    input = "flag.";
    matches = input.matchFirst(re);
    assert(matches.empty);

    input = "fla&g";
    matches = input.matchFirst(re);
    assert(matches.empty);

    input = "flég";
    matches = input.matchFirst(re);
    assert(matches.empty);
}

enum blockDefinitionOperators = `([+]?=)`;

unittest
{
    auto re = ctRegex!("^" ~ blockDefinitionOperators ~ "$");

    // Valid operators
    auto input = "=";
    auto matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    input = "+=";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

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
