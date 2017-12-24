import core.stdc.stdlib: exit;
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
    stderr.writefln("%s:%s: %s", fileName, line, msg);
    exit(1);
}

void die(string msg)
{
    stderr.writeln(msg);
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

void expandBlocks(Block[] blocks)
{
    Block findBlock(string name)
    {
        foreach (block; blocks)
        {
            if (block.name == name)
                return block;
        }

        die("Block not found: " ~ name);
        assert(false, "Can't happen");
    }

    // This looks very inefficient
    void expandBlock(Block block)
    {
        auto expandedSomething = false;

        while (true)
        {
            string newContents;
            import std.string: lineSplitter;

            expandedSomething = false;

            foreach (line; lineSplitter(block.contents))
            {
                auto matches = line.matchFirst(blockReferenceRegex);
                if (matches.empty)
                {
                    newContents ~= line ~ "\n";
                }
                else // expand
                {
                    expandedSomething = true;
                    auto newBlock = findBlock(matches["blockName"]);
                    auto prefix = to!string(matches["prefixCode"]);
                    auto postfix = to!string(matches["postfixCode"]);

                    foreach (expLine; lineSplitter(newBlock.contents))
                        newContents ~= prefix ~ expLine ~ postfix ~ "\n";
                }
            }

            block.contents = newContents;

            if (!expandedSomething)
                break;
        }
    }

    foreach (block; blocks)
    {
        if (block.fileName != "")
            expandBlock(block);
    }
}

void writeFiles(Block[] blocks, string root)
{
    import std.file;
    import std.path;

    void writeFile(Block block)
    {
        assert(block.fileName != "", "This should be a file block");
        auto file = File(buildPath(root, block.fileName), "w");
        file.write(block.contents);
    }

    mkdirRecurse(root);

    foreach (block; blocks)
    {
        if (block.fileName != "")
            writeFile(block);
    }

}

void main(string[] args)
{
    import std.getopt;

    writeln("");

    string targetDir = "generated_sources";

    auto helpInformation = getopt(
        args,
        "targetDir", "Root directory for the generated files", &targetDir);

    if (args.length < 2 || helpInformation.helpWanted)
    {
        defaultGetoptPrinter("Halp: An Ad Hoc Literate Programming Tool\n"
            ~ "Usage: halp [options] <input files...>\n",
            helpInformation.options);
        exit(1);
    }

    Block[] blocks = [];

    for (auto i = 1; i < args.length; ++i)
        blocks ~= readBlocks(args[i]);

    expandBlocks(blocks);

    writeFiles(blocks, targetDir);
}
