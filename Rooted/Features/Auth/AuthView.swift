import SwiftUI
import UIKit

struct AuthView: View {
    @EnvironmentObject private var session: AppSession
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var gender = "Woman"
    @State private var isCreatingAccount = false

    private let genderOptions = ["Woman", "Man", "Non-binary", "Prefer not to say"]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Rooted")
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                                .foregroundStyle(AppTheme.Colors.primaryText)

                            Text("A cultural community app for finding your people abroad.")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(AppTheme.Colors.secondaryText)
                        }
                        .padding(.top, 32)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(isCreatingAccount ? "Create your account" : "Welcome back")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(AppTheme.Colors.primaryText)

                                if isCreatingAccount {
                                    authField("Full name", text: $fullName)

                                    Picker("Gender", selection: $gender) {
                                        ForEach(genderOptions, id: \.self) { option in
                                            Text(option)
                                        }
                                    }
                                    .tint(AppTheme.Colors.highlight)
                                }

                                authField("Email", text: $email, keyboard: .emailAddress, textInput: .emailAddress)
                                secureField("Password", text: $password)

                                if let errorMessage = session.errorMessage {
                                    Text(errorMessage)
                                        .font(.footnote.weight(.medium))
                                        .foregroundStyle(.red)
                                }

                                Button {
                                    Task {
                                        if isCreatingAccount {
                                            await session.signUp(email: email, password: password, fullName: fullName, gender: gender)
                                        } else {
                                            await session.signIn(email: email, password: password)
                                        }
                                    }
                                } label: {
                                    Text(isCreatingAccount ? "Create Account" : "Sign In")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(AppTheme.Colors.highlight)
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                }

                                Button(isCreatingAccount ? "Already have an account? Sign in" : "Need an account? Create one") {
                                    isCreatingAccount.toggle()
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.Colors.accent)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
    }

    private func authField(
        _ title: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        textInput: UITextContentType? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.secondaryText)

            TextField(title, text: text)
                .textInputAutocapitalization(.never)
                .keyboardType(keyboard)
                .textContentType(textInput)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func secureField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.secondaryText)

            SecureField(title, text: text)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
