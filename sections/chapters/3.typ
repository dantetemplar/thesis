= Design

This chapter presents the design of an interactive assistant for timetable editing and optimization in educational institutions. The design decisions are grounded in two practical observations from the Innopolis University scheduling workflow: (1) timetables are continuously edited after publication, and (2) schedulers need both algorithmic support and high-control manual editing. Therefore, the proposed system is designed as a human-in-the-loop platform that integrates optimization, validation, and interactive editing within one workflow.

== Engineering Objectives and Design Principles

The system design follows four engineering principles derived from the problem analysis in Chapters 1 and 2. Each principle is linked to a concrete implementation mechanism.

*First, feasibility-first optimization.* Hard constraints (no overlaps, admissible room capacities, required number of meetings) are always prioritized over preference optimization. In implementation, this is enforced via hard constraints and phase ordering in the optimizer @Ceschia_2023 @Schaerf1999.

*Second, perturbation-aware editing.* The workflow treats timetable maintenance as a recurring adaptation task rather than one-off timetable generation @veenstra2016. In implementation, this is realized in Stage B as user-driven editing with optional solver assistance for local adjustments.

*Third, explicit validation transparency.* The system includes clear, user-visible checks for conflicts, constraints, and workload balance, so schedulers can verify correctness before publication. In implementation, this is realized via a dedicated checks workspace and diagnostics outputs @oude-vrielink2019.

*Fourth, workflow-native integration.* The architecture is compatible with existing institutional tools (Google Sheets, web-based internal systems, calendar-based room usage practices), minimizing process friction. In implementation, this is realized through parser-based migration and Outlook-linked booking checks/synchronization.

== Problem Formalization

Before introducing the formal model, we summarize the scheduling logic used at Innopolis University, because this logic directly defines model entities and constraints.

#heading(level: 3, numbering: none, outlined: false)[Institutional Scheduling Context]

At Innopolis University, the academic year is split into Fall, Spring, and Summer trimesters. Fall and Spring are additionally split into two teaching blocks, while Summer is a single block. Scheduling is performed on discrete teaching days and 90-minute slots.

Innopolis University is relatively small (around 2,000 students). This matters for external validity: many universities are an order of magnitude larger and operationally more complex, with multi-campus layouts, multiple departments/faculties, and broader governance layers. The workflow described here is designed for this institutional scale, while remaining extensible for larger deployments.

The university has both bachelor and master programs, including English-taught and Russian-taught tracks. Bachelor tracks include Software Development, Cybersecurity, Data Science, AI, Robotics, and Game Development; master programs (for example, SE, AIDE, and Robotics) follow separate curricula. For bachelor students, years 1-3 are course-based and year 4 is thesis-only (no regular taught timetable). For master students, year 2 is also thesis-focused and does not require regular timetable generation.

Students are organized into academic groups (for example, `B22-CBS-02`), where cohort, track, and group index are encoded in the group ID. However, groups are not fully disjoint:

- first-year English classes use separate level groups;
- some students attend classes from another year (retakes);
- bachelor years 1-2 share most courses across tracks, while year 3 and later are increasingly track-specific.

Core courses usually follow a lecture-tutorial-lab pattern:

- lecture is typically one weekly meeting delivered to the full audience;
- tutorial is typically one weekly meeting for the same full audience, often scheduled adjacent to lecture;
- lab is typically one weekly meeting per academic group and commonly taught by teaching assistants;
- in real data, exceptions are frequent (missing components, co-teaching sets, multiple lecture/tutorial meetings per week, split audiences, mixed-track and mixed-program audiences).

#figure(
  image("../../figures/core-courses-timetable-spreadsheet.png", width: 100%),
  caption: [View of the core-courses spreadsheet.]
)

#figure(
  image("../../figures/core-courses-timetable-spreadsheet-large-view.png", width: 100%),
  caption: [Large-view of the core-courses spreadsheet.]
)

English in year 1 follows a separate model. Students are assigned by language level, not by academic group, into stable English groups:

