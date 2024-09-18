import WorkspaceIamEventsModule "../workspace-iam/events";

module WorkspaceOrchestratorEvents {
	public type EventVariants = WorkspaceIamEventsModule.EventVariants;
};
