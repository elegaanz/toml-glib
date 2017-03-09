using Gee;

namespace Toml {

    /**
    * Transforms some raw TOML into a {@link Toml.Element}.
    */
    public class Parser : Object {

        /**
        * The TOML which is going to be parsed.
        *
        * If you want to modify it, create a new parser with the correct parameters.
        *
        * @see Toml.Parser.Parser
        */
        public string toml { get; private set; }

        /**
        * The {@link Toml.Token}s of the TOML to parse.
        *
        * @see Toml.Lexer.lex
        */
        private ArrayList<Token> tokens { get; set; }

        /**
        * The root of the document being parsed.
        */
        private Element root { get; set; default = new Element.table (); }

        /**
        * The index of the current token.
        */
        private int index;

        /**
        * The current token.
        */
        private Token current {
            owned get {
                if (this.index >= this.tokens.size) {
                    print (@"[WARNING:PARSER] Tried to get the token at $index, but they are only $(tokens.size).\n");
                    print ("Giving the previous token.\n");
                    this.index--;
                    print (@"(At line $(current.line), column $(current.column))\n\n");
                }
                return this.tokens[this.index];
            }
        }

        /**
        * The next token.
        */
        private Token next {
            owned get {
                return this.tokens[this.index + 1];
            }
        }

        /**
        * Create a new parser for the TOML contained in a file.
        *
        * @param path The path to the file.
        */
        public Parser.from_path (string path) throws Error {
            try {
                string content;
                FileUtils.get_contents (path, out content);
                this (content);
            } catch (Error err) {
                throw err;
            }
        }

        /**
        * Creates a new parser for the TOML contained in a file.
        *
        * @param file The {@link GLib.File} containing the TOML to parse.
        */
        public Parser.from_file (File file) throws Error {
            try {
                this.from_path (file.get_path ());
            } catch (Error err) {
                throw err;
            }
        }

        /**
        * Creates a new Parser for some TOMl.
        */
        public Parser (string toml) {
            this.index = 0;
            this.toml = toml;
        }

        /**
        * Eats the current token.
        */
        private void eat () {
            this.index++;
        }

        /**
        * Eats the current token if it's of a certain type.
        *
        * @param cat The {@link Toml.Category} to match
        * @return true if matched
        */
        private bool accept (Category cat) {
            if (cat == this.current.category) {
                this.eat ();
                return true;
            }
            return false;
        }

        /**
        * Throws an error if the current token doesn't match a category. Just eats it otherwise.
        *
        * @param cat The category to match
        */
        private bool expect (Category cat) throws TomlError.SYNTAX_ERROR {
            if (this.accept (cat)) {
                return true;
            } else {
                throw new TomlError.SYNTAX_ERROR (@"Expected $cat, got $(this.current.category) : $(this.current.lexeme)$(this.next.lexeme) (at line $(this.current.line), column $(this.current.column))");
            }
        }

        /**
        * Throws an error because of an unexpected token.
        *
        * Use it when an unexpected token is encountered.
        */
        private void unexpected () throws TomlError {
            throw new TomlError.SYNTAX_ERROR (@"Got $(this.current.category) ($(this.current.lexeme)), which is unexpected (at line $(this.current.line), column $(this.current.column))");
        }

        /**
        * Parse the loaded TOML.
        */
        public Element parse () throws Error {
            Lexer lex = new Lexer (this.toml);
            this.tokens = lex.lex ();
            parse_table (this.root);
            while (this.current.category != Category.EOF) {
                if (this.current.category == Category.LEFT_SQUARE_BRACE) {
                    if (this.next.category == Category.LEFT_SQUARE_BRACE) {
                        this.parse_table_array_declaration ();
                    } else {
                        this.parse_table_declaration ();
                    }
                } else {
                    unexpected ();
                }
            }
            expect (Category.EOF);
            return this.root;
        }

        /**
        * Parse a TOML table.
        */
        private void parse_table (Element table) throws TomlError {
            table.inline = false;
            string comment = "";
            while (this.accept (Category.HASH)) {
                comment += this.current.lexeme;
                this.expect (Category.COMMENT);
            }
            table.comment = table.comment != null ? table.comment + "\n\n" + comment : comment;

            while (current.category == Category.IDENTIFIER ||
                    current.category == Category.INT ||
                    current.category == Category.DOUBLE_QUOTE ||
                    current.category == Category.SINGLE_QUOTE) {
                string key = this.parse_key ();
                expect (Category.EQUAL);
                table[key] = this.parse_value ();
                table[key].comment = this.get_comment ();
            }

            if (!this.accept (Category.EOF)) {
                this.expect (Category.LEFT_SQUARE_BRACE);
            }
            this.index--;
        }

