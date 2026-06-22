//
//  PhoneView.swift
//
//  Created by Andres Marin on 13/02/26.
//

import SwiftUI

// MARK: - PhoneView
@available(iOS 26.0, *)
struct PhoneView: View {
    @Environment(\.localizationBundle) private var bundle
    @ObservedObject private var vm = PhoneViewModel()

    var body: some View {
        TabView {
            FavoritesView(
                contacts: vm.contacts,
                preloadedImages: vm.contactImages
            )
            .tabItem {
                Text("⭐️ " + String(localized: "Favorites", bundle: bundle))
                    .padding(.vertical, 10)
            }

            RecentsView()
                .tabItem {
                    Text("🕒 " + String(localized: "Recents", bundle: bundle))
                        .padding(.vertical, 10)
                }

            ContactsView(contacts: vm.contacts)
                .tabItem {
                    Text("👥 " + String(localized: "Contacts", bundle: bundle))
                        .padding(.vertical, 10)
                }

            KeypadView()
                .tabItem {
                    Text("🔢 " + String(localized: "Keypad", bundle: bundle))
                        .padding(.vertical, 10)
                }

            VoicemailView()
                .tabItem {
                    Text("📼 " + String(localized: "Voicemail", bundle: bundle))
                        .padding(.vertical, 10)
                }
        }
        .tint(.blue)
        .task { vm.loadData() }
    }
}

// MARK: - 1. Favorites View
@available(iOS 26.0, *)
struct FavoritesView: View {
    let contacts: [ContactConfig]
    var preloadedImages: [Int: UIImage] = [:]

    @Environment(\.localizationBundle) private var bundle
    @State private var callingContact: ContactConfig? = nil
    @State private var contactForDetail: ContactConfig? = nil

    var body: some View {
        NavigationStack {
            List {
                ForEach(contacts) { contact in
                    HStack(spacing: 12) {
                        Button {
                            callingContact = contact
                        } label: {
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: contact.avatar ?? "")) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable().scaledToFill()
                                            .frame(width: 45, height: 45)
                                            .clipShape(Circle())
                                    default:
                                        Circle()
                                            .fill(Color.gray.opacity(0.35))
                                            .frame(width: 46, height: 46)
                                            .overlay(
                                                Text(contact.name.prefix(2).uppercased())
                                                    .font(.system(size: 17, weight: .semibold))
                                                    .foregroundStyle(.white)
                                            )
                                    }
                                }
                                .frame(width: 46, height: 46)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name)
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundStyle(.primary)
                                    HStack(spacing: 3) {
                                        Image(systemName: "phone")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                        Text(String(localized: "mobile", bundle: bundle))
                                            .font(.system(size: 13))
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            contactForDetail = contact
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, -2)
                    .listSectionSeparator(.hidden, edges: .top)
                }
            }
            .sheet(item: $contactForDetail) { contact in
                ContactDetailWebView(contact: contact)
                    .presentationDetents([.medium])
            }
            .fullScreenCover(item: $callingContact) { contact in
                CallView(
                    contact: contact,
                    preloadedBackground: preloadedImages[contact.id],
                    onEnd: { callingContact = nil }
                )
            }
            .listStyle(.plain)
            .navigationTitle(String(localized: "Favorites", bundle: bundle))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Edit", bundle: bundle)) {}
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) { Image(systemName: "plus") }
                }
            }
            .overlay {
                if contacts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star.slash.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text(String(localized: "No Favorites", bundle: bundle))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(String(localized: "Add contacts to your favorites\nfor quick access.", bundle: bundle))
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
}

// MARK: - 2. Recents View
struct RecentsView: View {
    @Environment(\.localizationBundle) private var bundle
    @State private var filter = 0

