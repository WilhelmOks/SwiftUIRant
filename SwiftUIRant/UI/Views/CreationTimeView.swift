//
//  CreationTimeView.swift
//  SwiftUIRant
//
//  Created by Wilhelm Oks on 01.10.22.
//

import SwiftUI

struct CreationTimeView: View {
    let createdTime: Int
    let isEdited: Bool
    
    var body: some View {
        /*
        HStack(spacing: 5) {
            Text(TimeFormatter.shared.string(fromSeconds: createdTime))
                .font(baseSize: 12, weight: .medium)
                .foregroundColor(.secondaryForeground)
            
            if isEdited {
                Image(systemName: "pencil.circle")
                    .font(baseSize: 12)
                    .foregroundColor(.secondaryForeground)
            }
        }*/
        
        VStack(alignment: .trailing, spacing: 5) {
            Text(TimeFormatter.shared.string(fromSeconds: createdTime))
                .font(baseSize: 12, weight: .medium)
                .foregroundColor(.secondaryForeground)
            
            if isEdited {
                Text("Edited")
                    .font(baseSize: 12, weight: .medium)
                    .foregroundColor(.secondaryForeground)
            }
        }
    }
}

struct CreationTimeView_Previews: PreviewProvider {
    static var previews: some View {
        CreationTimeView(
            createdTime: Int(Date().addingTimeInterval(-15).timeIntervalSince1970),
            isEdited: true
        )
    }
}
