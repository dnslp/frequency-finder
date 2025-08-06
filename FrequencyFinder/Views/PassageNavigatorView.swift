import SwiftUI

struct PassageNavigatorView: View {
    @ObservedObject var viewModel: ReadingPassageViewModel
    @State private var scrollOffset: CGFloat = .zero
    @State private var scrollContentSize: CGSize = .zero
    @State private var isAutoScrolling = false
    @State private var scrollSpeed: Double = 50.0
    @State private var autoScrollTimer: Timer?

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        let passage = ReadingPassage.passages[viewModel.selectedPassageIndex]

        ZStack {
            HStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 100)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.goToPreviousPassage()
                    }
                Spacer()
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 100)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.goToNextPassage()
                    }
            }
            .zIndex(1)

            VStack(spacing: 16) {
                // MARK: - Passage Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                    Text(passage.title)
                        .font(Font.custom(viewModel.selectedFont, size: viewModel.fontSize + 4).bold())
                    Spacer()
                    Text(passage.skillFocus)
                        .font(.caption2.bold())
                        .padding(6)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(8)
                }

                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text(passage.text)
                                .font(Font.custom(viewModel.selectedFont, size: viewModel.fontSize))
                                .lineSpacing(viewModel.fontSize * 0.2)
                                .multilineTextAlignment(.leading)
                                .background(
                                    GeometryReader { proxy in
                                        Color.clear.onAppear {
                                            scrollContentSize = proxy.size
                                        }
                                    }
                                )
                        }
                        .id("passageTextContainer")
                        .padding(.horizontal, 4)

                    }
                    .onChange(of: scrollOffset) { offset in
                        scrollViewProxy.scrollTo("passageTextContainer", anchor: UnitPoint(x: 0, y: offset / scrollContentSize.height))
                    }
                }
                .frame(height: 300)
            }

            // MARK: - Navigation and Controls
            VStack(spacing: 12) {
                HStack {
                    // Previous Button
                    Button(action: { viewModel.goToPreviousPassage() }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(viewModel.selectedPassageIndex == 0)

                    Spacer()

                    // Breadcrumb
                    HStack(spacing: 8) {
                        ForEach(0..<ReadingPassage.passages.count, id: \.self) { index in
                            Circle()
                                .fill(index == viewModel.selectedPassageIndex ? Color.accentColor : Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                    }

                    Spacer()

                    // Next Button
                    Button(action: { viewModel.goToNextPassage() }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(viewModel.selectedPassageIndex == ReadingPassage.passages.count - 1)
                }
                .font(.title2)

                // Auto-scroll controls
                HStack {
                    Picker("Scroll Mode", selection: $isAutoScrolling) {
                        Text("Manual").tag(false)
                        Text("Auto").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    if isAutoScrolling {
                        HStack {
                            Button(action: { scrollSpeed = max(10, scrollSpeed - 10) }) {
                                Image(systemName: "minus")
                            }
                            Text("\(Int(scrollSpeed))")
                            Button(action: { scrollSpeed = min(200, scrollSpeed + 10) }) {
                                Image(systemName: "plus")
                            }
                        }
                        .padding(.leading)
                    }
                }
            }
        }
        .onChange(of: isAutoScrolling) { autoScrolling in
            if autoScrolling {
                startAutoScroll()
            } else {
                stopAutoScroll()
            }
        }
        .onDisappear(perform: stopAutoScroll)
        .offset(x: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    self.dragOffset = gesture.translation.width
                }
                .onEnded { gesture in
                    if gesture.translation.width < -100 {
                        viewModel.goToNextPassage()
                    } else if gesture.translation.width > 100 {
                        viewModel.goToPreviousPassage()
                    }
                    withAnimation {
                        self.dragOffset = 0
                    }
                }
        )
    }

    private func startAutoScroll() {
        stopAutoScroll() // Ensure no existing timer is running
        let scrollViewHeight = 300.0
        let scrollableHeight = max(0, scrollContentSize.height - scrollViewHeight)

        guard scrollableHeight > 0 else { return }

        let duration = scrollableHeight / scrollSpeed
        var elapsed: TimeInterval = 0
        let interval: TimeInterval = 0.1

        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            elapsed += interval
            let progress = elapsed / duration
            scrollOffset = min(scrollableHeight, scrollableHeight * progress)

            if progress >= 1.0 {
                timer.invalidate()
                isAutoScrolling = false
            }
        }
    }

    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
}
