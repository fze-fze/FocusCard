//
//  ContentView.swift
//  FocusCard
//
//  Created by fze on 2026/2/7.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Timer
    @State private var isRunning = false
    @State private var totalSeconds: Int = 25 * 60
    @State private var remainingSeconds: Int = 25 * 60
    @State private var timer: Timer?

    // MARK: - Tasks
    struct TaskItem: Identifiable {
        let id = UUID()
        var title: String
        var isDone: Bool = false
    }

    @State private var tasks: [TaskItem] = [
        .init(title: "欢迎加入FocusCard！"),
        .init(title: "训练您的专注模式")
    ]

    @State private var selectedTaskID: UUID?
    @State private var showAddTask = false
    @State private var newTaskTitle = ""

    // MARK: - Navigation
    enum Tab: String, CaseIterable {
        case timer
        case tasks
    }

    @State private var selectedTab: Tab = .timer

    // MARK: - Collapsible Sections
    @State private var showPending = true
    @State private var showDone = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .timer:
                        timerPage
                    case .tasks:
                        tasksPage
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomNavigator
        }
        .sheet(isPresented: $showAddTask) {
            addTaskSheet
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.09, blue: 0.12),
                    Color(red: 0.10, green: 0.13, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.22), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
                .frame(width: 260, height: 260)
                .offset(x: 140, y: -220)
                .blendMode(.screen)
                .opacity(0.9)

            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(18))
                .offset(x: -170, y: 260)
                .blur(radius: 2)
        }
    }

    // MARK: - Pages

    private var timerPage: some View {
        ScrollView {
            VStack(spacing: 20) {
                titleHeader

                focusCard

                statsCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
    }

    private var tasksPage: some View {
        ScrollView {
            VStack(spacing: 16) {
                tasksHeader

                taskSection(
                    title: "未完成",
                    count: pendingIndices.count,
                    isExpanded: $showPending
                ) {
                    if pendingIndices.isEmpty {
                        emptyState(text: "今天没有待办，保持专注节奏")
                    } else {
                        VStack(spacing: 10) {
                            ForEach(pendingIndices, id: \.self) { index in
                                taskRow(task: $tasks[index], index: index)
                            }
                        }
                    }
                }

                taskSection(
                    title: "已完成",
                    count: doneIndices.count,
                    isExpanded: $showDone
                ) {
                    if doneIndices.isEmpty {
                        emptyState(text: "完成后的项目会出现在这里")
                    } else {
                        VStack(spacing: 10) {
                            ForEach(doneIndices, id: \.self) { index in
                                taskRow(task: $tasks[index], index: index)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
    }

    // MARK: - UI Pieces

    private var titleHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text("FocusCard")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
            statusPill
        }
        .foregroundStyle(.white)
    }

    private var tasksHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text("任务清单")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                Text("专注从清晰开始")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
            Button {
                showAddTask = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.18))
                    )
            }
        }
        .foregroundStyle(.white)
    }

    private var statusPill: some View {
        Text(isRunning ? "专注中" : "未开始")
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.16))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
    }

    private var focusCard: some View {
        let progress = 1 - Double(remainingSeconds) / Double(max(totalSeconds, 1))

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("当前任务")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))

                    Text(currentTaskTitle)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                }
                Spacer()
                Text(timeString(remainingSeconds))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(.white)

            ZStack(alignment: .leading) {
                GeometryReader { geo in
                    let width = geo.size.width
                    Capsule()
                        .frame(height: 10)
                        .foregroundStyle(.white.opacity(0.12))

                    Capsule()
                        .frame(width: max(0, width * CGFloat(min(max(progress, 0), 1))), height: 10)
                        .foregroundStyle(LinearGradient(colors: [Color(red: 0.78, green: 0.95, blue: 0.88), Color(red: 0.34, green: 0.78, blue: 0.72)], startPoint: .leading, endPoint: .trailing))
                        .animation(.smooth, value: remainingSeconds)
                }
            }
            .frame(height: 10)

            HStack(spacing: 10) {
                Button {
                    toggleTimer()
                } label: {
                    Label(isRunning ? "暂停" : "开始", systemImage: isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.32, green: 0.82, blue: 0.75))

                Button {
                    resetTimer()
                } label: {
                    Label("重置", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.5))
            }
            .foregroundStyle(.white)

            Text("提示：先挑一个任务，再进入专注。")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isRunning ? Color(red: 0.34, green: 0.78, blue: 0.72) : Color.white.opacity(0.12), lineWidth: 1.5)
                .animation(.easeInOut(duration: 0.25), value: isRunning)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 14, x: 0, y: 8)
    }

    private var statsCard: some View {
        HStack(spacing: 12) {
            statItem(title: "已完成", value: "\(doneCount)")
            Divider()
                .frame(height: 36)
                .overlay(Color.white.opacity(0.2))
            statItem(title: "待完成", value: "\(pendingIndices.count)")
            Divider()
                .frame(height: 36)
                .overlay(Color.white.opacity(0.2))
            statItem(title: "总任务", value: "\(tasks.count)")
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .foregroundStyle(.white)
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
        }
        .frame(maxWidth: .infinity)
    }

    private func taskSection<Content: View>(
        title: String,
        count: Int,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.snappy) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                        )
                    Spacer()
                    Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                content()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func taskRow(task: Binding<TaskItem>, index: Int) -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy) {
                    task.wrappedValue.isDone.toggle()
                }
            } label: {
                Image(systemName: task.wrappedValue.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(task.wrappedValue.isDone ? Color(red: 0.46, green: 0.86, blue: 0.72) : .white.opacity(0.5))
            }
            .buttonStyle(.plain)

            Text(task.wrappedValue.title)
                .font(.body)
                .foregroundStyle(task.wrappedValue.isDone ? .white.opacity(0.5) : .white)
                .strikethrough(task.wrappedValue.isDone)

            Spacer()

            if selectedTaskID == task.wrappedValue.id {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Color(red: 0.44, green: 0.82, blue: 0.76))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTaskID = task.wrappedValue.id
        }
        .contextMenu {
            Button(role: .destructive) {
                deleteTask(at: index)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private func emptyState(text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(.white.opacity(0.6))
            Text(text)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var bottomNavigator: some View {
        HStack(spacing: 12) {
            navButton(
                title: "计时",
                systemImage: "timer",
                tab: .timer
            )
            navButton(
                title: "任务",
                systemImage: "checklist",
                tab: .tasks
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    private func navButton(title: String, systemImage: String, tab: Tab) -> some View {
        Button {
            withAnimation(.snappy) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(selectedTab == tab ? Color(red: 0.10, green: 0.13, blue: 0.16) : .white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selectedTab == tab ? Color.white.opacity(0.9) : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }

    private var addTaskSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("输入任务标题…", text: $newTaskTitle)
                    .textFieldStyle(.roundedBorder)

                Button {
                    addTask()
                } label: {
                    Text("添加任务")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("新增任务")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") { showAddTask = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers

    private var currentTaskTitle: String {
        if let id = selectedTaskID, let t = tasks.first(where: { $0.id == id }) {
            return t.title
        }
        return "未选择任务"
    }

    private var doneCount: Int {
        tasks.filter(\.isDone).count
    }

    private var pendingIndices: [Int] {
        tasks.indices.filter { tasks[$0].isDone == false }
    }

    private var doneIndices: [Int] {
        tasks.indices.filter { tasks[$0].isDone }
    }

    private func deleteTask(at index: Int) {
        let id = tasks[index].id
        tasks.remove(at: index)
        if selectedTaskID == id {
            selectedTaskID = nil
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func toggleTimer() {
        if isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                stopTimer()
            }
        }
    }

    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        stopTimer()
        remainingSeconds = totalSeconds
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard title.isEmpty == false else { return }
        tasks.insert(TaskItem(title: title), at: 0)
        newTaskTitle = ""
        showAddTask = false
    }
}


#Preview {
    ContentView()
}
