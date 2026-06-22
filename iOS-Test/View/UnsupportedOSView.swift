//
//  UnsupportedOSView.swift
//
//  Created by Alam Monroy.
//

import SwiftUI

/// Shown when the device's OS doesn't support the Liquid Glass APIs
/// this demo relies on (iOS 26.0+).
struct UnsupportedOSView: View {
    @Environment(\.localizationBundle) private var bundle

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)

            Text(String(localized: "Update Required", bundle: bundle))
                .font(.title2.weight(.semibold))

            Text(String(localized: "This demo requires iOS 26 or later.", bundle: bundle))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(currentSystemVersionLabel)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    private var currentSystemVersionLabel: String {
        let format = String(localized: "Current version: %@", bundle: bundle)
        return String(format: format, UIDevice.current.systemVersion)
    }
}

// MARK: - Preview
#Preview("Unsupported OS") {
    UnsupportedOSView()
}
