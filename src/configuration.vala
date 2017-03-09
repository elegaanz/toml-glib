namespace Toml {

    [CCode (has_target = false)]
    public delegate bool PropertyFilter (string name);

    public enum CommentPosition {
        AFTER,
        BEFORE
    }

    public class Configuration : Object {
        public bool indent { get; set; }

        public string indent_chars { get; set; }

        public PropertyFilter should_write { get; set; }

        public CommentPosition comment_position { get; set; }

        public bool always_line_break { get; set; }

        public Configuration.@default () {
            this.indent = false;
            this.indent_chars = "  ";
            this.should_write  = (name) => {
                return true;
            };
            this.comment_position = CommentPosition.AFTER;
            this.always_line_break = true;
        }

        public Configuration.follow_file_conventions (string path) {
            error ("Not implemented yet");
        }
    }
}