        /**
        * Parse a value (string, int, float, array, inline table, etc).
        *
        * @return The parsed value.
        */
        private Element parse_value () throws TomlError {
            switch (this.current.category) {
                case Category.INT:
                    var val = new Element (int.parse (this.current.lexeme.replace ("_", "")));
                    eat ();
                    val.comment = get_comment ();
                    return val;
                case Category.DOUBLE:
                    return new Element (this.parse_double ());
                case Category.BOOLEAN:
                    var val = new Element (bool.parse (this.current.lexeme));
                    eat ();
                    val.comment = get_comment ();
                    return val;
                case Category.SINGLE_QUOTE:
                case Category.TRIPLE_SINGLE_QUOTE:
                case Category.TRIPLE_DOUBLE_QUOTE:
                case Category.DOUBLE_QUOTE:
                    var val = new Element (this.parse_string ());
                    val.comment = get_comment ();
                    return val;
                case Category.DATE_TIME:
                    var val = new Element (this.parse_date_time ());
                    val.comment = get_comment ();
                    return val;
                case Category.DATE:
                    var val = new Element (this.parse_date ());
                    val.comment = get_comment ();
                    return val;
                case Category.TIME:
                    var val = new Element (this.parse_time ());
                    val.comment = get_comment ();
                    return val;
                case Category.LEFT_SQUARE_BRACE:
                    var val = new Element.array (this.parse_array ());
                    foreach (var ch in val.children) {
                        ch.parent = val;
                    }
                    val.inline = true;
                    val.comment = get_comment ();
                    return val;
                case Category.LEFT_BRACE:
                    return this.parse_inline_table ();
                case Category.HASH:
                    eat ();
                    break;
                default:
                    unexpected ();
                    break;
            }

            while (this.accept (Category.HASH)) {
                eat ();
            }

            return new Element ("NULL");
        }

        private double parse_double () throws TomlError {
            var res = 0.0;
            var dbl = this.current.lexeme.replace ("e", "E").replace ("_", "");
            this.expect (Category.DOUBLE);
            if ("E" in dbl) {
                var dbl_parts = dbl.split ("E");
                int exp = int.parse (dbl_parts[1]);
                double frac = double.parse (dbl_parts[0]);
                res = ((double) exp) * frac;
            } else {
                res = double.parse (dbl);
            }
            return res;
        }

        private Element parse_inline_table () throws TomlError {
            var res = new Element.table ();
            res.inline = true;
            this.expect (Category.LEFT_BRACE);
            while (true) {
                var key = this.parse_key ();
                this.expect (Category.EQUAL);
                var val = this.parse_value ();
                res[key] = val;
                if (!this.accept (Category.COMMA)) {
                    break;
                }
            }
            this.expect (Category.RIGHT_BRACE);
            return res;
        }

        /**
        * Try to get a comment.
        *
        * @return the comment if found, else an empty string.
        */
        private string get_comment () throws TomlError {
            string comment = null;
            while (accept (Category.HASH)) {
                comment = comment == null ? this.current.lexeme : comment + this.current.lexeme;
                expect (Category.COMMENT);
            }
            return comment;
        }

        /**
        * Parses an inline array
        */
        private ArrayList<Element> parse_array () throws TomlError {
            this.expect (Category.LEFT_SQUARE_BRACE);
            var elts = new ArrayList<Element> ();

            while (true) {
                var val = this.parse_value ();
                val.identifier = elts.size.to_string ();
                elts.add (val);
                if (!this.accept (Category.COMMA)) {
                    if (this.accept (Category.RIGHT_SQUARE_BRACE)) {
                        break;
                    } else {
                        unexpected ();
                    }
                }
                val.comment = this.get_comment ();
                if (this.accept (Category.RIGHT_SQUARE_BRACE)) {
                    break;
                }
            }

            return elts;
        }

        /**
        * Parse the declaration of a table array (e.g. `[[foo]]`).
        */
        private void parse_table_array_declaration () throws TomlError {
            this.expect (Category.LEFT_SQUARE_BRACE);
            this.expect (Category.LEFT_SQUARE_BRACE);
            string key = this.parse_key ();
            this.expect (Category.RIGHT_SQUARE_BRACE);
            this.expect (Category.RIGHT_SQUARE_BRACE);
            if (!(key in root)) {
                var arr = new Element.array ();
                arr.identifier = key;
                root[key] = arr;
            }
            var table = new Element.table ();
            this.parse_table (table);
            table.identifier = root[key].as<ArrayList<Element>> ().size.to_string ();
            table.parent = root[key];
            root[key].as<ArrayList<Element>> ().add (table);
        }

        /**
        * Parse the declaration of a table (e.g. `[foo]`).
        */
        private void parse_table_declaration () throws TomlError {
            this.expect (Category.LEFT_SQUARE_BRACE);
            string key = this.parse_key ();
            this.expect (Category.RIGHT_SQUARE_BRACE);
            Element table = new Element.table ();
            this.parse_table (table);
            root[key] = table;
        }