- `AWA` groups (`AWA 1` ... `AWA 5`);
- `EAP` groups (`EAP 1` ... `EAP 11`);
- `FL` groups (`FL1` ... `FL6`).

Each English group has two `class` meetings per week with a stable instructor. Group size is typically around 15 students.

Electives follow separate institutional rules:

- assignment is based on top-5 student choices, with one final assignment per elective bucket;
- elective buckets occur in specific periods (Tech+Hum in Summer year 1, Tech+Hum in Summer year 2, Tech in Fall year 3);
- after assignment, elective structure is fully determined by the lecturer (format, grouping, meeting pattern);
- for planning and bureaucracy, the strict requirement is to satisfy the required number of academic hours.

Sports sections are treated as a separate process: students must accumulate 30 academic hours, but sports section scheduling is managed externally and is out of scope for this assistant.

The university uses one main campus building with rooms of different capacities (lecture halls, seminar rooms, labs). Online delivery is also possible and does not consume physical room resources. Teaching staff includes professors and teaching assistants; instructor availability and instructor preferences are operationally important, especially because some teaching assistants are also students. Instructor workload is also usually expected to be clustered into fewer weekdays with a practical daily limit of around 4-5 meetings where possible.

Large external events regularly create temporary room blackouts. A concrete case is the IT conference Merge 2026: on 17-18 April, large lecture halls 105, 106, 107, and 108 were occupied by conference tracks for the full working day, which overlapped regular teaching windows.

When an instructor is also enrolled as a student, the timetable must prevent role-conflicts: the same person cannot be assigned to teach and attend another class at overlapping times.

Time overlap checks are interval-based, not only slot-label-based. This is important because different programs may use different slot grids (for example, bachelors 12:10-13:40 and masters 12:40-14:10), so partial overlaps must be detected even when slot names differ. A unified slot grid can be used by default, but interval checks remain mandatory.

Governance constraints also affect scheduling operations. Some programs are coordinated through curators, and schedule changes are routed through them rather than direct instructor-level negotiation. For selected tracks (for example, some Russian-language bachelor streams), room changes can be restricted because of fixed recording setup requirements.

Room assignment is constrained not only by capacity but also by room features (for example, amphitheater layout, board/screen type, specialized equipment). These constraints are operationally critical even when room inventories are incomplete or periodically outdated.

Some rooms require delegated booking rights (for example, cyberpolygon spaces), so booking operations may involve handoff to another responsible person.

Data readiness is another operational factor: curriculum plans, teaching loads, and elective lists can arrive late or change without timely notification, creating synchronization risk between planning artifacts and the actual schedule state.

Block-level operations also require explicit support: each semester is split into two teaching blocks, and block transitions often cause confusion for students and instructors if schedule changes are not clearly surfaced. Some instructors also teach in "waves" (present only in specific weeks), which creates additional date-window constraints in Stage B.

In operational planning, besides feasibility, the schedule is expected to avoid overloaded days and uncomfortable placement. Typical targets are:

- no more than 3 distinct subjects per group per day where possible;
- no more than 5 meetings per group per day where possible;
- workload clustered into fewer weekdays for both groups and instructors where possible;
- minimized Saturday and late-evening classes (later than 18:00);
- avoid assigning small audiences to excessively large rooms where possible (prefer the smallest suitable room; for example, assigning a 2-student group to a 60-seat room is considered operationally unreasonable);
- for back-to-back classes, prefer the same room to avoid unnecessary transitions; instructor-side continuity has higher priority than group-side continuity;
- for lecture -> tutorial sequences, prefer immediate adjacency and placement in the same room;
- lecture/tutorial placement preferably in morning or afternoon slots;
- for loaded undergraduate years (especially years 1-2), lecture-tutorial-lab chains are preferably placed on the same day.

This institutional structure explains why the model must support mixed audiences, per-group sessions, stable subgroup teaching (English), lecturer-defined elective structures, co-teaching, selector-based group expansion, and checks for cross-group student conflicts.

#heading(level: 3, numbering: none, outlined: false)[Room Booking Operations]

