

module halp.regexes;

import std.regex;

private enum validFileNameChars = `[a-zA-Z0-9 _./]`;
private enum filePath = `(/` ~ validFileNameChars ~ `+)`;

unittest
{
    auto re = ctRegex!("^" ~ filePath ~ "$");

    // Just a file name
    auto input = "/file.ext";
    auto matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // File name and path
    input = "/foo/bar.ext";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // Spaces and dots are ok
    input = "/path with spaces/file.with.dotted.name";
    matches = input.matchFirst(re);
    assert(!matches.empty);
    assert(matches[1] == input);

    // Missing initial slash
    matches = "file.ext".matchFirst(re);
    assert(matches.empty);

    matches = "foo/bar.ext".matchFirst(re);
    assert(matches.empty);

    // Invalid characters
    matches = "/file*ext".matchFirst(re);
    assert(matches.empty);

    matches = "/file,ext".matchFirst(re);
    assert(matches.empty);

    matches = "/file!ext".matchFirst(re);
    assert(matches.empty);

    matches = "/file?ext".matchFirst(re);
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
