namespace Toml {

    /**
    * Errors related to TOML.
    */
    public errordomain TomlError {
        SYNTAX_ERROR,
        INVALID_ESCAPE_SEQUENCE,
        PATH,
        SERIALIZATION
    }

    [Version (experimental = true)]
    private string strip_line_continuations (string s) {
        try {
            Regex re = /\\$/;
            return re.replace (s, s.length, 0, "");
        } catch (Error err) {
            return s;
        }
    }

}
