//
//  RantViewModel.swift
//  SwiftUIRant
//
//  Created by Wilhelm Oks on 22.09.22.
//

import Foundation
import SwiftRant

@MainActor final class RantViewModel: ObservableObject {
    @Published var rant: Rant
    
    @Published var alertMessage: AlertMessage = .none()
    
    @Published var voteController: VoteController!
    
    init(rant: Rant) {
        self.rant = rant
        
        voteController = .init(
            voteState: { [weak self] in
                self?.rant.voteState ?? .unvoted
            },
            score: { [weak self] in
                self?.rant.score ?? 0
            },
            voteAction: { [weak self] voteState in
                let changedRant = try await Networking.shared.vote(rantID: rant.id, voteState: voteState)
                self?.applyChangedData(changedRant: changedRant)
            },
            handleError: { [weak self] error in
                self?.alertMessage = .presentedError(error)
            }
        )
    }
    
    private func applyChangedData(changedRant: Rant) {
        dlog("### updating rant with id: \(rant.id)")
        let changedVoteState = changedRant.voteState
        rant.voteState = changedVoteState
        rant.score = changedRant.score
        DataStore.shared.update(rantInFeedId: rant.id, voteState: changedVoteState, score: changedRant.score)
        //TODO: find out why feed is not updating
    }
}