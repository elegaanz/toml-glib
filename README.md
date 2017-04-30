# TOML GLib [![Build Status](https://travis-ci.org/Bat41/toml-glib.svg?branch=master)](https://travis-ci.org/Bat41/toml-glib)

A small library to parse TOML.

## Small example

Put this in a Vala file:

```vala
using Toml;

void main () {
    try {
        Element doc = new Parser.from_file ("test.toml").parse ();
        string name = doc["visitor"]["name"].as<string> ();
        print ("Hello, %s!\n", name);
    } catch (Error err) {
        print ("Error: %s\n", err.message);
    }
}
```

Then in `test.toml`, put:

```toml
[visitor]
name = "world"
```

Compile with:

```
valac *.vala --pkg toml-glib
```

You should get this:

```
Hello, world!
```

## Building

```
mkdir build && cd build
meson ..
ninja
```
