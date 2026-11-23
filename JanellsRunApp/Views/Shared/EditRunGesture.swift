import SwiftUI

/// Long-press on a run's row opens the edit sheet, the same way wherever a
/// run appears.
private struct EditRunGesture: ViewModifier {
    let run: Run
    let onTap: (() -> Void)?
    @State private var isEditing = false

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture { onTap?() }
            .onLongPressGesture { isEditing = true }
            .sheet(isPresented: $isEditing) {
                EditRunSheet(run: run)
            }
    }
}

extension View {
    /// Long-press edits the run. A row that also responds to a tap passes it
    /// here, because a NavigationLink or Button would swallow the long-press.
    func editsRun(_ run: Run, onTap: (() -> Void)? = nil) -> some View {
        modifier(EditRunGesture(run: run, onTap: onTap))
    }
}
