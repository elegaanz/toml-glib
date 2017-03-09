using Toml;

/**
* Test programm for TOML-GLib
*/
void main (string[] args) {
    Test.init (ref args);
    Test.set_nonfatal_assertions ();

    test_lexer ();

    test_parser ();

    test_writer ();

    Test.run ();
}
