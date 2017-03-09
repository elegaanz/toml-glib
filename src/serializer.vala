// Inspired by https://github.com/BZHDeveloper/Json-Vala/blob/master/src/Serialize.vala

namespace Toml.Serialization {
    public Element serialize (Object obj) throws TomlError {
        Element result = new Element.table ();
		var klass = (ObjectClass) obj.get_type ().class_ref ();
		foreach (var spec in klass.list_properties ()) {
			GLib.Value value = GLib.Value (spec.value_type);
			obj.get_property (spec.name, ref value);
			if (spec.value_type.is_object ())
				result[spec.name] = serialize ((GLib.Object) value);
			else
				result[spec.name] = new Element (value);
		}
        return result;
    }

    public G deserialize<G> (Element elt) throws TomlError {
        return element_to_object (typeof (G), elt);
    }

    public Object element_to_object (Type type, Element elt) throws TomlError {
        if (!type.is_object ()) {
			throw new TomlError.SERIALIZATION ("deserialize: requested type should be a GLib.Object");
        }
        if (elt.value_type != typeof (Object)) {
            throw new TomlError.SERIALIZATION ("deserialize: the element to deserialize should be a table");
        }

		var obj = GLib.Object.new (type);
		var klass = (ObjectClass) type.class_ref ();
		foreach (var spec in klass.list_properties ()) {
			var val = elt[spec.name].value;
			if (spec.value_type.is_object ())
				obj.set (spec.name, element_to_object (spec.value_type, elt[spec.name]));
			else
				obj.set_property (spec.name, val);
		}
        return obj;
    }
}
