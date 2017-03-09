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

    Test.add_func ("/toml-glib/serialize", () => {
        try {
            var test = new SerializationTester ();
            var toml = Toml.Serialization.serialize (test);
            assert_true (toml["name"].as<string> () == test.name);
            assert_true (toml["age"].as<int> () == test.age);
            assert_true (toml["date-of-birth"].as<DateTime> () == test.date_of_birth);
            assert_true (toml["hello"]["description"].as<string> () == test.hello.description);
        } catch (Error err) {
            print ("ERROR: %s\n", err.message);
            Test.fail ();
        }
    });

    Test.add_func ("/toml-glib/deserialize", () => {
        try {
            var doc = new Parser ("""
name = "Henry"
age = 13
date-of-birth = 1975-05-07T08:34:45

[hello]
description = "Something really cool"
""").parse ();
            var test = Toml.Serialization.deserialize<SerializationTester> (doc);
            assert_true (doc["name"].as<string> () == test.name);
            assert_true (doc["age"].as<int> () == test.age);
            assert_true (doc["date-of-birth"].as<DateTime> () == test.date_of_birth);
            assert_true (doc["hello"]["description"].as<string> () == test.hello.description);
        } catch (Error err) {
            print ("ERROR: %s\n", err.message);
            Test.fail ();
        }
    });

    Test.run ();
}

class SerializationTester : Object {

    public string name { get; set; default = "John Doe"; }

    public int age { get; set; default = 42; }

    public DateTime date_of_birth { get; set; default = new DateTime.now_local (); }

    public Thing hello { get; set; default = new Thing (); }
}

class Thing : Object {

    public string description { get; set; default = "Big, blue and smooth."; }
}
