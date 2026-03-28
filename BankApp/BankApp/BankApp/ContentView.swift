import SwiftUI
import Combine

// MARK: - Root ContentView
struct ContentView: View {
    @StateObject private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            DashboardView()
                .navigationTitle("BankApp")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .accounts:
                        AccountsView()
                    case .transfer:
                        TransferView()
                    case .payBills:
                        PayBillsView()
                    case .cards:
                        CardsView()
                    case .support:
                        SupportView()
                    case .settings:
                        SettingsView()
                    }
                }
        }
        .environmentObject(router)
        .sheet(item: $router.pendingConfirmation) { model in
            ConfirmationView(model: model) {
                router.proceed()
            } onCancel: {
                router.cancel()
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    ContentView()
}
// MARK: - Router & Routing
@MainActor
final class Router: ObservableObject {
    @Published var path = NavigationPath()
    @Published var pendingConfirmation: ConfirmationModel?

    private var pendingAction: (() -> Void)?

    func confirm(title: String, message: String, confirmLabel: String = "Confirm", cancelLabel: String = "Cancel", icon: String? = "checkmark.shield", onConfirm: @escaping () -> Void) {
        pendingAction = onConfirm
        pendingConfirmation = ConfirmationModel(title: title, message: message, confirmLabel: confirmLabel, cancelLabel: cancelLabel, iconSystemName: icon)
    }

    func proceed() {
        let action = pendingAction
        pendingAction = nil
        pendingConfirmation = nil
        action?()
    }

    func cancel() {
        pendingAction = nil
        pendingConfirmation = nil
    }

    func confirmThenPush(_ route: AppRoute, info: String) {
        confirm(title: "Proceed to \(route.title)", message: info) { [weak self] in
            self?.path.append(route)
        }
    }

    func confirmBack(info: String = "You are about to go back. Unsaved changes may be lost.") {
        confirm(title: "Confirm Back", message: info, confirmLabel: "Go Back") { [weak self] in
            self?.path.removeLast()
        }
    }
}

enum AppRoute: Hashable {
    case accounts
    case transfer
    case payBills
    case cards
    case support
    case settings

    var title: String {
        switch self {
        case .accounts: return "Accounts"
        case .transfer: return "Transfer"
        case .payBills: return "Pay Bills"
        case .cards: return "Cards"
        case .support: return "Support"
        case .settings: return "Settings"
        }
    }
}

// MARK: - Confirmation Model & View
struct ConfirmationModel: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let confirmLabel: String
    let cancelLabel: String
    let iconSystemName: String?

    static func == (lhs: ConfirmationModel, rhs: ConfirmationModel) -> Bool {
        lhs.id == rhs.id
    }
}

struct ConfirmationView: View {
    let model: ConfirmationModel
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if let icon = model.iconSystemName {
                Image(systemName: icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.tint)
                    .padding(.top, 8)
            }

            Text(model.title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)

            ScrollView {
                Text(model.message)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                Button(role: .cancel) { onCancel() } label: {
                    Text(model.cancelLabel)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button { onConfirm() } label: {
                    Text(model.confirmLabel)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 8)
        }
        .padding()
    }
}

