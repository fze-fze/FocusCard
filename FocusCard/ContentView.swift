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

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header

                focusCard

                taskList
            }
            .padding()
            .navigationTitle("FocusCard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                addTaskSheet
            }
            .onDisappear {
                stopTimer()
            }
        }
    }

    // MARK: - UI Pieces

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("今天做点什么？")
                    .font(.title2.weight(.semibold))
                Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(isRunning ? "专注中" : "未开始")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial)
                .clipShape(.capsule)
        }
    }

    private var focusCard: some View {
        let progress = 1 - Double(remainingSeconds) / Double(max(totalSeconds, 1))

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("当前任务")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(currentTaskTitle)
                        .font(.headline)
                        .lineLimit(1)
                }
                Spacer()
                Text(timeString(remainingSeconds))
                    .font(.title2.monospacedDigit().weight(.semibold))
            }

            // 进度条
            ZStack(alignment: .leading) {
                GeometryReader { geo in
                    let width = geo.size.width
                    Capsule()
                        .frame(height: 10)
                        .foregroundStyle(.quaternary)

                    Capsule()
                        .frame(width: max(0, width * CGFloat(min(max(progress, 0), 1))), height: 10)
                        .foregroundStyle(.tint)
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

                Button {
                    resetTimer()
                } label: {
                    Label("重置", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            // 小提示
            Text("提示：选中下方一个任务后再开始，会更有仪式感。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isRunning ? Color.accentColor : Color.clear, lineWidth: 2)
                .animation(.easeInOut(duration: 0.25), value: isRunning)
        )
    }

    private var taskList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("任务列表")
                    .font(.headline)
                Spacer()
                Text("\(doneCount)/\(tasks.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            List {
                ForEach($tasks) { $task in
                    HStack(spacing: 12) {
                        Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.isDone ? .green : .secondary)
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    task.isDone.toggle()
                                }
                            }

                        Text(task.title)
                            .strikethrough(task.isDone)
                            .foregroundStyle(task.isDone ? .secondary : .primary)

                        Spacer()

                        if selectedTaskID == task.id {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTaskID = task.id
                    }
                }
                .onDelete { indexSet in
                    tasks.remove(atOffsets: indexSet)
                    if let id = selectedTaskID, tasks.contains(where: { $0.id == id }) == false {
                        selectedTaskID = nil
                    }
                }
            }
            .listStyle(.plain)
            .frame(minHeight: 220)
        }
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
        return "未选择任务（点一下下面的任务）"
    }

    private var doneCount: Int {
        tasks.filter(\.isDone).count
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
