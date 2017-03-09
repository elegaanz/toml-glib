using Gee;

namespace Toml {
    public class Writer : Object {

        private Configuration config;

        private StringBuilder bld;

        private Regex bare_re;

        public Writer (Configuration config = new Configuration.default ()) {
            this.config = config;
            this.bld = new StringBuilder ();
            this.bare_re = /^[A-Za-z0-9_\- ]+$/;
        }

        private string tab (int tabs, bool force = false) {
            string res = "";
            if (this.config.indent || force) {
                for (int i = 0; i < tabs; i++) {
                    res += this.config.indent_chars ?? "  ";
                }
            }
            return res;
        }

        /**
        * New line char for inline containers, depending on the config.
        */
        private string new_line () {
            return this.config.always_line_break ? ",\n" : ", " ;
        }

        public string write (Element elt, int tabs = 0) {
            if (this.config.comment_position == CommentPosition.BEFORE && elt.comment != null) {
                bld.append ("# ");
                bld.append (string.joinv ("\n# ", elt.comment.split ("\n")));
                bld.append ("\n");
            }

            if (elt.value_type == typeof (Object)) { // tables
                if (elt.inline) {
                    bld.append ("{" + (this.config.always_line_break ? "\n" : " "));

                    bool first = true;
                    foreach (var ch in elt.children) {
                        if (first) {
                            first = false;
                        } else {
                            bld.append (new_line ());
                        }
                        bld.append (tab (this.config.indent ? tabs + 1 : 1, true));
                        bld.append (key (ch));
                        bld.append (" = ");
                        this.write (ch);
                    }

                    bld.append ((this.config.always_line_break ? "\n" : " ") + "}");
                    if (this.config.comment_position == CommentPosition.AFTER && elt.comment != null) {
                        bld.append (" # ");
                        bld.append (string.joinv ("\n# ", elt.comment.split ("\n")));
                        bld.append ("\n");
                    }
                } else {
                    if (elt.identifier != null) { // don't write it for root
                        bld.append (tab (tabs));
                        bld.append ("\n[");
                        bld.append (path (elt));
                        bld.append ("]\n");
                    }
                    foreach (var ch in elt.children) {
                        bld.append (tab (tabs + 1));
                        if (!ch.is_container () || ch.inline) {
                            bld.append (key (ch));
                            bld.append (" = ");
                        }

                        this.write (ch, tabs + 1);
                        bld.append ("\n");
                    }
                    // bld.truncate (bld.len - 2); // remove the last \n
                }
            } else if (elt.value_type == typeof (ArrayList)) { // arrays
                if (elt.inline) {
                    bld.append ("[\n");

                    bool first = true;
                    foreach (var ch in elt.children) {
                        if (first) {
                            first = false;
                        } else {
                            bld.append (new_line ());
                        }
                        bld.append (tab (this.config.indent ? tabs + 1 : 1, true));
                        this.write (ch, tabs + 1);
                    }

                    bld.append ("\n]");
                    if (this.config.comment_position == CommentPosition.AFTER && elt.comment != null) {
                        bld.append (" # ");
                        bld.append (string.joinv ("\n# ", elt.comment.split ("\n")));
                        bld.append ("\n");
                    }
                } else {
                    foreach (var ch in elt.children) {
                        bld.append (tab (tabs));
                        bld.append ("[[");
                        bld.append (path (elt));
                        bld.append ("]]\n");

                        bld.append (tab (tabs + 1));
                        foreach (var ch_ch in ch.children) {
                            bld.append (key (ch_ch));
                            bld.append (" = ");
                            this.write (ch_ch);
                            bld.append ("\n");
                        }
                    }
                }
            } else if (elt.value_type == typeof (string)) {
                if (elt.as<string> () == null || bare_re.match (elt.as<string> ())) {
                    bld.append (@"\"$(elt.as<string> ())\"");
                } else {
                    bld.append (@"'$(elt.as<string> ())'");
                }
            } else if (elt.value_type == typeof (int)) {
                bld.append (elt.as<int> ().to_string ());
            } else if (elt.value_type == typeof (double)) {
                bld.append (elt.value.get_double ().to_string ());
            } else if (elt.value_type == typeof (bool)) {
                bld.append (elt.as<bool> ().to_string ());
            }
            return bld.str;
        }

        public string? path (Element elt) {
            if (elt.identifier == null) {
                return null;
            } else if (elt.parent == null || path (elt.parent) == null) {
                return key (elt);
            } else {
                return path (elt.parent) + "." + key (elt);
            }
        }

        public string key (Element elt) {
            if (bare_re.match (elt.identifier)) {
                return elt.identifier;
            } else {
                return @"'$(elt.identifier)'";
            }
        }
    }
}
