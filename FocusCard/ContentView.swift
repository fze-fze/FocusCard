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
    struct TaskItem: Identifiable, Equatable {
        let id = UUID()
        var title: String
        var isDone: Bool = false
        var labelIndex: Int = 0
    }

    @State private var tasks: [TaskItem] = [
        .init(title: "欢迎加入FocusCard！"),
        .init(title: "训练您的专注模式")
    ]

    @State private var selectedTaskID: UUID?
    @State private var showAddTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskLabelIndex = 0

    // MARK: - Navigation
    enum Tab: String, CaseIterable {
        case collect
        case timer
        case tasks
    }

    @State private var selectedTab: Tab = .timer

    // MARK: - Collapsible Sections
    @State private var showPending = true
    @State private var showDone = false

    // MARK: - Collection Labels
    @State private var collectionLabels: [String] = [
        "学习", "工作", "运动", "阅读", "生活", "灵感"
    ]

    @State private var showEditLabels = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .collect:
                        collectPage
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
        .sheet(isPresented: $showEditLabels) {
            editLabelsSheet
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
        List {
            tasksHeaderRow

            taskSectionRow(
                title: "未完成",
                count: pendingIndices.count,
                isExpanded: $showPending,
                accent: Color(red: 0.33, green: 0.82, blue: 0.74)
            )

            if showPending {
                if pendingIndices.isEmpty {
                    emptyStateRow(text: "今天没有待办，保持专注节奏")
                } else {
                    ForEach(pendingIndices, id: \.self) { index in
                        taskRow(task: $tasks[index], index: index)
                    }
                }
            }

            taskSectionRow(
                title: "已完成",
                count: doneIndices.count,
                isExpanded: $showDone,
                accent: Color(red: 0.55, green: 0.64, blue: 0.72)
            )

            if showDone {
                if doneIndices.isEmpty {
                    emptyStateRow(text: "完成后的项目会出现在这里")
                } else {
                    ForEach(doneIndices, id: \.self) { index in
                        taskRow(task: $tasks[index], index: index)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    private var collectPage: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                collectHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 18)

                GeometryReader { gridGeo in
                    let spacing: CGFloat = 16
                    let cellHeight = (gridGeo.size.height - spacing * 2) / 3

                    LazyVGrid(columns: collectionColumns, spacing: spacing) {
                        ForEach(collectionLabels.indices, id: \.self) { index in
                            collectionCell(index: index, height: cellHeight)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .animation(.snappy, value: tasks)
    }

    // MARK: - Headers

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

    private var collectHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text("收集")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                Text("完成后会被钉在对应标签下")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
            Button {
                showEditLabels = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                    Text("编辑标签")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                )
            }
        }
        .foregroundStyle(.white)
    }

    private var tasksHeaderRow: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text("任务")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                Text("专注从清晰开始")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
            Button {
                showAddTask = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("新建任务")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                )
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 6, trailing: 16))
        .listRowSeparator(.hidden)
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

    // MARK: - Timer UI

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

    // MARK: - Tasks UI

    private func taskSectionRow(title: String, count: Int, isExpanded: Binding<Bool>, accent: Color) -> some View {
        Button {
            withAnimation(.snappy) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(accent)
                    .frame(width: 4, height: 16)
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
                            .fill(accent.opacity(0.18))
                    )
                Spacer()
                Image(systemName: isExpanded.wrappedValue ? "chevron.down" : "chevron.right")
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 6, trailing: 16))
        .listRowSeparator(.hidden)
    }

    private func taskRow(task: Binding<TaskItem>, index: Int) -> some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(collectionLabels.indices, id: \.self) { labelIndex in
                    Button(labelName(for: labelIndex)) {
                        task.wrappedValue.labelIndex = labelIndex
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "tag")
                        .font(.caption)
                    Text(labelName(for: task.wrappedValue.labelIndex))
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                )
            }

            Text(task.wrappedValue.title)
                .font(.body)
                .foregroundStyle(task.wrappedValue.isDone ? .white.opacity(0.5) : .white)
                .strikethrough(task.wrappedValue.isDone)

            Spacer()

            if selectedTaskID == task.wrappedValue.id {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Color(red: 0.44, green: 0.82, blue: 0.76))
            }

            Button {
                withAnimation(.snappy) {
                    task.wrappedValue.isDone.toggle()
                }
            } label: {
                Image(systemName: task.wrappedValue.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(task.wrappedValue.isDone ? Color(red: 0.46, green: 0.86, blue: 0.72) : .white.opacity(0.55))
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(task.wrappedValue.isDone ? Color.white.opacity(0.05) : Color.white.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(task.wrappedValue.isDone ? Color.white.opacity(0.08) : Color.white.opacity(0.14), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTaskID = task.wrappedValue.id
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteTask(at: index)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowSeparator(.hidden)
    }

    private func emptyStateRow(text: String) -> some View {
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
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 6, trailing: 16))
        .listRowSeparator(.hidden)
    }

    // MARK: - Collection UI

    private var collectionColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }

    private func collectionCell(index: Int, height: CGFloat) -> some View {
        let label = labelName(for: index)
        let cards = completedTasks(for: index)
        let visibleCards = Array(cards.prefix(3))

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(cards.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                    )
            }

            ZStack(alignment: .top) {
                if cards.isEmpty {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .frame(height: 90)
                        .overlay(
                            Text("暂无卡片")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.45))
                        )
                        .padding(.top, 6)
                } else {
                    ZStack(alignment: .topLeading) {
                        ForEach(Array(visibleCards.enumerated()), id: \.element.id) { offset, item in
                            collectionCard(title: item.title, isTop: offset == 0)
                                .offset(x: CGFloat(offset) * 5, y: CGFloat(offset) * 12)
                                .rotationEffect(offset == 1 ? .degrees(-4) : .degrees(0))
                                .zIndex(Double(10 - offset))
                        }
                    }
                    .padding(.top, 8)
                    .frame(height: 90)
                }
            }

            if cards.count > 3 {
                Text("+\(cards.count - 3) 张")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func collectionCard(title: String, isTop: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.96, green: 0.95, blue: 0.92), Color(red: 0.92, green: 0.90, blue: 0.88)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(maxWidth: .infinity, minHeight: 54)
            .overlay(
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(red: 0.20, green: 0.22, blue: 0.24))
                    .lineLimit(1)
                    .padding(.horizontal, 8),
                alignment: .leading
            )
            .overlay(alignment: .top) {
                if isTop {
                    pinTopView
                        .offset(y: -4)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.22), radius: 6, x: 0, y: 4)
    }

    private var pinTopView: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 1.00, green: 0.78, blue: 0.64), Color(red: 0.92, green: 0.45, blue: 0.32)],
                        center: .center,
                        startRadius: 2,
                        endRadius: 10
                    )
                )
                .frame(width: 16, height: 16)
                .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 2)

            Circle()
                .fill(Color.white.opacity(0.65))
                .frame(width: 5, height: 5)
                .offset(x: -2, y: -2)

            Circle()
                .fill(Color(red: 0.74, green: 0.30, blue: 0.22))
                .frame(width: 4, height: 4)
        }
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: 0.8)
        )
    }

    // MARK: - Bottom Nav

    private var bottomNavigator: some View {
        HStack(spacing: 12) {
            navButton(
                title: "收集",
                systemImage: "tray.full",
                tab: .collect
            )
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

    // MARK: - Sheets

    private var addTaskSheet: some View {
        NavigationStack {
            VStack(spacing: 18) {
                TextField("输入任务标题…", text: $newTaskTitle)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 10) {
                    Text("归类到标签")
                        .font(.subheadline.weight(.semibold))

                    LazyVGrid(columns: collectionColumns, spacing: 10) {
                        ForEach(collectionLabels.indices, id: \.self) { index in
                            Button {
                                newTaskLabelIndex = index
                            } label: {
                                Text(labelName(for: index))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(newTaskLabelIndex == index ? .white : .primary)
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(newTaskLabelIndex == index ? Color(red: 0.20, green: 0.60, blue: 0.55) : Color.primary.opacity(0.08))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

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
        .presentationDetents([.medium, .large])
    }

    private var editLabelsSheet: some View {
        NavigationStack {
            Form {
                Section("标签名称") {
                    ForEach(collectionLabels.indices, id: \.self) { index in
                        TextField("标签", text: Binding(
                            get: { collectionLabels[index] },
                            set: { collectionLabels[index] = $0 }
                        ))
                    }
                }
            }
            .navigationTitle("编辑标签")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { showEditLabels = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
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

    private func labelName(for index: Int) -> String {
        guard collectionLabels.indices.contains(index) else {
            return "未分类"
        }
        let name = collectionLabels[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "未分类" : name
    }

    private func completedTasks(for index: Int) -> [TaskItem] {
        tasks.filter { $0.isDone && $0.labelIndex == index }
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
        let safeIndex = collectionLabels.indices.contains(newTaskLabelIndex) ? newTaskLabelIndex : 0
        tasks.insert(TaskItem(title: title, labelIndex: safeIndex), at: 0)
        newTaskTitle = ""
        showAddTask = false
    }
}


#Preview {
    ContentView()
}
