module CoreTypes {
	public type Event<T> = {
		action : Text;
		payload : T;
	};
};
