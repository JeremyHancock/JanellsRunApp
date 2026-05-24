import SwiftUI

struct FeedbackSheet: View {
    @State var feedbackType: FeedbackType
    var userName: String?
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var submitted = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if submitted {
                    successView
                } else {
                    formView
                }
            }
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(submitted ? "Done" : "Cancel") { dismiss() }
                }
                if !submitted {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Submit") { submit() }
                            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty
                                      || description.trimmingCharacters(in: .whitespaces).isEmpty
                                      || isSubmitting)
                    }
                }
            }
        }
    }

    private var formView: some View {
        Form {
            Section {
                Picker("Type", selection: $feedbackType) {
                    ForEach(FeedbackType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(feedbackType == .bug ? "What went wrong?" : "What would you like?") {
                TextField("Title", text: $title)
                TextEditor(text: $description)
                    .frame(minHeight: 120)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .disabled(isSubmitting)
        .overlay {
            if isSubmitting {
                ProgressView()
            }
        }
    }

    private var successView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.teal)
            Text("Thanks for your feedback!")
                .font(.headline)
            Text("We'll take a look soon.")
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func submit() {
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                try await FeedbackService.submit(
                    type: feedbackType,
                    title: title,
                    description: description,
                    userName: userName
                )
                submitted = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
