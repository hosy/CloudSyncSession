struct WorkMiddleware: Middleware {
    var session: CloudSyncSession

    func run(next: (SyncEvent) -> SyncEvent, event: SyncEvent) -> SyncEvent {
        let prevState = session.state
        let event = next(event)
        let newState = session.state

        if prevState.currentWork != newState.currentWork {
            work()
        }

        return event
    }

    private func work() {
        if let work = session.state.currentWork {
            switch work {
            case .fetch(let operation):
                session.operationHandler.handle(fetchOperation: operation) { result in
                    switch result {
                    case let .failure(error):
                        session.dispatch(event: .workFailure(work, error))
                    case let .success(response):
                        session.dispatch(event: .workSuccess(work, .fetch(response)))
                    }
                }
            case .modify(let operation):
                session.operationHandler.handle(modifyOperation: operation) { result in
                    switch result {
                    case let .failure(error):
                        session.dispatch(event: .workFailure(work, error))
                    case let .success(response):
                        session.dispatch(event: .workSuccess(work, .modify(response)))
                    }
                }
            case .createZone(let operation):
                session.operationHandler.handle(createZoneOperation: operation) { result in
                    switch result {
                    case let .failure(error):
                        session.dispatch(event: .workFailure(work, error))
                    case let .success(hasCreatedZone):
                        session.dispatch(event: .workSuccess(work, .createZone(hasCreatedZone)))
                    }
                }
            }
        }
    }
}
