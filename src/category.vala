namespace Toml {
    public enum Category {
        HASH,
        COMMENT,
        CHAR,
        INT,
        DOUBLE,
        BOOLEAN,
        DATE_TIME,
        DATE,
        TIME,

        LINE_BREAK,
        WHITESPACE,

        DOUBLE_QUOTE,
        SINGLE_QUOTE,
        TRIPLE_DOUBLE_QUOTE,
        TRIPLE_SINGLE_QUOTE,

        LEFT_SQUARE_BRACE,
        RIGHT_SQUARE_BRACE,
        LEFT_BRACE,
        RIGHT_BRACE,

        COMMA,
        DOT,
        EQUAL,

        IDENTIFIER,

        EOF;

        public string to_string () {
            switch (this) {
                case HASH:
                    return "a hash";
                case COMMENT:
                    return "a comment";
                case CHAR:
                    return "a character";
                case INT:
                    return "an integer";
                case DOUBLE:
                    return "a floating number";
                case BOOLEAN:
                    return "a boolean";
                case DATE_TIME:
                    return "a date and time";
                case DATE:
                    return "a date";
                case TIME:
                    return "a time";
                case LINE_BREAK:
                    return "the end of a line";
                case WHITESPACE:
                    return "some space";
                case DOUBLE_QUOTE:
                    return "double quotes";
                case SINGLE_QUOTE:
                    return "a single quote";
                case TRIPLE_DOUBLE_QUOTE:
                    return "three double quotes";
                case TRIPLE_SINGLE_QUOTE:
                    return "three single quotes";
                case LEFT_SQUARE_BRACE:
                    return "an opening square brace";
                case RIGHT_SQUARE_BRACE:
                    return "a closing square brace";
                case LEFT_BRACE:
                    return "an opening curly brace";
                case RIGHT_BRACE:
                    return "a closing curly brace";
                case COMMA:
                    return "a comma";
                case DOT:
                    return "a dot";
                case EQUAL:
                    return "an equal sign";
                case IDENTIFIER:
                    return "an identifier";
                case Category.EOF:
                    return "the end of the file";
                default:
                    return "unknown";
            }
        }
    }
}
