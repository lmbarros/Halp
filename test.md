# Test

This is a test program.

## Main structure

We have to import some modules and the do stuff. All in a neat file with a neat `main()` function. Nothing really interesting.

⟨file:main.d⟩ =
```D
⟨imports⟩

void main()
{
    ⟨do stuff⟩
}
```

## Say hello

This program says hello. We need to import the proper module.

⟨imports⟩ =
```D
import std.stdio;
```

Then, we can actually say hello:

⟨do stuff⟩ =
```D
writeln("Hey you!");
```

## Say goodbye

⟨do stuff⟩ +=
```D
writeln("Goodbye. Goddbye.");
```

## Departing words

That's all folks!