    var recentCalls: [RecentItem] {[
        RecentItem(name: "Pallav Agarwal",    label: String(localized: "mobile",    bundle: bundle), date: "12:42 PM",                                           type: .missed),
        RecentItem(name: "Mom",               label: String(localized: "home",      bundle: bundle), date: String(localized: "Yesterday", bundle: bundle),        type: .outgoing),
        RecentItem(name: "Craig Federighi",   label: String(localized: "work",      bundle: bundle), date: String(localized: "Friday",    bundle: bundle),        type: .incoming),
        RecentItem(name: "Tim Cook",          label: "iPhone",                                       date: String(localized: "Friday",    bundle: bundle),        type: .incoming),
        RecentItem(name: "+1 (555) 123-4567", label: "Cupertino, CA",                               date: String(localized: "Thursday",  bundle: bundle),        type: .missed)
    ]}

    var filteredCalls: [RecentItem] {
        filter == 1 ? recentCalls.filter { $0.type == .missed } : recentCalls
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCalls) { call in
                    HStack(spacing: 12) {
                        if call.type == .outgoing {
                            Image(systemName: "phone.arrow.up.right.fill")
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .frame(width: 12)
                        } else {
                            Spacer().frame(width: 12)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(call.name)
                                .font(.headline)
                                .foregroundStyle(call.type == .missed ? .red : .primary)
                            Text(call.label)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }

                        Spacer()

                        HStack(alignment: .center, spacing: 8) {
                            Text(call.date)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            Button(action: {}) {
                                Image(systemName: "info.circle")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(.plain)
            .navigationTitle(String(localized: "Recents", bundle: bundle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker(String(localized: "Filter", bundle: bundle), selection: $filter) {
                        Text(String(localized: "All", bundle: bundle)).tag(0)
                        Text(String(localized: "Missed", bundle: bundle)).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Edit", bundle: bundle)) {}
                }
            }
        }
    }
}

struct RecentItem: Identifiable {
    let id = UUID()
    let name: String
    let label: String
    let date: String
    let type: CallType
    enum CallType { case incoming, outgoing, missed }
}

// MARK: - 3. Contacts View
@available(iOS 26.0, *)
struct ContactsView: View {
    let contacts: [ContactConfig]
    @Environment(\.localizationBundle) private var bundle
    @State private var searchText = ""

    let staticNames = ["Aaron", "Adam", "Brian", "Bob", "Charlie", "Craig Federighi", "David", "Emily", "Frank", "Greg", "Harry", "Ian", "John Appleseed", "Jony Ive", "Kate", "Larry", "Mike", "Nancy", "Oscar", "Pallav Agarwal", "Paul", "Quincy", "Rachel", "Steve Jobs", "Tim Cook", "Ursula", "Victor", "Wendy", "Xavier", "Yvonne", "Zach"]

    var allNames: [String] {
        let fromVM = contacts.map { $0.name }
        let merged = Array(Set(fromVM + staticNames)).sorted()
        if searchText.isEmpty { return merged }
        return merged.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var groupedContacts: [String: [String]] {
        Dictionary(grouping: allNames, by: { String($0.prefix(1)) })
    }

    var sortedKeys: [String] { groupedContacts.keys.sorted() }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 15) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(Text("JA").font(.title2).bold().foregroundStyle(.white))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("John Appleseed")
                                .font(.title2).fontWeight(.semibold)
                            Text(String(localized: "My Card", bundle: bundle))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                ForEach(sortedKeys, id: \.self) { key in
                    Section(header: Text(key).fontWeight(.bold)) {
                        ForEach(groupedContacts[key]!, id: \.self) { name in
                            Text(name).fontWeight(.medium)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle(String(localized: "Contacts", bundle: bundle))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Groups", bundle: bundle)) {}
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) { Image(systemName: "plus") }
                }
            }
        }
    }
}

// MARK: - 4. Keypad View
struct KeypadView: View {
    @Environment(\.localizationBundle) private var bundle
    @State private var number = ""

