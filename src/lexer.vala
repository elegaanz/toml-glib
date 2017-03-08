using Gee;

namespace Toml {

    public class Lexer : Object {

        public string toml { get; set; }

        public Grammar grammar { get; set; }

        public Lexer (string toml, Grammar grm = new Grammar ()) {
            this.toml = toml;
            this.grammar = grm;
        }

        public ArrayList<Token> lex () throws TomlError, Error {
            string _toml = this.toml;

            ArrayList<string> stack = new ArrayList<string> ();
            ArrayList<Token> tokens = new ArrayList<Token> ();

            stack.add ("root");

            int line = 1;
            int col = 0;
            while (_toml.length > 0) {
                bool matched = false;
                foreach (var evaluator in this.grammar.rules[stack.last ()]) {
                    try {
                        Token? tok;
                        var size = evaluator.evaluate (_toml, out tok);
                        if (size > 0) {

                            // Adding the token if needed (e.g. not just blank)
                            if (tok != null) {
                                if (tok.category == Category.LINE_BREAK || (tok.category == Category.CHAR && tok.lexeme.has_prefix ("\n"))) {
                                    line++;
                                    col = 0;
                                } else {
                                    col += size;
                                    if (tok.category != Category.WHITESPACE) {
                                        tok.line = line;
                                        tok.column = col;
                                        tokens.add (tok);
                                    }
                                }
                            } else {
                                assert_not_reached ();
                            }

                            if (evaluator.pop) {
                                stack.remove (stack.last ());
                            }

                            if (evaluator.push != null) {
                                stack.add_all (new ArrayList<string>.wrap (evaluator.push));
                            }

                            matched = true;
                            _toml = _toml.substring (size);
                            break;
                        }
                    } catch (Error err) {
                        throw err;
                    }
                }

                if (!matched) {
                    throw new TomlError.SYNTAX_ERROR (@"Invalid TOML at line $line, column $col. ($(stack.last ()), $(_toml[0:10]), $(tokens.last ().lexeme))");
                }
            }

            tokens.add (new Token ("", Category.EOF) { line = line, column = col + 1 });
            return tokens;
        }
    }
}
