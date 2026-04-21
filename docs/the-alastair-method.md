# The Alastair Method — Technical Specification & Product Reference

> A comprehensive reference for the engineering team building AlPHA (Alastair Planner & Habit App).

---

## 1. Origin & Philosophy

The Alastair Method was created by **Alastair Johnston**, a bullet journalist who designed a matrix-based task management system to solve a core productivity problem: how to see *everything* at a glance while still being able to focus on *one context at a time*.

It was originally a paper-based layout technique for bullet journals. The method bridges a "whole picture" overview with focused, context-driven work sessions.

**Core principle:** List tasks once, manage them with markers — never rewrite.

---

## 2. Core Data Model

The Alastair Method is fundamentally a **two-dimensional matrix (grid)**:

```
              | Context/Time Columns ...              |
              | Col A | Col B | Col C | Col D | Col E |
--------------+-------+-------+-------+-------+-------+
Task 1        |   •   |       |   •   |       |       |
Task 2        |       |   •   |       |       |   •   |
Task 3        |   •   |   •   |       |   •   |       |
...           |       |       |       |       |       |
```

### 2.1 Axes

| Axis       | Represents                  | Examples                                              |
|------------|-----------------------------|-------------------------------------------------------|
| **Rows**   | Individual tasks/items       | "Send proposal to client", "Fix auth bug"            |
| **Columns**| Contexts *or* time periods   | Contexts: Email, Phone, Projects, Deep Work, Waiting  |
|            |                              | Time: Mon/Tue/Wed... or Jan/Feb/Mar... or Hour blocks |

### 2.2 The Two Primary Modes

| Mode             | Column Meaning     | Use Case                                     |
|------------------|--------------------|----------------------------------------------|
| **Context Mode** | GTD-style contexts | Categorizing tasks by *how/where* they're done |
| **Time Mode**    | Time periods       | Scheduling tasks across days, weeks, or months |

---

## 3. Column Types by Timeframe

The method is flexible across any timeframe:

| Timeframe  | Number of Columns | Column Labels                        |
|------------|-------------------|--------------------------------------|
| **Daily**  | ~12               | Active hours (8am, 9am, 10am...)     |
| **Weekly** | 7                 | M, T, W, Th, F, Sa, Su              |
| **Monthly**| 28–31             | Day numbers (1, 2, 3... 31)          |
| **Yearly** | 12                | Jan, Feb, Mar... Dec                 |

### 3.1 Context Columns (GTD-style)

When used for context-based work (the original intent), typical columns include:

| Column         | Description                                      |
|----------------|--------------------------------------------------|
| Calendar       | Tasks tied to calendar events (e.g., Outlook)    |
| Email          | Tasks requiring email action                     |
| Phone          | Tasks requiring a phone call                     |
| Projects       | Tasks belonging to a specific project            |
| Thinking       | Deep work requiring uninterrupted focus           |
| Someday/Maybe  | Non-urgent ideas to revisit later                |
| Waiting For    | Delegated or blocked items awaiting a response   |
| @Home          | Tasks that can only be done at home              |
| @Office        | Tasks that can only be done at the office         |

Columns are **fully customizable** per user.

---

## 4. Task Markers & Signifiers

Tasks in each cell of the matrix are tracked using **markers** — small symbols placed at the intersection of a task row and a column.

### 4.1 Core Marker Set

| Symbol | Meaning                | Description                                  |
|--------|------------------------|----------------------------------------------|
| `•`    | **To Do / Scheduled**  | Dot placed in the relevant column(s)         |
| `×`    | **In Progress / Done** | X drawn over the dot when task is worked on  |
| `—`    | **Strikethrough row**  | Full line crossed out = task fully complete   |
| `>`    | **Migrated**           | Task moved forward to the next period        |
| `<`    | **Scheduled**          | Task moved to a specific future date         |
| `○`    | **Started**            | Circle outline = work begun but not finished |
| `★`    | **Deadline / Priority**| Star marks a hard deadline or high priority  |
| `~`    | **Recurring**          | Zigzag/tilde through multiple day columns    |

### 4.2 Task State Machine

