Fix NWD-212: GET /api/dispatches/{id} returns a 500 for a dispatch that has no driver yet. Pending dispatches don't have a driver until a dispatcher assigns one, so this is valid data.
