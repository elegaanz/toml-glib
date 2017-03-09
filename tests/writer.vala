using Toml;

void test_writer () {
    Test.add_func ("/toml-glib/writer/write", () => {
        try {
            string toml = """a = 42

[table]
foo = "bar"
inline = {
  foo = "bar",
  hey = 42,
  is = true
}

[[array]]
inner-inline = [
  'â',
  'ê',
  'î',
  'ô',
  'û',
  'ŷ'
]
bar = "baz"

""";
            var doc = new Parser (toml).parse ();
            assert (new Writer ().write (doc) == toml);
        } catch (Error err) {
            print ("Error: %s\n", err.message);
        }
    });
}
