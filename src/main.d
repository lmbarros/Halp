import std.conv;
import std.stdio;
import std.regex;
import halp.regexes;

struct Block
{
    string fileName;
    string name;
    string contents;
}

void die(string fileName, int line, string msg)
{
	import core.stdc.stdlib: exit;
	stderr.writefln("%s:%s: %s", fileName, line, msg);
	exit(1);
}

Block[] readBlocks(string fileName)
{
    enum
    {
        readingProse,
        justReadBlockDefinition,
        readingBlockContents,
    }

    auto state = readingProse;

    Block[] blocks = [];
    Block block;

    auto file = File(fileName, "r");

	auto lineNumber = 0;
	auto openBlockLineNumber = 0;

    foreach (line; file.byLine())
    {
		++lineNumber;

        final switch(state)
        {
            case readingProse:
				auto matches = line.matchFirst(fileDefinitionRegex);
				if (!matches.empty)
				{
					block.fileName = to!string(matches["fileName"]);
					state = justReadBlockDefinition;
					break;
				}

                matches = line.matchFirst(blockDefinitionRegex);
                if (!matches.empty)
                {
                    block.name = to!string(matches["blockName"]);
                    state = justReadBlockDefinition;
                    break;
                }

				break;

            case justReadBlockDefinition:
				auto matches = line.matchFirst(mdCodeBlockOpenRegex);
				if (matches.empty)
					die(fileName, lineNumber, "Expected Markdown code block (```)");
				state = readingBlockContents;
				openBlockLineNumber = lineNumber;
				break;

            case readingBlockContents:
				auto matches = line.matchFirst(mdCodeBlockCloseRegex);
				if (!matches.empty)
				{
					if (matches["extraCode"].length > 0)
						block.contents ~= matches["extraCode"] ~ "\n";
					state = readingProse;
					blocks ~= block;
					block = Block();
				}
				else
				{
					block.contents ~= line ~ "\n";
				}
				break;
        }
    }

	if (state == readingBlockContents)
		die(fileName, lineNumber, "Code block opened at line " ~ to!string(openBlockLineNumber) ~ " is never closed.");

    return blocks;
}


void main()
{
    writeln("Halp: An Ad Hoc Literate Programming Tool");

    auto blocks = readBlocks("test.md");

	writefln("Read %s blocks:", blocks.length);
	foreach (block; blocks)
	{
		writefln("    Name: %s", block.name);
		writefln("    File name: %s", block.fileName);
		writefln("    Contents: %s", block.contents);
		writeln("--------------------\n\n");
	}
}
