import std.conv;
import std.stdio;
import std.regex;
import halp.regexes;

class Block
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
    Block[] blocks = [];

    // Talk about a bad interface...
    Block createOrGetBlock(string op, string blockName, string fileName)
    {
        if (blockName != "")
        {
            foreach(block; blocks)
            {
                if (block.name == blockName)
                {
                    if (op == "=")
                        block.contents = "";
                    return block;
                }
            }

            auto block = new Block();
            block.name = blockName;
            blocks ~= block;
            return block;
        }
        else if (fileName != "")
        {
            foreach(block; blocks)
            {
                if (block.fileName == fileName)
                {
                    if (op == "=")
                        block.contents = "";
                    return block;
                }
            }

            auto block = new Block();
            block.fileName = fileName;
            blocks ~= block;
            return block;
        }
        else
        {
            assert(false, "Must pass either the block or file name.");
        }
    }

    enum
    {
        readingProse,
        justReadBlockDefinition,
        readingBlockContents,
    }

    auto state = readingProse;

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
                    auto blockFileName = to!string(matches["fileName"]);
                    auto op = to!string(matches["blockDefOp"]);
                    block = createOrGetBlock(op, "", blockFileName);
                    state = justReadBlockDefinition;
                    break;
                }

                matches = line.matchFirst(blockDefinitionRegex);
                if (!matches.empty)
                {
                    auto blockName = to!string(matches["blockName"]);
                    auto op = to!string(matches["blockDefOp"]);
                    block = createOrGetBlock(op, blockName, "");
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
                }
                else
                {
                    block.contents ~= line ~ "\n";
                }
                break;
        }
    }

    // TODO: Improve this: look for block definitions while reading code blocks;
    //       report error if one is found. (Not foolproof, but good enough.)
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
        writeln("    Contents:");
        writeln("--------------------");
        writeln(block.contents);
        writeln("--------------------\n");
    }
}
