import Text "mo:base/Text";

module TextValidator {
	// Improve this validation
	public func isEmail(maybeEmail : Text) : Bool {
		return not isEmpty(maybeEmail) and Text.contains(maybeEmail, #char '@');
	};

	public func isEmpty(maybeText : Text) : Bool {
		return Text.size(maybeText) == 0;
	};
};