```
                    ┌──────────┐
                    │  Created │
                    │    (•)   │
                    └────┬─────┘
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
        ┌──────────┐ ┌────────┐ ┌──────────┐
        │In Progress│ │Migrated│ │Cancelled │
        │    (○/×)  │ │  (>)   │ │  (——)    │
        └────┬─────┘ └────┬───┘ └──────────┘
             │             │
             ▼             ▼
        ┌──────────┐  (re-enters as
        │ Complete │   new • in next
        │   (—)    │   period)
        └──────────┘
```

### 4.3 Context Shifting

A critical feature: tasks can **shift contexts dynamically**. For example:
- A task starts in the **Phone** column (`•` under Phone)
- You call but leave a voicemail
- Cross off the dot under Phone (`×`), add a new dot under **Waiting For** (`•`)

This models real-world workflow where the *nature* of a task changes as you work on it.

---

## 5. Workflow & Daily Cycle

### 5.1 Setup (Start of Period)

1. **Name the page** — e.g., "Week of March 9" or "March 2026"
2. **Create columns** — Draw vertical columns for your chosen timeframe or contexts
3. **List tasks** — Write each task as a row, one per line
4. **Mark contexts/days** — Place a `•` in every column where the task is relevant

### 5.2 Execution (During the Period)

1. **Pick a context column** — e.g., "Email"
2. **Scan down** — Find all tasks with a `•` in that column
3. **Work sequentially** — Process each task, marking with `×` or `○` as you go
4. **Add new tasks** — Append to the bottom of the list as they come in
5. **Shift contexts** — If a task's nature changes, update column markers

### 5.3 Review (End of Period)

1. **Assess progress** — Review all rows for completion status
2. **Migrate incomplete tasks** — Mark with `>` and carry forward to the next period's fresh grid
3. **Reflect** — Identify patterns (recurring incomplete tasks may need re-evaluation)

---

## 6. Variations

### 6.1 Future Log (Yearly Planning)

- 12 columns (one per month) on the left side of the page
- Tasks listed with their exact dates on the right
- A `•` placed in the corresponding month column
- When a month arrives, scan its column and transfer tasks to the monthly spread

### 6.2 Weekly Task List

- 7 columns for days of the week
- Running to-do list beside the columns
- Dot each task on the day(s) it should be worked on
- Most popular variation for daily use

### 6.3 Project Tracker

- Columns represent project phases, milestones, or team members
- Tasks are project deliverables or sub-tasks
- Provides a single-page project overview

---

## 7. Application Data Model (Suggested)

Based on the method's mechanics, here is a suggested data model for the app:

### 7.1 Core Entities

```
Board
├── id: UUID
├── name: string              // "Week of March 9" or "Q1 Projects"
├── type: enum                // DAILY | WEEKLY | MONTHLY | YEARLY | CUSTOM
├── owner_id: UUID → User
├── created_at: timestamp
├── archived: boolean
└── columns: Column[]

Column
├── id: UUID
├── board_id: UUID → Board
├── label: string             // "Mon", "Email", "Waiting For", etc.
├── position: int             // ordering
├── color: string (optional)  // for visual differentiation
└── type: enum                // TIME_PERIOD | CONTEXT | CUSTOM

Task
├── id: UUID
├── board_id: UUID → Board
├── title: string
├── description: string (optional)
├── position: int             // row ordering
├── state: enum               // OPEN | IN_PROGRESS | COMPLETE | MIGRATED | CANCELLED
├── priority: enum            // NONE | LOW | MEDIUM | HIGH | DEADLINE
├── deadline: date (optional)
├── recurring: boolean
├── recurrence_rule: string (optional)  // e.g., RRULE
├── created_at: timestamp
├── completed_at: timestamp (optional)
└── markers: Marker[]

Marker
├── id: UUID
├── task_id: UUID → Task
├── column_id: UUID → Column
├── symbol: enum              // DOT | X | CIRCLE | STAR | TILDE | MIGRATED
├── created_at: timestamp
└── updated_at: timestamp
```

### 7.2 Key Relationships

