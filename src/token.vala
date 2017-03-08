using Gee;

namespace Toml {

    /**
    * Represents a Toml token.
    *
    * It is a couple of a lexeme (the representation in the document)
    * and a category (what does this token corresponds to).
    */
    public class Token : Object {

        /**
        * Creates a new {@link Toml.Token}.
        *
        * @param lex The lexeme of this token
        * @param cat The category of this token.
        */
        public Token (string lex, Category? cat) {
            this.lexeme = lex;
            this.category = cat;
        }

        /**
        * What is this token in the TOML document.
        *
        * It's not really important for things like parentheses or so, but
        * it's useful for identifiers and characters for instance.
        */
        public string lexeme { get; set; }

        /**
        * The category this token belongs to.
        */
        public Category? category { get; set; }

        /**
        * The line number of this token in the document.
        */
        public int line { get; internal set; }

        /**
        * The column number of this token in the document.
        */
        public int column { get; internal set; }
    }

}