Microsoft Outlook is used as the institutional room-booking provider. In this workflow, Outlook is used to detect room-booking conflicts and synchronize approved timetable bookings. The assistant also supports one-click booking updates for timetable events, including instructor identity in booking metadata, so operational notifications stay aligned.

The practical process is strongly communication-dependent: some instructors primarily rely on Outlook notifications, others on messenger communication. Therefore, booking metadata must explicitly include instructor identity, and booking synchronization must remain up to date after each timetable change.

#figure(
  image("../../figures/outlook-calendar-view.png", width: 100%),
  caption: [Outlook timetable calendar view.]
)

#figure(
  image("../../figures/outlook-room-calendars.png", width: 100%),
  caption: [Outlook room calendars used for finding free rooms for timetable.]
)

#figure(
  image("../../figures/outlook-event-details.png", width: 100%),
  caption: [Outlook event details.]
)

#figure(
  image("../../figures/outlook-event-details-choose-room.png", width: 100%),
  caption: [Outlook event details, selecting the target room.]
)

#figure(
  image("../../figures/outlook-event-details-choose-calendar.png", width: 100%),
  caption: [Outlook event details, selecting the target calendar.]
)


#heading(level: 3, numbering: none, outlined: false)[Formal Model]

The scheduling problem is modeled on a finite planning horizon (semester or block) with discrete teaching dates and discrete intra-day slots. Let:

- $G$ be the set of student groups (academic, English, elective, and cross-cutting groups).
- $C$ be the set of courses.
- $K_c$ be the set of components for course $c$ (e.g., lecture, tutorial, lab, class).
- $R$ be the set of rooms with capacity function `cap(r)`.
- $I$ be the set of instructors.
- $D$ be teaching dates in the term.
- $T$ be available intra-day slots.

Each concrete meeting instance $m$ is generated from a course component and contains:

- target audience (one group or union of groups),
- expected attendance,
- candidate instructor options (including co-teaching sets),
- one weekly recurrence index inside the term.

Examples of meeting generation used in the implementation:

- `Calculus / lec`: one shared meeting for all selected groups;
- `Calculus / lab`: one meeting per group when `per_group = true`;
- `English / class`: meetings by English-level groups, not by academic groups;
- selector-based audiences such as `@BS_Y1_EN` (whole program) or `@MS_Y1/AIDE` (single track).

#heading(level: 3, numbering: none, outlined: false)[Stage A: Reference Weekly Structure]

The decision model uses binary assignment variables. For each meeting $m$, day-slot pair $(d,t)$, room $r$, and instructor option $i$:

- $x_(m,d,t,r,i) \in {0,1}$ equals 1 iff meeting $m$ is assigned to $(d,t,r,i)$.

Core assignment condition:

- each meeting is assigned exactly once over admissible alternatives.

Hard constraints in Stage A:

- no time overlap for the same room;
- no time overlap for the same instructor;
- no time overlap for the same student group;
- no time overlap for students appearing in multiple groups;
- no overlap between teaching assignments and student attendance for people with dual role (instructor + student);
- meeting counts satisfy the curriculum-implied weekly requirements;
- room assignment meets required attendance threshold.

Representative constraints:

- no-overlap for each room/instructor/group is enforced as interval incompatibility over selected assignments;
- room capacity feasibility is enforced on each selected $(m,r)$ assignment.

Soft constraints (optimize when feasible):

- preserve pedagogical ordering (lecture before tutorial, tutorial before lab, etc.);
- maximize back-to-back lecture-tutorial continuity for shared audience;
- prefer same-day coupling for related components when applicable;
- penalize Saturday and late-evening classes;
- penalize room oversizing and unnecessary room changes;
- balance distribution of meetings across weekdays.
- prefer assignments that match instructor time preferences, with role-based priority weights (for example, professor preferences can be weighted higher than teaching assistant preferences).

#heading(level: 3, numbering: none, outlined: false)[Stage B: Calendar-Level Adaptation (User-Driven)]

Stage B starts from an accepted baseline weekly structure and instantiates it on concrete calendar dates.

Perturbation is treated relative to an accepted baseline calendar. In practical terms, adaptation quality reflects how much the updated schedule deviates from the accepted one in date, slot, room, and instructor assignments.