- A **Board** has many **Columns** and many **Tasks**
- A **Task** has many **Markers** (one per relevant column)
- A **Marker** links a Task to a Column with a specific symbol/state
- Tasks can be **migrated** from one Board to another (creating a link between boards)

### 7.3 Key Operations

| Operation          | Description                                               |
|--------------------|-----------------------------------------------------------|
| `createBoard()`    | Initialize a new board with columns for a timeframe       |
| `addTask()`        | Append a task row to the board                            |
| `setMarker()`      | Place/update a marker at a task×column intersection       |
| `removeMarker()`   | Remove a marker from a cell                               |
| `completeTask()`   | Strikethrough — set state to COMPLETE                     |
| `migrateTask()`    | Move an incomplete task to a new board, mark as MIGRATED  |
| `shiftContext()`   | Remove marker from one column, add to another             |
| `reorderTask()`    | Change a task's row position                              |
| `archiveBoard()`   | Archive a completed period's board                        |

---

## 8. UX Considerations for Digital Implementation

### 8.1 Must-Have Features

| Feature                  | Rationale                                                    |
|--------------------------|--------------------------------------------------------------|
| **Grid/matrix view**     | The defining visual — tasks as rows, columns as contexts/time |
| **Tap-to-mark cells**    | Quick marker toggling (tap cycles: empty → • → × → ○)       |
| **Swipe to complete**    | Strikethrough gesture on a task row                          |
| **Drag to reorder**      | Reposition tasks by priority                                 |
| **Migration flow**       | End-of-period prompt to migrate incomplete tasks forward      |
| **Custom columns**       | Users must be able to define their own columns               |
| **Board templates**      | Pre-built templates: Weekly, Monthly, GTD Contexts, etc.     |

### 8.2 Mobile-Specific

- The grid can be wide — support **horizontal scrolling** for columns
- Consider a **collapsed view** that shows only columns with active markers
- **Pinch-to-zoom** on the matrix for dense boards
- Quick-add task via **floating action button**

### 8.3 Interaction: Marker Cycling

A single tap on a cell should cycle through marker states:

```
(empty) → • (to do) → ○ (started) → × (done) → (empty)
```

Long-press could open a full marker picker for special symbols (`★`, `~`, `>`).

### 8.4 Migration UX

At the end of a time period:
1. System prompts: "You have N incomplete tasks. Migrate to next period?"
2. User selects which tasks to migrate
3. Selected tasks appear in the new board with `>` marker on the old board
4. Cancelled tasks get strikethrough

---

## 9. Success Criteria from the Original Method

Per Alastair Johnston's guidance:

1. **Commit to at least 3 weeks** of consistent use to build the habit
2. The method should feel **faster than a traditional to-do list** — never rewrite tasks
3. Users should be able to **see everything in one glance**
4. Context-based execution should let users **batch similar work** efficiently
5. The system must be **simple enough to not require instructions** after initial onboarding

---

## 10. Sources

- [To Do: The Alastair Method — Bullet Journal](https://bulletjournal.com/blogs/bulletjournalist/to-do-the-alastair-method)
- [To Do: The Alastair Method — Alastair Johnston (creator)](https://alastairjohnston.com/to-do-the-alastair-method/)
- [Future Log: The Alastair Method — Alastair Johnston](https://alastairjohnston.com/cracking-the-bullet-journal-forward-planning-problem/)
- [Projects: The Alastair Method — Bullet Journal](https://bulletjournal.com/blogs/bulletjournalist/projects-the-alastair-method)
- [The Alastair Method Explained — Delightful Planner](https://delightfulplanner.com/the-alastair-method-explained/)
- [The Alastair Method Template — 101 Planners](https://www.101planners.com/the-alastair-method/)
- [Weekly Tasks with the Alastair Method — Rach Smith](https://rachsmith.com/weekly-tasks/)
- [How to Use the Alastair Method — Productive Pixie](https://www.theproductivepixie.com/2021/08/alastair-bullet-journal-method.html)

### Addendum

- [Video transcript — Boho Berry walkthrough](./the-alastair-method-transcript.md) — raw auto-generated transcript kept as research context