// MARK: - Dashboard
struct DashboardView: View {
    @EnvironmentObject private var router: Router

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                Grid(horizontalSpacing: 16, verticalSpacing: 16) {
                    GridRow {
                        ActionCard(title: "Accounts", subtitle: "Balances & activity", systemImage: "banknote") {
                            router.confirmThenPush(.accounts, info: "View all your accounts, balances, and recent transactions.")
                        }
                        ActionCard(title: "Transfer", subtitle: "Between accounts", systemImage: "arrow.left.arrow.right") {
                            router.confirmThenPush(.transfer, info: "Move money between your accounts or to saved payees.")
                        }
                    }
                    GridRow {
                        ActionCard(title: "Pay Bills", subtitle: "Utilities & more", systemImage: "doc.text") {
                            router.confirmThenPush(.payBills, info: "Pay your utilities, credit cards, and other billers.")
                        }
                        ActionCard(title: "Cards", subtitle: "Manage your cards", systemImage: "creditcard") {
                            router.confirmThenPush(.cards, info: "View card details, limits, and manage controls.")
                        }
                    }
                    GridRow {
                        ActionCard(title: "Support", subtitle: "We're here to help", systemImage: "person.fill.questionmark") {
                            router.confirmThenPush(.support, info: "Contact support, find FAQs, and secure messages.")
                        }
                        ActionCard(title: "Settings", subtitle: "Preferences", systemImage: "gearshape") {
                            router.confirmThenPush(.settings, info: "Security, notifications, and app preferences.")
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("Your Banking")
                .font(.largeTitle.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Screens
struct AccountsView: View {
    @EnvironmentObject private var router: Router

    var body: some View {
        List {
            Section("Checking") {
                Text("Main Checking •••• 1234")
                Text("Joint Checking •••• 5678")
            }
            Section("Savings") {
                Text("High-Yield Savings •••• 9012")
            }
        }
        .navigationTitle("Accounts")
        .navigationBarBackButtonHidden(true)
        .toolbar { ConfirmingBackToolbar() }
    }
}

struct TransferView: View {
    @EnvironmentObject private var router: Router
    @State private var amount: String = ""

    var body: some View {
        Form {
            Section("From / To") {
                Text("From: Main Checking")
                Text("To: High-Yield Savings")
            }
            Section("Amount") {
                TextField("0.00", text: $amount)
                    .keyboardType(.decimalPad)
            }
            Section {
                Button("Review Transfer") {
                    router.confirm(title: "Review Transfer", message: "Transfer $\(amount.isEmpty ? "0.00" : amount) from Main Checking to High-Yield Savings.", confirmLabel: "Submit", icon: "arrow.right.circle") {
                        // After confirming result, we could show a result or pop.
                        router.confirm(title: "Transfer Submitted", message: "Your transfer has been successfully submitted.", confirmLabel: "Done") {
                            router.confirmBack(info: "Return to previous screen.")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Transfer")
        .navigationBarBackButtonHidden(true)
        .toolbar { ConfirmingBackToolbar() }
    }
}

struct PayBillsView: View {
    @EnvironmentObject private var router: Router

    var body: some View {
        List {
            Text("Electric Utility")
            Text("Mobile Carrier")
            Text("Water & Sewage")
        }
        .navigationTitle("Pay Bills")
        .navigationBarBackButtonHidden(true)
        .toolbar { ConfirmingBackToolbar() }
    }
}

struct CardsView: View {
    @EnvironmentObject private var router: Router

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("Card Controls")
                .font(.title3.bold())
            Button("Freeze Card") {
                router.confirm(title: "Freeze Card", message: "This will temporarily disable your card for purchases.", confirmLabel: "Freeze", icon: "snowflake") {
                    router.confirm(title: "Card Frozen", message: "Your card is now frozen. You can unfreeze it anytime.", confirmLabel: "OK") { }
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .navigationTitle("Cards")
        .navigationBarBackButtonHidden(true)
        .toolbar { ConfirmingBackToolbar() }
    }
}

struct SupportView: View {
    @EnvironmentObject private var router: Router

    var body: some View {
        List {
            Text("Contact Us")
            Text("Secure Messages")
            Text("FAQs")
        }
        .navigationTitle("Support")
        .navigationBarBackButtonHidden(true)
        .toolbar { ConfirmingBackToolbar() }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var router: Router
    @State private var notificationsEnabled = true

    var body: some View {
        Form {
            Toggle("Notifications", isOn: $notificationsEnabled)
            Button("Sign Out") {
                router.confirm(title: "Sign Out", message: "Are you sure you want to sign out?", confirmLabel: "Sign Out", icon: "rectangle.portrait.and.arrow.right") {
                    // In a real app: clear credentials and go to login screen.
                }
            }
            .tint(.red)
        }
        .navigationTitle("Settings")
        .navigationBarBackButtonHidden(true)
        .toolbar { ConfirmingBackToolbar() }
    }
}

// MARK: - Shared Back Toolbar
struct ConfirmingBackToolbar: ToolbarContent {
    @EnvironmentObject private var router: Router

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.confirmBack(info: "You are about to go back. Unsaved changes may be lost.")
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
        }
    }
}

