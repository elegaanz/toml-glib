using Toml;
using Gee;

void test_parser () {
    Test.add_func ("/toml-glib/parser", () => {
        parse ("# Foo");
    });

    Test.add_func ("/toml-glib/parser/int", () => {
        try {
            string toml = """a = 12""";
            var doc = parse (toml);
            assert (doc["a"].as<int> () == 12);
        } catch (Error err) {
            assert_not_reached ();
        }
    });

    Test.add_func ("/toml-glib/parser/bool", () => {
        try {
            var doc = parse ("a = true\nb = false");
            assert (doc["a"].as<bool> () == true);
            assert (doc["b"].as<bool> () == false);
        } catch {
            assert_not_reached ();
        }
    });

    Test.add_func ("/toml-glib/parser/inline-tables", () => {
        try {
            var doc = parse ("a = { foo = 42, bar = { hey = \"hello\", paf = 2.478 } }");
            assert (doc["a"].value_type == typeof (Object));
            assert (doc["a"]["foo"].as<int> () == 42);
            assert (doc["a"]["bar"]["hey"].as<string> () == "hello");
        } catch (Error err) {
            print ("[ERROR] %s\n", err.message);
            Test.fail ();
        }
    });

    Test.add_func ("/toml-glib/parser/file", () => {
        try {
            Parser p = new Parser.from_path ("test.toml");
            var root = p.parse ();
            assert (root["title"].as<string> () == "TOML Example");
            assert (root["people"].as<ArrayList<Element>> ().size == 2);
            assert (root["people"].as<ArrayList<Element>> ()[0]["name"].as<string> () == "John Doe");
        } catch (Error err) {
            print ("[ERROR] %s\n", err.message);
            Test.fail ();
        }
    });

    Test.add_func ("/toml-glib/parser/whole-spec", () => {
        try {
            Parser p = new Parser.from_path ("all.toml");
            p.parse ();
        } catch (Error err) {
            print ("[ERROR] %s\n", err.message);
            Test.fail ();
        }
    });
}

// Safe parsing
Element? parse (string toml) {
    try {
        return new Parser (toml).parse ();
    } catch (Error err) {
        Test.fail ();
        print ("\n" + err.message + "\n");
    }
    return null;
}