        private Time parse_time () throws TomlError {
            Regex time_re = /(\d{2}):(\d{2}):(\d{2})(\.\d+)?/;
            MatchInfo info;
            if (time_re.match (this.current.lexeme, 0, out info)) {
                int hours = int.parse (info.fetch (1));
                int minutes = int.parse (info.fetch (2));
                int seconds = int.parse (info.fetch (3));

                var time = Time ();
                time.hour = hours;
                time.minute = minutes;
                time.second = seconds;
                eat ();
                return time;
            } else {
                throw new TomlError.SYNTAX_ERROR ("Invalid time format. Use hh-mm-ss.ms.");
            }
        }

        /**
        * Parses a simple date.
        */
        private Date parse_date () throws TomlError {
            Regex date_re = /(\d{4})-(\d{2})-(\d{2})/;
            MatchInfo info;
            if (date_re.match (this.current.lexeme, 0, out info)) {
                ushort year = (ushort) info.fetch (1);
                int _month = (int) info.fetch (2);
                uchar day = (uchar) int.parse (info.fetch (3));

                DateMonth month = DateMonth.JANUARY;
                switch (_month) {
                    case 1:  month = DateMonth.JANUARY; break;
                    case 2:  month = DateMonth.FEBRUARY; break;
                    case 3:  month = DateMonth.MARCH; break;
                    case 4:  month = DateMonth.APRIL; break;
                    case 5:  month = DateMonth.MAY; break;
                    case 6:  month = DateMonth.JUNE; break;
                    case 7:  month = DateMonth.JULY; break;
                    case 8:  month = DateMonth.AUGUST; break;
                    case 9:  month = DateMonth.SEPTEMBER; break;
                    case 10: month = DateMonth.OCTOBER; break;
                    case 11: month = DateMonth.NOVEMBER; break;
                    case 12: month = DateMonth.DECEMBER; break;
                }

                Date date = Date ();
                date.clear ();
                date.set_day (day);
                date.set_month (month);
                date.set_year (year);
                eat ();
                return date;
            }  else {
                throw new TomlError.SYNTAX_ERROR ("Invalid date format. Use YYYY-MM-DD.");
            }
        }

        /**
        * Parse a date and time literal, using RFC 3339.
        */
        private DateTime parse_date_time () throws TomlError {
            Regex dt_re = /(\d{4})-(\d{2})-(\d{2})(T|t)(\d{2}):(\d{2}):(\d{2})(\.(\d+))?((Z|z|[\-\+])(\d{2}):(\d{2}))?/;
            MatchInfo info;
            if (dt_re.match (this.current.lexeme, 0, out info)) {
                int year =    int.parse (info.fetch (1));
                int month =   int.parse (info.fetch (2));
                int day =     int.parse (info.fetch (3));
                int hours =    int.parse (info.fetch (4));
                int minutes = int.parse (info.fetch (5));

                string seconds_int = info.fetch (6);
                string seconds_dec = info.fetch (8) ?? "0";
                double seconds = double.parse (seconds_int + "." + seconds_dec);

                string zone = info.fetch (11);
                if (zone != null) {
                    int zone_hours = int.parse (info.fetch (12));
                    int zone_minutes = int.parse (info.fetch (13));
                    // Get back to UTC
                    if (zone == "-") {
                        hours += zone_hours;
                        minutes += zone_minutes;
                    } else {
                        hours -= zone_hours;
                        minutes -= zone_minutes;
                    }
                }
                eat ();
                return new DateTime.utc (year, month, day, hours, minutes, seconds);
            } else {
                throw new TomlError.SYNTAX_ERROR ("Invalid date-time format. Use RFC 3339.");
            }
        }

        /**
        * Parses a key (e.g. `abc`, `abc.cde`, `a.'ß'.c`, "a.b.c", etc).
        *
        * @return The key.
        */
        private string parse_key () throws TomlError {
            string res = "";
            if (this.current.category == Category.IDENTIFIER || this.current.category == Category.INT) {
                res = this.current.lexeme;
                eat ();
            } else if (this.current.category == Category.SINGLE_QUOTE ||
                        this.current.category == Category.DOUBLE_QUOTE) {
                res = this.parse_string ();
            } else {
                this.unexpected ();
            }

            if (this.accept (Category.DOT)) {
                res += "." + this.parse_key ();
            }

            return res;
        }

        /**
        * Parses a string literal.
        */
        private string parse_string () throws TomlError {
            var quote_style = this.current.category;
            if (quote_style != Category.DOUBLE_QUOTE && quote_style != Category.SINGLE_QUOTE &&
                quote_style != Category.TRIPLE_SINGLE_QUOTE && quote_style != Category.TRIPLE_DOUBLE_QUOTE) {
                throw new TomlError.SYNTAX_ERROR ("Expected a quote to begin the string.");
            }
            eat ();
            string res = "";
            while (true) {
                if (this.current.category == Category.CHAR) {
                    res += this.current.lexeme;
                    eat ();
                } else {
                    this.expect (quote_style);
                    break;
                }
            }
            return res;
        }
    }
}