At this stage, the exact perturbation metric is intentionally left as an open engineering question. The intended direction is to avoid unnecessary structural changes while preserving feasibility and operational predictability for students, instructors, and planners.

In Stage B, planners manually decide concrete moves (which class to move and where), while the system provides diagnostics and can run solver-assisted suggestions for local repair when requested. Date-specific operational constraints, including instructor unavailability and room blackouts from external bookings/events, are enforced during this process.

The overall objective is lexicographic across stages:

- first, satisfy feasibility (hard constraints);
- then, maximize pedagogical coherence and comfort in Stage A;
- then, support low-perturbation user-guided adaptation in Stage B.

== Domain Data Model

The domain model is implemented as typed configuration entities with explicit validation rules. The central configuration includes:

- *Term configuration*: semester date range, active weekdays, slot start times.
- *Room configuration*: room identifiers and capacities.
- *Instructor configuration*: instructor identity and role metadata.
- *Instructor preferences*: preferred time windows used in solving and verification, including preference-priority by role.
- *Program hierarchy*: degree/year/language structures and track-level groups.
- *Student groups*: group code, kind, estimated size, optional explicit student membership.
- *Course configuration*: course tags and component-level teaching requirements.

The course component model supports patterns that are typical for real university timetabling and often difficult to express in legacy tools:

- per-group or shared-audience components,
- selectors over program/track structure (e.g., all groups in a track),
- co-teaching alternatives,
- explicit per-week frequencies,
- relations to other components for ordering and coupling preferences.

This representation allows one model to cover common course structures (lecture+tutorial+lab), English stream classes, and mixed audience cases.

== System Architecture

The system uses a three-part architecture: frontend, backend orchestration, and optimizer workers.

#figure(
  align(center)[
    #image("../../figures/system-architecture-sequence.svg", width: 100%)
  ],
  caption: [Swimlane diagram of architecture.]
)



#heading(level: 3, numbering: none, outlined: false)[Frontend]

The frontend is a web application that provides:

- configuration workspace (courses, groups/programs, instructors, rooms, term settings),
- timetable workspace with weekly navigation and multiple views,
- conflict-aware visual details for selected entities (group, program, meeting, room, instructor),
- validation and consistency feedback while editing configuration.

Interface responsibility: the frontend sends configuration updates and solve/cancel commands over REST APIs, and consumes task/status/log updates provided by backend streams.

The UI is intentionally built around direct manipulation and reversible actions to align with scheduler expectations @Shneiderman1983 @Norman2013.



#heading(level: 3, numbering: none, outlined: false)[Backend]

The backend is designed as a task and state orchestration service:

- stores and updates configuration versions;
- receives solve/edit requests from UI;
- dispatches optimization tasks to worker nodes;
- streams progress and logs back to UI;
- persists generated schedule artifacts and derived checks.

Interface responsibility: the backend exposes REST endpoints for frontend operations and worker task lifecycle management, including asynchronous task initialization and cancellation polling.

This layer isolates the user workflow from solver runtime details and enables horizontal scaling of optimization workers.



#heading(level: 3, numbering: none, outlined: false)[Optimizer workers]

Optimizer workers run independently and connect to backend endpoints to:

- receive solve/cancel tasks,
- execute CP-SAT model solving,
- report phase logs and statuses,
- return schedule artifacts in machine-readable format.

Interface responsibility: workers poll backend task endpoints for work/cancel signals and stream phase logs/status through a persistent channel (WebSocket) to backend, following a GitHub-worker style pull model.

This worker model supports distributed execution and robust operational deployment, including multi-node setups.

== Booking-Centric Design

Room booking is treated as a dedicated capability in the system design, rather than a side effect of timetable generation.

- Outlook provider data is used for room-conflict checks and blackout detection;
- approved timetable changes are synchronized to booking system with one action;
- booking payload includes instructor identity to satisfy communication requirements;
- delegated booking flow is supported for rooms with restricted permissions;
- booking consistency is validated after each adaptation cycle to keep timetable and room reservations aligned.

