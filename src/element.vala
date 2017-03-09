using Gee;

namespace Toml {

    /**
    * Represents any TOML element.
    *
    * It could contain string, ints, array, tables, booleans, etc.
    *
    * To retrive the value contained as a normal value, use {@link Toml.Element.as} method.
    *
    * Example:
    *
    * {{{
    *   Element doc = get_document ();
    *   int a = doc["foo.bar"].as<int> ();
    *   doc["foo"]["baz"]["hey"] = "Hey bro!";
    * }}}
    */
    public class Element : Object {

        internal Value value;

        /**
        * The {@link GLib.Type} stored by this element.
        */
        public Type value_type {
            get {
                return this.value.type ();
            }
        }

        /**
        * A comment associated with this element.
        */
        public string comment { get; set; }

        /**
        * The children of this element.
        *
        * Only have a value when this element is a table or an array.
        */
        public ArrayList<Element>? children { get; set; }

        /**
        * Defines if this element should is inline in the document.
        *
        * Only meaningful when the element is a container.
        */
        public bool inline { get; set; }

        /**
        * The parent element.
        *
        * It's null when this element is the document root.
        */
        public weak Element? parent { get; set; }

        /**
        * The absolute path of this element in the document.
        *
        * For instance, let's assume we have this document.
        *
        * {{{
        *   [a.b.c]
        *   d.e = 42
        * }}}
        *
        * The path of `e` will be `a.b.c.d.e`.
        */
        public string? path {
            owned get {
                return (this.parent != null && this.parent.path != null
                    ? this.parent.path + "."
                    : null)
                + this.identifier;
            }
        }

        /**
        * The (relative) identifier of this element.
        *
        * It is unique only inside the parent's scope.
        *
        * For instance, let's assume we have this document.
        *
        * {{{
        *   [a.b.c]
        *   d.e = 42
        * }}}
        *
        * The identifier of `e` will just be `e`.
        */
        public string? identifier {
            owned get {
                if (this._identifier != null) {
                    return this._identifier;
                } else if (this.parent != null) {
                    return this.parent.as<ArrayList<Element>> ().index_of (this).to_string ();
                } else {
                    return null;
                }
            }
            internal set {
                _identifier = value;
            }
        }
        private string _identifier;

        /**
        * Creates a new TOML element for a primitive value.
        *
        * For tables and arrays use {@link Toml.Element.table} and {@link Toml.Element.array}.
        */
        public Element (Value v) {
            this.value = v;
        }

        /**
        * Creates a new table element.
        */
        public Element.table () {
            this.children = new ArrayList<Element> ();
            this.value = Value (typeof (Object));
        }

        /**
        * Creates a new array element (inline or table style).
        */
        public Element.array (ArrayList<Element> children = new ArrayList<Element> ()) {
            this.children = children;
            this.value = Value (typeof (ArrayList));
        }

        /**
        * Tells if this can have children or not.
        *
        * @return true if it is a container (array or table), false if it is a primitive.
        */
        public bool is_container () {
            return this.value_type == typeof (ArrayList) || this.value_type == typeof (Object);
        }

        /**
        * Try to get a children at a certain path.
        *
        * Nested path (e.g `foo.bar`) are not supported: they are considered as keys containing dots.
        * Use `a["foo"]["bar"]` instead.
        *
        * You can use it like that.
        *
        * {{{
        *   var foo = table["foo"];
        *   // Ugly equivalent
        *   var foo = table.get ("foo");
        * }}}
        *
        * @param path The path of the child. It could contain dots.
        * @return The child element if found, else this element.
        */
        public new Element @get (Value path) throws TomlError.PATH {
            var _path = (string) path;

            if (this.children != null) {
                foreach (Element ch in this.children) {
                    if (ch.identifier == _path) {
                        return ch;
                    }
                }
                throw new TomlError.PATH (@"Nothing at `$_path`.");
            }
            throw new TomlError.PATH (@"`$(this.path)` doesn't have children.");
        }

        /**
        * Checks if an element exists at a certain key.
        *
        * @param key The key to look for.
        */
        public bool contains (Value key) {
            try {
                return this[key] != null;
            } catch (Error e) {
                return false;
            }
        }

        /**
        * Sets an element at a specified path.
        *
        * @param path The path of the element.
        * @param val The element to put at the specified path.
        */
        public new void @set (Value path, Element val) throws TomlError {
            if (!this.is_container ()) {
                throw new TomlError.PATH ("You can't add children to something else that arrays and tables.");
            }
            Element? to_remove = null;
            foreach (Element elt in this.children) {
                if (elt.path == path) {
                    to_remove = elt;
                    break;
                }
            }

            if (to_remove != null) {
                this.children.remove (to_remove);
            }

            val.parent = this;
            val.identifier = (string) path;
            this.children.add (val);
        }

        /**
        * Try to get the value contained into this element.
        *
        * @return The value of this element in the specified type.
        */
        public G @as<G> () {
            var type = typeof (G);
            if (type == typeof (ArrayList)) {
                return this.children;
            } else if (type == typeof (Element[])) {
                return this.children.to_array ();
            } else if (type == typeof (string)) {
                return this.value.get_string ();
            } else if (type == typeof (int)) {
                return this.value.get_int ();
            } else if (type == typeof (DateTime)) {
                return (DateTime) this.value.get_boxed ();
            } else if (type == typeof (bool)) {
                return this.value.get_boolean ();
            } else {
                return (G) this.value.get_object ();
            }
        }

        /**
        * Shorthand for {@link Toml.Element.as}<{@link Gee.ArrayList}<{@link Toml.Element}>>.
        */
        public ArrayList<Element> as_array () {
            return this.as<ArrayList<Element>> ();
        }

        /**
        * Converts this element to its TOML equivalent.
        */
        [Version (experimental = true)]
        public string to_string () {
            string res = "";
            if (this.value.holds (typeof (Object))) {
                if (this.inline) {
                    string[] values = {};
                    foreach (var ch in this.children) {
                        values += ch.to_string ();
                    }
                    res += "\n%s = { %s }\n".printf (this.identifier, string.joinv (", ", values));
                } else {
                    if (this.path != null) {
                        print ("THIS.PATH: `%s`\n\n", this.path);
                        res += "\n[%s]\n".printf (this.path);
                    }
                    foreach (var ch in this.children) {
                        res += ch.to_string ();
                    }
                }
            } else if (this.value.holds (typeof (ArrayList))) {
                if (this.inline) {
                    string[] values = {};
                    foreach (var ch in this.children) {
                        values += ch.to_string ();
                    }
                    res += "\n%s = [\n\t%s\n]\n".printf (this.identifier, string.join (",\n\t", values));
                } else {
                    res += "\n[[%s]]\n".printf (this.path);
                    foreach (var ch in this.children) {
                        res += ch.to_string ();
                    }
                }
            } else {
                string str_rep = "null";
                if (this.value.type () == typeof (string)) {
                    str_rep = (string) this.value;
                } else if (this.value.type () == typeof (int)) {
                    str_rep = ((int) this.value).to_string ();
                } else if (this.value.type () == typeof (bool)) {
                    str_rep = ((bool) this.value).to_string ();
                } else if (this.value.type () == typeof (double)) {
                    str_rep = ((double) this.value).to_string ();
                }
                res += this.identifier + " = " + str_rep + "\n";
            }
            return res;
        }
    }
}
