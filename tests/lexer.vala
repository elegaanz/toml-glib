using Toml;
using Gee;

/**
* Tests for the lexer
*/
void test_lexer () {
    Test.add_func ("/toml-glib/lexer/comment", () => {
        const string toml =
"""# Hello, world!
   # Foo (with spaces before)
bar = 12 # Wahou, such end of line""";

        check (toml, {
            new Token ("#", Category.HASH),
            new Token (" Hello, world!", Category.COMMENT),
            new Token ("#", Category.HASH),
            new Token (" Foo (with spaces before)", Category.COMMENT),
            null,
            null,
            null,
            new Token ("#", Category.HASH),
            new Token (" Wahou, such end of line", Category.COMMENT),
        });
    });

    Test.add_func ("/toml-glib/lexer/bare-key", () => {
        check ("foo", {
            new Token ("foo", Category.IDENTIFIER)
        });
    });

    Test.add_func ("/toml-glib/lexer/double-values", () => {
        const string toml = """
        bar = 78.6
        light = 3.00E8
        """;
        check (toml, {
            null, null,
            new Token ("78.6", Category.DOUBLE),
            null, null,
            new Token ("3.00E8", Category.DOUBLE)
        });
    });

    Test.add_func ("/toml-glib/lexer/inline-table", () => {
        check ("foo = { bar = 42 }", {
            null,
            null,
            new Token ("{", Category.LEFT_BRACE),
            new Token ("bar", Category.IDENTIFIER),
            null,
            new Token ("42", Category.INT),
            new Token ("}", Category.RIGHT_BRACE)
        });
    });

    Test.add_func ("/toml-glib/lexer/nested-inline-table", () => {
        const string toml = "foo = { bar = { baz = 42 } }";
        var toks = lex (toml);
        assert (toks[0].category == Category.IDENTIFIER);
        assert (toks[0].lexeme == "foo");
        assert (toks[2].category == Category.LEFT_BRACE);
        assert (toks[10].category == Category.RIGHT_BRACE);
    });
}

private void check (string toml, Token?[] expected) {
    var toks = lex (toml);
    int i = 0;
    foreach (var tok in toks) {
        if (i >= expected.length || expected[i] == null) {
            i++;
            continue;
        }

        if (tok.category != expected[i].category || tok.lexeme != expected[i].lexeme) {
            print ("Expected :\n  - %s\n  - %s\nGot :\n  - %s\n  - %s\n",
                expected[i].lexeme, expected[i].category.to_string (), tok.lexeme, tok.category.to_string ());
            Test.fail ();
        }
        i++;
    }
}

private ArrayList<Token> lex (string toml) {
    try {
        Lexer lex = new Lexer (toml);
        return lex.lex ();
    } catch (Error err) {
        print ("\n" + err.message + "\n\n");
        Test.fail ();
    }
    return new ArrayList<Token> ();
}