== Two-Stage Timetabling Method

The operational method is organized into two connected planning stages.

*Stage A: Reference weekly structure.* A coherent weekly template is generated from the curriculum and resource constraints. This stage emphasizes pedagogical ordering, room suitability, and load distribution.

*Stage B: Calendar-level realization.* The weekly structure is instantiated across actual dates in the active period. Date-specific disturbances (availability changes, exceptions, resource blocks) are handled through manual planner decisions, with solver assistance available on demand for local adjustments while preserving overall structure.

This decomposition reflects actual university operations: planners reason in weekly patterns but execute on concrete calendar dates.

== Multi-Objective Optimization Design

The optimization process uses a hierarchical (lexicographic) objective strategy with sequential phases.

- *Tier 1 (pedagogical coherence):* minimize ordering violations and missed lecture-to-tutorial continuity.
- *Tier 2 (quality and comfort):* minimize calendar discomfort and resource inefficiencies (late classes, Saturday load, room oversizing, weekday imbalance).

Each solved phase is fixed as a bound for the next phase. This prevents lower-priority objectives from degrading higher-priority educational structure.

This design directly addresses a common practical issue: a single aggregated weighted objective may hide unacceptable violations behind a numerically improved but educationally weak schedule.

== Validation and Quality Control Framework

To make the design operationally auditable, the assistant provides a verification layer that can be launched before and after solving:

- overlap checks (rooms, groups, instructors, and students) with interval-level intersection detection,
- curriculum and constraint checks (required meetings, ordering relations, room capacity feasibility),
- instructor checks (availability violations, dual-role conflict checks, and preference satisfaction reports with priority-aware summaries),
- schedule consistency checks (same-day and back-to-back coherence for related classes),
- workload and distribution checks (group load by weekday, instructor load, weekday concentration, late slots, Saturday load),
- room usage checks (capacity overflow, oversize assignments, room utilization and room changes),
- external booking checks via Outlook provider data (room-booking conflicts and conference-driven room blackouts).

This framework supports both automatic checks and human review, enabling transparent acceptance decisions for produced timetables. In practice, trust is established not by tuning objective weights, but by passing these checks and giving planners clear diagnostics for each issue.

== User-Centered Interaction Design

The assistant is designed as a decision-support system rather than full automation:

- users can inspect data assumptions and schedule structure;
- users can switch views by group, room, and instructor;
- users can investigate local conflicts before global re-solve;
- users can iteratively adjust input and regenerate schedules.

This interaction model follows the principle that schedulers retain responsibility and contextual knowledge, while optimization provides consistent computational support.

== Transition from Legacy Workflow Impact

The design intentionally absorbs lessons from earlier process stages:

- highly irregular Google Sheets source structure;
- custom parsing and conflict checking scripts;
- spreadsheet plugin checks for room/time/teacher conflicts;
- practical limitations of existing monolithic timetabling systems in usability and adaptation speed.

#figure(
  image("../../figures/core-courses-timetable-spreadsheet.png", width: 100%),
  caption: [Legacy spreadsheet-based timetable source with heterogeneous structure that motivated formal modeling.]
)

The resulting design consolidates fragmented steps into one coherent platform with a formal model, integrated checks, and optimization-driven editing. The engineering trace from legacy artifacts to design choices is explicit:

- legacy spreadsheets with heterogeneous semantics -> parser and normalization pipeline;
- spreadsheet ambiguity and hidden conventions -> explicit typed data model;
- manual conflict scanning -> verification module with explicit diagnostics;
- manual booking lookup and reconciliation -> booking integration and consistency checks;
- fragmented edits across tools -> integrated settings/timetable/checks workspaces.

== Chapter Summary

This chapter defined the engineering design of the proposed scheduling assistant. The problem was formalized as a constrained multi-objective optimization task with explicit hard/soft criteria and perturbation-aware adaptation. A Curriculum-Based Course Timetabling (CB-CTT) domain model, three-layer architecture with explicit interfaces, two-stage planning method, and transparent quality framework were established. These choices support practical timetable maintenance under continuous operational changes while preserving scheduler control.