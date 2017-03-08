namespace Toml {

    /**
    * A delegate for token generators.
    *
    * A token generator is a function that generates a token.
    * It is called when a specific {@link GLib.Regex} is matched.
    *
    * @see Toml.Evaluator
    */
    public delegate Token TokenGenerator (string toml) throws TomlError;

    /**
    * Represents an evaluator.
    *
    * It is an element of the grammar. It consists in one {@link GLib.Regex}
    * and a function to generate a token if this regex a part of the TOML document.
    *
    * It also has some properties to manipulate the stack of the {@link Toml.Lexer}.
    *
    * @see Toml.Grammar
    * @see Toml.Lexer
    */
    public class Evaluator : Object {

        public TokenGenerator generator { get; owned set; }

        public string[]? push { get; set; }

        public bool pop { get; set; }

        public Regex pattern { get; set; }

        public Evaluator (Regex re, owned TokenGenerator gen, bool pop = false, string[]? push = null) {
            this.generator = (owned) gen;
            this.pattern = re;
            this.push = push;
            this.pop = pop;
        }

        public int evaluate (string toml, out Token? tok) throws TomlError {
            MatchInfo info;
            if (this.pattern.match (toml, RegexMatchFlags.ANCHORED, out info)) {
                string match = info.fetch (0);
                tok = this.generator (match);
                return match.length;
            }

            tok = null;
            return 0;
        }
    }
}
