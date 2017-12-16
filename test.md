# Test

This is a test program.

## Main structure

We have to import some modules and the do stuff. All in a neat file with a neat `main()` function. Nothing really interesting.

⟨/main.d⟩ =
```D
⟨imports⟩

void main()
{
    ⟨do stuff⟩
}
```

## Say hello

This program says hello. We need to import the proper module.

**TODO:** Consider supporting a syntax like `⟨imports⟩[uniquelines]` to make sure that imports are not imported more than once.

⟨imports⟩ =
```D
import std.stdio;
```

Then, we can actually say hello:

⟨do stuff⟩ =
```D
writefln("Hey you!");
```

## Bonus: Say goodbye

If we said hello, why not saying goodbye also?

⟨do stuff⟩ +=
```D
writefln("Goodbye!");
```