//
//  RantDetailsView.swift
//  SwiftUIRant
//
//  Created by Wilhelm Oks on 17.09.22.
//

import SwiftUI
import SwiftDevRant

struct RantDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    let sourceTab: InternalView.Tab
    
    @StateObject var viewModel: RantDetailsViewModel
    
    @State private var isMoreMenuPresented = false
    
    enum PresentedSheet: Identifiable {
        case editRant(rant: Rant)
        case postComment(rantId: Rant.ID)
        case editComment(comment: Comment)
        
        var id: String {
            switch self {
            case .editRant(rant: let rant):
                return "edit_rant_\(String(rant.id))"
            case .postComment(rantId: let id):
                return "post_comment_\(String(id))"
            case .editComment(comment: let comment):
                return "edit_comment_\(String(comment.id))"
            }
        }
    }
    
    @State private var presentedSheet: PresentedSheet?
        
    var body: some View {
        content()
            .background(Color.primaryBackground)
            .navigationTitle("Rant")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    toolbarReloadButton()
                }
                
                ToolbarItem(placement: .automatic) {
                    toolbarMoreButton()
                }
            }
            .alert($viewModel.alertMessage)
            .sheet(item: $presentedSheet) { item in
                switch item {
                case .postComment(rantId: let rantId):
                    WritePostView(
                        viewModel: .init(
                            kind: .postComment(rantId: rantId),
                            mentionSuggestions: viewModel.commentMentionSuggestions(),
                            onSubmitted: {
                                Task {
                                    await viewModel.reload()
                                    DispatchQueue.main.async {
                                        viewModel.scrollToCommentWithId = viewModel.comments.last?.id
                                        BroadcastEvent.shouldScrollToComment.send()
                                    }
                                }
                            }
                        )
                    )
                case .editComment(comment: let comment):
                    WritePostView(
                        viewModel: .init(
                            kind: .editComment(comment: comment),
                            mentionSuggestions: viewModel.commentMentionSuggestions(),
                            onSubmitted: {
                                Task {
                                    await viewModel.reload()
                                }
                            }
                        )
                    )
                case .editRant(rant: let rant):
                    WritePostView(
                        viewModel: .init(
                            kind: .editRant(rant: rant),
                            onSubmitted: {
                                Task {
                                    await viewModel.reload()
                                }
                            }
                        )
                    )
                }
            }
            .onReceive(viewModel.dismiss) { _ in
                dismiss()
            }
            .onReceive { event in
                switch event {
                case .shouldUpdateCommentInLists(let comment): return comment
                default: return nil
                }
            } perform: { (comment: Comment) in
                viewModel.comments.updateComment(comment)
            }
    }
    
    @ViewBuilder private func content() -> some View {
        if let rant = viewModel.rant, !viewModel.isLoading {
            ZStack {
                VStack(spacing: 0) {
                    if let weekly = viewModel.rant?.weekly {
                        weeklyArea(weekly)
                        
                        Divider()
                    }
                    
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            VStack(spacing: 0) {
                                RantView(
                                    viewModel: .init(
                                        rant: rant
                                    ),
                                    onEdit: {
                                        presentedSheet = .editRant(rant: rant)
                                    },
                                    onDelete: {
                                        Task {
                                            await viewModel.deleteRant(rant: rant)
                                        }
                                    }
                                )
                                .padding(.bottom, 10)
                                .id(rant.hashValue)
                                
                                LazyVStack(spacing: 0) {
                                    ForEach(viewModel.comments, id: \.id) { comment in
                                        VStack(spacing: 0) {
                                            Divider()
                                            
                                            RantCommentView(
                                                viewModel: .init(comment: comment),
                                                onReply: {
                                                    presentedSheet = .postComment(rantId: viewModel.rantId)
                                                },
                                                onEdit: {
                                                    presentedSheet = .editComment(comment: comment)
                                                },
                                                onDelete: {
                                                    Task {
                                                        await viewModel.deleteComment(comment: comment)
                                                    }
                                                }
                                            )
                                            .padding(.bottom, 10)
                                            .id(comment.hashValue)
                                        }
                                        .id("comment_\(comment.id)")
                                    }
                                }
                            }
                            .padding(.bottom, 10)
                            .padding(.bottom, 40) //TODO: measure comment button size and set it here
                        }
                        .onReceive(broadcastEvent: .shouldScrollToComment) { _ in
                            if let commentId = viewModel.scrollToCommentWithId {
                                withAnimation {
                                    scrollProxy.scrollTo("comment_\(commentId)", anchor: .top)
                                }
                            }
                        }
                    }
                }
                
                commentButton()
                .fill(.bottomTrailing)
                .padding(10)
            }
        } else {
            ProgressView()
        }
    }
    
    @ViewBuilder private func weeklyArea(_ weekly: Rant.Weekly) -> some View {
        VStack(spacing: 4) {
            Text(weekly.topic)
                .font(baseSize: 15, weightDelta: 1)
                .multilineTextAlignment(.leading)
                .fillHorizontally(.leading)
                .foregroundColor(.primaryForeground)
            
            Text("Week \(weekly.week) Group Rant")
                .font(baseSize: 13, weightDelta: 1)
                .multilineTextAlignment(.leading)
                .fillHorizontally(.leading)
                .foregroundColor(.secondaryForeground)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder private func commentButton() -> some View {
        Button {
            presentedSheet = .postComment(rantId: viewModel.rantId)
        } label: {
            Label {
                Text("Comment")
            } icon: {
                Image(systemName: "bubble.right")
            }
            .font(baseSize: 13, weightDelta: 1)
        }
        .buttonStyle(.borderedProminent)
    }
    
    @ViewBuilder private func toolbarReloadButton() -> some View {
        ZStack {
            ProgressView()
                .opacity(viewModel.isReloading ? 1 : 0)
                
            Button {
                Task {
                    await viewModel.reload()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 26, height: 26)
            }
            .disabled(viewModel.isLoading)
            .opacity(!viewModel.isReloading ? 1 : 0)
        }
    }
    
    @ViewBuilder private func toolbarMoreButton() -> some View {
        #if os(macOS)
        Menu {
            if let link = viewModel.rant?.linkToRant {
                Button {
                    let devRantLink = "https://devrant.com/\(link)"
                    Pasteboard.shared.copy(devRantLink)
                } label: {
                    Label("Copy Rant Link", systemImage: "doc.on.doc")
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .frame(width: 26, height: 26)
        }
        .disabled(viewModel.isLoading || viewModel.isReloading)
        #endif
        
        // Using ActionSheet instead of Menu on iOS because the Menu appears to be a bit buggy:
        // When Menu is open and user taps on "Comment" button, the comment button becomes broken and can not be tapped until view is dismissed and opened again.
        #if os(iOS)
        Button {
            isMoreMenuPresented = true
        } label: {
            Image(systemName: "ellipsis")
                .frame(width: 26, height: 26)
        }
        .disabled(viewModel.isLoading || viewModel.isReloading)
        .actionSheet(isPresented: $isMoreMenuPresented) {
            ActionSheet(
                title: Text(""),
                message: nil,
                buttons: [
                    .default(Text("Copy Rant Link")) {
                        if let link = viewModel.rant?.linkToRant {
                            let devRantLink = "https://devrant.com/\(link)"
                            Pasteboard.shared.copy(devRantLink)
                        }
                    },
                    .cancel()
                ]
            )
        }
        #endif
        
        //TODO: Subscribe to User's Rants
        //TODO: Mute Notifs for this Rant (except @mentions)
    }
}

struct RantDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        RantDetailsView(
            sourceTab: .feed,
            viewModel: .init(
                rantId: 1
            )
        )
    }
}