    let columns = Array(repeating: GridItem(.fixed(78), spacing: 24), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text(number)
                    .font(.system(size: 40, weight: .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(height: 50)
                    .padding(.horizontal, 40)

                Button(String(localized: "Add Number", bundle: bundle)) {}
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                    .opacity(number.isEmpty ? 0 : 1)
                    .frame(height: 20)
            }
            .padding(.bottom, 20)

            LazyVGrid(columns: columns, spacing: 16) {
                KeypadButton(main: "1", sub: "")        { append("1") }
                KeypadButton(main: "2", sub: "A B C")   { append("2") }
                KeypadButton(main: "3", sub: "D E F")   { append("3") }
                KeypadButton(main: "4", sub: "G H I")   { append("4") }
                KeypadButton(main: "5", sub: "J K L")   { append("5") }
                KeypadButton(main: "6", sub: "M N O")   { append("6") }
                KeypadButton(main: "7", sub: "P Q R S") { append("7") }
                KeypadButton(main: "8", sub: "T U V")   { append("8") }
                KeypadButton(main: "9", sub: "W X Y Z") { append("9") }
                KeypadButton(main: "*", sub: "", isSymbol: true) { append("*") }
                KeypadButton(main: "0", sub: "+")       { append("0") }
                KeypadButton(main: "#", sub: "", isSymbol: true) { append("#") }
            }
            .padding(.bottom, 20)

            HStack {
                Color.clear.frame(width: 78, height: 78)
                Spacer()
                Button(action: {}) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 78, height: 78)
                        .overlay(
                            Image(systemName: "phone.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                        )
                }
                .buttonStyle(IOSButtonStyle())
                Spacer()
                Button {
                    if !number.isEmpty { number.removeLast() }
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Color(uiColor: .systemGray3))
                        .frame(width: 78, height: 78)
                }
                .opacity(number.isEmpty ? 0 : 1)
                .disabled(number.isEmpty)
            }
            .padding(.horizontal, 45)
            .padding(.bottom, 80)
        }
    }

    func append(_ val: String) {
        if number.count < 15 { number += val }
    }
}

// MARK: - 5. Voicemail View
struct VoicemailView: View {
    @Environment(\.localizationBundle) private var bundle
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Spacer()
                Text(String(localized: "Call Voicemail", bundle: bundle))
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(uiColor: .systemGray6))
                    )
                Spacer()
            }
            .navigationTitle(String(localized: "Voicemail", bundle: bundle))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Greeting", bundle: bundle)) {}
                }
            }
        }
    }
}

// MARK: - Keypad Button
struct KeypadButton: View {
    let main: String
    let sub: String
    var isSymbol: Bool = false
    let action: () -> Void

    let lightGray = Color(red: 229/255, green: 229/255, blue: 229/255)
    let darkGray  = Color(red: 50/255,  green: 50/255,  blue: 50/255)

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 39, style: .continuous)
                    .fill(colorScheme == .dark ? darkGray : lightGray)
                    .frame(width: 82, height: 78)
                VStack(spacing: 0) {
                    Text(main)
                        .font(.system(size: 34, weight: .regular))
                        .foregroundStyle(.primary)
                        .padding(.top, (sub.isEmpty && !isSymbol) ? 0 : (isSymbol ? 6 : 2))
                    if !sub.isEmpty {
                        Text(sub)
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(.primary)
                            .padding(.bottom, 4)
                    }
                }
                .offset(y: sub.isEmpty ? 0 : -2)
            }
        }
        .buttonStyle(IOSButtonStyle())
    }
}

// MARK: - iOS Button Style
struct IOSButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Previews
@available(iOS 26.0, *)
#Preview("Favorites") {
    FavoritesView(contacts: [
        ContactConfig(id: 1, name: "AARP",     avatar: "https://ui-avatars.com/api/?name=AARP&background=E11B22&color=fff&bold=true",   imageURL: nil, description: nil, websiteURL: nil),
        ContactConfig(id: 2, name: "Tim Cook", avatar: "https://ui-avatars.com/api/?name=TC&background=0080F6&color=fff&bold=true",     imageURL: nil, description: nil, websiteURL: nil),
    ])
}

@available(iOS 26.0, *)
#Preview("Phone") {
    PhoneView()
}
