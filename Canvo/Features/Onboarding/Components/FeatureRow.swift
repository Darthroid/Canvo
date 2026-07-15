//
//  FeatureRow.swift
//  Canvo
//
//  Created by Олег Комаристый on 30.04.2026.
//

import SwiftUI

struct FeatureRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
