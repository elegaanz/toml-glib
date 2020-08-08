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
valac --pkg toml-glib *.vala
```

You should get this:

```
Hello, world!
```

## Building and Installation

You'll need the following dependencies:

* libgee-0.8-dev
* libglib2.0-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
