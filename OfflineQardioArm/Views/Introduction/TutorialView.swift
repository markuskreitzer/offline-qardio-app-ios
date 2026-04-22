import SwiftUI

struct TutorialView : View {
    @AppStorage("tutorialCompleted") var tutorialCompleted = false
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    private let pagesCount = 5

    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $currentPage) {

                    TutorialPage(title: "Welcome to Qardio", description: "Use your QardioArm Blood Pressure Monitor without their servers.", imageName: "fuelStation").tag(0)
                    SetUpHealthKitView().tag(1)
                    TutorialPage(title: "App Walkthrough", description: "This is your blood pressure reading app. Connect your QardioArm Blood Pressure Monitor using the Connect button on the bottom left if it doesn't show up.", imageName: "ConnectToQardio").tag(2)
                    TutorialPage(title: "App Walkthrough", description: "Use the Guest Mode toggle to take a reading without saving it to Apple Health.", imageName: "GuestMode").tag(3)
                    TutorialPage(title: "App Walkthrough", description: "Tap Get Reading to request a blood pressure reading.", imageName: "GetReading").tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                HStack {
                    Button("Skip") {
                        tutorialCompleted = true
                    }
                    .padding()

                    Spacer()

                    if currentPage < pagesCount - 1 {
                        Button("Next") {
                            currentPage += 1
                        }
                        .padding()
                    } else {
                        Button("Done") {
                            tutorialCompleted = true
                            dismiss()
                        }
                        .padding()
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    TutorialView()
}
