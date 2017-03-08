using Gee;

namespace Toml {

    public class Grammar : Object {

        public HashMap<string, ArrayList<Evaluator>> rules { get; set; }

        public Grammar () {
            this.rules = new HashMap<string, ArrayList<Evaluator>> ();
            this.rules["comment"] =                  this.comment_evaluators ();
            this.rules["string"] =                   this.string_evaluators ();
            this.rules["literal-string"] =           this.literal_string_evaluators ();
            this.rules["multiline-string"] =         this.multiline_string_evaluators ();
            this.rules["multiline-literal-string"] = this.multiline_string_literal_evaluators ();
            this.rules["root"] =                     this.root_evaluators ();
        }

        private ArrayList<Evaluator> comment_evaluators () {
            return new ArrayList<Evaluator>.wrap ({
                new Evaluator (/[\r\n]/, token (Category.LINE_BREAK), true),
                new Evaluator (/.*/, token (Category.COMMENT), true)
            });
        }

        private ArrayList<Evaluator> string_evaluators () {
            return new ArrayList<Evaluator>.wrap ({
                new Evaluator (re ("\""), token (Category.DOUBLE_QUOTE), true),
                new Evaluator (re ("([\\x{0020}-\\x{0021}\\x{0023}-\\x{005B}\\x{005D}-\\x{FFFF}]|\\\\(\"|\\\\|t|n|b|f|r|u[A-Z0-9]{4}))"), token (Category.CHAR))
            });
        }

        private ArrayList<Evaluator> literal_string_evaluators () {
            return new ArrayList<Evaluator>.wrap ({
                new Evaluator (re ("'"), token (Category.SINGLE_QUOTE), true),
                new Evaluator (re ("([\\x{0020}-\\x{0026}\\x{0028}-\\x{FFFF}])+"), token (Category.CHAR))
            });
        }

        private bool trim_next_line;
        private ArrayList<Evaluator> multiline_string_evaluators () {
            var valid_unicode = "\\x{0020}-\\x{0021}\\x{0023}-\\x{FFFF}";
            return new ArrayList<Evaluator>.wrap ({
                new Evaluator (re ("\"\"\""), token (Category.TRIPLE_DOUBLE_QUOTE), true),

                new Evaluator (re ("([\n" + valid_unicode + "]\"?\"?)*[\n" + valid_unicode + "]", RegexCompileFlags.DOTALL),
                    (_m) => {
                        var m = _m;
                        if (this.trim_next_line) {
                            m = m.strip ();
                        }
                        this.trim_next_line = m.has_suffix ("\\");
                        return new Token (strip_line_continuations (m).compress (), Category.CHAR);
                    })
            });
        }

        private ArrayList<Evaluator> multiline_string_literal_evaluators () {
            var valid_unicode = "\n\\x{0020}-\\x{0026}\\x{0028}-\\x{FFFF}";
            return new ArrayList<Evaluator>.wrap ({
                new Evaluator (re ("'''"), token (Category.TRIPLE_SINGLE_QUOTE), true),
                new Evaluator (re ("([" + valid_unicode + "]'?'?)*[" + valid_unicode + "]+", RegexCompileFlags.DOTALL),
                    (m) => { return new Token (m.strip (), Category.CHAR); })
            });
        }

        /**
        * Evaluators for the document
        */
        private ArrayList<Evaluator> root_evaluators () {
            var date_time = "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}";

            return new ArrayList<Evaluator>.wrap ({
                new Evaluator (/#/, token (Category.HASH), false, {"comment"}),
                new Evaluator (/[ \t]+/, token (Category.WHITESPACE)),
                new Evaluator (/[\r\n]/, token (Category.LINE_BREAK)),

                new Evaluator (/\[/, token (Category.LEFT_SQUARE_BRACE)),
                new Evaluator (/\]/, token (Category.RIGHT_SQUARE_BRACE)),
                new Evaluator (/{/, token (Category.LEFT_BRACE)),
                new Evaluator (/}/, token (Category.RIGHT_BRACE)),

                new Evaluator (/\./, token (Category.DOT)),
                new Evaluator (/,/, token (Category.COMMA)),
                new Evaluator (/=/, token (Category.EQUAL)),

                new Evaluator (/true|false/, token (Category.BOOLEAN)),

                // Dates, RFC 3339
                new Evaluator (re (date_time + "(\\.\\d+)?(Z|z|[\\-\\+]\\d{2}:\\d{2})?"), token (Category.DATE_TIME)),
                // Simple Date
                new Evaluator (re ("\\d{4}-\\d{2}-\\d{2}"), token (Category.DATE)),

                new Evaluator (re ("\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?"), token (Category.TIME)),

                // Double with exponent
                new Evaluator (/[-\+]?[0-9]+(\.[0-9]+)?[eE][-\+]?[0-9]+/, token (Category.DOUBLE)),
                // Double without exponent
                new Evaluator (/[-\+]?[0-9_]+\.[0-9_]+/, token (Category.DOUBLE)),

                // Integers
                new Evaluator (/[-\+]?[0-9_]+/, (m) => {
                    return new Token (m, Category.INT);
                }),

                // Strings
                new Evaluator (re ("\"\"\""), token (Category.TRIPLE_DOUBLE_QUOTE), false, {"multiline-string"}),
                new Evaluator (re ("'''"), token (Category.TRIPLE_SINGLE_QUOTE), false, {"multiline-literal-string"}),
                new Evaluator (re ("\""), token (Category.DOUBLE_QUOTE), false, {"string"}),
                new Evaluator (re ("'"), token (Category.SINGLE_QUOTE), false, {"literal-string"}),

                // Identifiers
                new Evaluator (/[\w_-]+/, token (Category.IDENTIFIER))
            });
        }

        private TokenGenerator token (Category cat) {
            return (m) => {
                return new Token (m, cat);
            };
        }

        /**
        * Safe way to create Regex from string.
        */
        private Regex re (string pattern, RegexCompileFlags comp = 0) {
            try {
                return new Regex (pattern, comp);
            } catch {
                assert_not_reached ();
            }
        }
    }
}
