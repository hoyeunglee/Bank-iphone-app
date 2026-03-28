import SwiftUI
import Combine
import SafariServices
import UIKit

// MARK: - Root ContentView
struct ContentView: View {
    @StateObject private var router = Router()
    @State private var isAuthenticated = false

    var body: some View {
        NavigationStack(path: $router.path) {
            Group {
                if isAuthenticated {
                    DashboardView()
                        .navigationTitle("BankApp")
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    LoginView {
                        isAuthenticated = true
                    }
                    .navigationTitle("Welcome")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
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
                case .createAccount:
                    CreateAccountView()
                case .statements:
                    StatementsView()
                case .investment:
                    InvestmentView()
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
        .sheet(item: $router.pendingWebLink) { link in
            SafariWebView(url: link.url)
                .ignoresSafeArea()
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
    @Published var pendingWebLink: WebLink?

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
    case createAccount
    case statements
    case investment

    var title: String {
        switch self {
        case .accounts: return "Accounts"
        case .transfer: return "Transfer"
        case .payBills: return "Pay Bills"
        case .cards: return "Cards"
        case .support: return "Support"
        case .settings: return "Settings"
        case .createAccount: return "Create Account"
        case .statements: return "Statements"
        case .investment: return "Investments"
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

// MARK: - Web Link Model & Safari Wrapper
struct WebLink: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    static func == (lhs: WebLink, rhs: WebLink) -> Bool { lhs.id == rhs.id }
}

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
}

// MARK: - Login
struct LoginView: View {
    @EnvironmentObject private var router: Router
    let onAuthenticated: () -> Void

    @State private var username: String = ""
    @State private var password: String = ""

    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://www.apple.com/legal/privacy/en-ww/")!

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

            VStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.tint)
                Text("Welcome to BankApp")
                    .font(.title2.bold())
            }

            VStack(spacing: 16) {
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .submitLabel(.next)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .submitLabel(.go)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text("Hint: username ‘customer’, password ‘password’")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)

            Button {
                let enteredUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
                router.confirm(title: "Confirm Login", message: "Log in as \(enteredUser.isEmpty ? "customer" : enteredUser)?", confirmLabel: "Log In", icon: "lock.open") {
                    let isValid = enteredUser.lowercased() == "customer" && password == "password"
                    if isValid {
                        router.confirm(title: "Login Successful", message: "Welcome back, \(enteredUser.isEmpty ? "customer" : enteredUser).", confirmLabel: "Continue", icon: "checkmark.circle") {
                            onAuthenticated()
                        }
                    } else {
                        router.confirm(title: "Login Failed", message: "Invalid username or password. Hint: customer / password", confirmLabel: "Try Again", icon: "exclamationmark.triangle") { }
                    }
                }
            } label: {
                Text("Log In")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            Button {
                router.confirmThenPush(.createAccount, info: "Start account creation by scanning your HKID or Passport with the camera. This is a simulation.")
            } label: {
                Text("Create Account")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 8) {
                Button {
                    router.confirm(title: "Open Terms of Use", message: "This will open Apple’s Standard EULA in a browser.", confirmLabel: "Open", icon: "safari") {
                        router.pendingWebLink = WebLink(url: termsURL)
                    }
                } label: {
                    Text("Terms of Use")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                Button {
                    router.confirm(title: "Open Privacy Policy", message: "This will open Apple’s Privacy Policy in a browser.", confirmLabel: "Open", icon: "safari") {
                        router.pendingWebLink = WebLink(url: privacyURL)
                    }
                } label: {
                    Text("Privacy Policy")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                Button {
                    router.confirmThenPush(.support, info: "Contact our support team for assistance.")
                } label: {
                    Text("Support")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

// MARK: - Create Account (Simulation)
private enum DocumentType { case hkid, passport; var displayName: String { self == .hkid ? "HKID" : "Passport" } }

struct CreateAccountView: View {
    @EnvironmentObject private var router: Router
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var selectedDoc: DocumentType?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.tint)
                    .padding(.top)

                Text("Create a New Account")
                    .font(.title2.bold())

                Text("Use your device camera to scan your HKID card or Passport. This is a simulation; no data is sent to a server.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if let img = capturedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(alignment: .bottomLeading) {
                            if let doc = selectedDoc {
                                Text("Scanned: \(doc.displayName)")
                                    .font(.caption)
                                    .padding(6)
                                    .background(.thinMaterial, in: Capsule())
                                    .padding(8)
                            }
                        }
                }

                HStack {
                    Button {
                        router.confirm(title: "Scan HKID", message: "Open camera to scan your HKID?", confirmLabel: "Scan", icon: "camera") {
                            selectedDoc = .hkid
                            showCamera = true
                        }
                    } label: {
                        Label("Scan HKID", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        router.confirm(title: "Scan Passport", message: "Open camera to scan your Passport?", confirmLabel: "Scan", icon: "camera") {
                            selectedDoc = .passport
                            showCamera = true
                        }
                    } label: {
                        Label("Scan Passport", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                if capturedImage != nil {
                    Button {
                        router.confirm(title: "Create Account", message: "Proceed to create your bank account with the scanned document? (Simulation)", confirmLabel: "Create", icon: "person.badge.plus") {
                            router.confirm(title: "Account Created", message: "Your bank account has been created (simulation).", confirmLabel: "Done", icon: "checkmark.circle") {
                                router.confirmBack(info: "Return to previous screen.")
                            }
                        }
                    } label: {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Text("Note: Please add NSCameraUsageDescription to your Info.plist for camera access.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Create Account")
        .navigationBarBackButtonHidden(true)
        .toolbar { ConfirmingBackToolbar() }
        .sheet(isPresented: $showCamera) {
            CameraCaptureView(image: $capturedImage)
                .ignoresSafeArea()
        }
    }
}

struct CameraCaptureView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraCaptureView
        init(_ parent: CameraCaptureView) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.originalImage] as? UIImage {
                parent.image = img
            }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
}

// MARK: - Statements
struct StatementItem: Identifiable {
    let id = UUID()
    let title: String
}

struct StatementsView: View {
    @EnvironmentObject private var router: Router
    @State private var viewingStatement: StatementItem?

    private let bankMonths = ["Jan 2026", "Feb 2026", "Mar 2026"]
    private let investmentMonths = ["Jan 2026", "Feb 2026", "Mar 2026"]

    var body: some View {
        List {
            Section("Bank Statements") {
                ForEach(bankMonths, id: \.self) { month in
                    Button(month) {
                        router.confirm(title: "Open Statement", message: "Open bank statement for \(month)?", confirmLabel: "Open", icon: "doc.text") {
                            viewingStatement = StatementItem(title: "Bank Statement - \(month)")
                        }
                    }
                }
            }
            Section("Investment Statements") {
                ForEach(investmentMonths, id: \.self) { month in
                    Button(month) {
                        router.confirm(title: "Open Statement", message: "Open investment statement for \(month)?", confirmLabel: "Open", icon: "doc.text") {
                            viewingStatement = StatementItem(title: "Investment Statement - \(month)")
                        }
                    }
                }
            }
        }
        .navigationTitle("Statements")
        .navigationBarBackButtonHidden(true)
        .toolbar { ConfirmingBackToolbar() }
        .sheet(item: $viewingStatement) { item in
            StatementDetailView(title: item.title)
        }
    }
}

struct StatementDetailView: View, Identifiable {
    let id = UUID()
    let title: String
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title2.bold())
            Spacer()
            Image(systemName: "doc.richtext")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("PDF preview (simulation)")
                .foregroundStyle(.secondary)
            Spacer()
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
                        ActionCard(title: "Statements", subtitle: "Monthly statements", systemImage: "doc.text.magnifyingglass") {
                            router.confirmThenPush(.statements, info: "View your monthly bank and investment statements.")
                        }
                        ActionCard(title: "Investments", subtitle: "Buy & sell stocks", systemImage: "chart.line.uptrend.xyaxis") {
                            router.confirmThenPush(.investment, info: "Access your investment account to buy and sell stocks.")
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.confirmThenPush(.support, info: "Contact support by phone or email.")
                } label: {
                    Label("Support", systemImage: "lifepreserver")
                }
            }
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

struct InvestmentView: View {
    @EnvironmentObject private var router: Router

    private struct Position: Identifiable { let id = UUID(); let symbol: String; let shares: Double; let value: Double }
    private let positions = [
        Position(symbol: "AAPL", shares: 12, value: 2400),
        Position(symbol: "TSLA", shares: 5, value: 1100),
        Position(symbol: "0700.HK", shares: 30, value: 12000)
    ]

    var body: some View {
        List {
            Section("Positions") {
                ForEach(positions) { p in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(p.symbol).font(.headline)
                            Text("Shares: \(p.shares, specifier: "%.2f")").font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(currency(p.value)).monospacedDigit().font(.headline)
                    }
                }
            }

            Section("Actions") {
                Button("Buy Stock") {
                    router.confirm(title: "Buy Stock", message: "Proceed to buy stock?", confirmLabel: "Buy", icon: "cart.badge.plus") {
                        router.confirm(title: "Order Placed", message: "Your buy order has been submitted (simulation).", confirmLabel: "OK", icon: "checkmark.circle") { }
                    }
                }
                Button("Sell Stock") {
                    router.confirm(title: "Sell Stock", message: "Proceed to sell stock?", confirmLabel: "Sell", icon: "cart.badge.minus") {
                        router.confirm(title: "Order Placed", message: "Your sell order has been submitted (simulation).", confirmLabel: "OK", icon: "checkmark.circle") { }
                    }
                }
            }
        }
        .navigationTitle("Investments")
        .navigationBarBackButtonHidden(true)
        .toolbar { ConfirmingBackToolbar() }
    }

    private func currency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
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
    @State private var showAccountNumber = false
    @State private var showBalance = false

    private let checkingAccounts: [BankAccount] = [
        BankAccount(name: "Main Checking", number: "1234567812341234", balance: 2534.12),
        BankAccount(name: "Joint Checking", number: "5678567856785678", balance: 812.33)
    ]
    private let savingsAccounts: [BankAccount] = [
        BankAccount(name: "High-Yield Savings", number: "9012901290129012", balance: 10234.45)
    ]

    var body: some View {
        List {
            Section("Checking") {
                ForEach(checkingAccounts) { account in
                    AccountRow(account: account, showNumber: showAccountNumber, showBalance: showBalance)
                }
            }
            Section("Savings") {
                ForEach(savingsAccounts) { account in
                    AccountRow(account: account, showNumber: showAccountNumber, showBalance: showBalance)
                }
            }
        }
        .navigationTitle("Accounts")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ConfirmingBackToolbar()
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    let willShow = !showAccountNumber
                    let title = willShow ? "Show Account Numbers" : "Hide Account Numbers"
                    let message = willShow ? "Account numbers will be visible." : "Account numbers will be hidden."
                    let confirm = willShow ? "Show" : "Hide"
                    router.confirm(title: title, message: message, confirmLabel: confirm, icon: "eye") {
                        showAccountNumber.toggle()
                    }
                } label: {
                    Label("Toggle Account Numbers", systemImage: showAccountNumber ? "eye.slash" : "eye")
                }

                Button {
                    let willShow = !showBalance
                    let title = willShow ? "Show Balances" : "Hide Balances"
                    let message = willShow ? "Balances will be visible." : "Balances will be hidden."
                    let confirm = willShow ? "Show" : "Hide"
                    router.confirm(title: title, message: message, confirmLabel: confirm, icon: "eye") {
                        showBalance.toggle()
                    }
                } label: {
                    Label("Toggle Balances", systemImage: showBalance ? "eye.slash" : "eye")
                }
            }
        }
    }
}

struct BankAccount: Identifiable {
    let id = UUID()
    let name: String
    let number: String
    let balance: Double
}

struct AccountRow: View {
    let account: BankAccount
    let showNumber: Bool
    let showBalance: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.headline)
                Text(numberText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textSelection(.disabled)
            }
            Spacer(minLength: 12)
            Text(balanceText)
                .font(.headline)
                .monospacedDigit()
                .frame(alignment: .trailing)
        }
        .contentShape(Rectangle())
    }

    private var numberText: String {
        if showNumber {
            return formattedNumber(account.number)
        } else {
            return maskedNumber(account.number)
        }
    }

    private var balanceText: String {
        if showBalance {
            return currency(account.balance)
        } else {
            return "••••"
        }
    }

    private func formattedNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        var chunks: [String] = []
        var chunk = ""
        for (idx, ch) in digits.enumerated() {
            chunk.append(ch)
            if (idx + 1) % 4 == 0 {
                chunks.append(chunk)
                chunk = ""
            }
        }
        if !chunk.isEmpty { chunks.append(chunk) }
        return chunks.joined(separator: " ")
    }

    private func maskedNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        let last4 = digits.suffix(4)
        return "•••• \(String(last4))"
    }

    private func currency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
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
            Section("Contact") {
                LabeledContent("Phone", value: "+852 1234 5678")
                LabeledContent("Email", value: "support@bankapp.example")
            }
            Section("Actions") {
                Button("Call Support") {
                    router.confirm(title: "Call Support", message: "Call +852 1234 5678? (Simulation)", confirmLabel: "Call", icon: "phone") { }
                }
                Button("Email Support") {
                    router.confirm(title: "Email Support", message: "Compose email to support@bankapp.example? (Simulation)", confirmLabel: "Compose", icon: "envelope") { }
                }
            }
            Section("FAQs") {
                Text("How do I reset my password?")
                Text("How do I change my address?")
            }
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

