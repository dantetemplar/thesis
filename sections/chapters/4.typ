= Implementation

This chapter describes the implemented system corresponding to the design presented in Chapter 3. The implementation integrates parser-based legacy data handling, formal schedule configuration, CP-SAT optimization, and a web-based interactive assistant for timetable editing, validation, and analysis.

== Implementation Stack and Repositories

The implementation is distributed across three codebases:

- *Schedule assistant optimizer* (`schedule-assistant`): Python-based formal model, solver execution, and verification checks.
- *Schedule platform backend/frontend* (`schedule-builder-backend`, `schedule-builder-frontend`): data extraction, compatibility checks, Outlook integration, and service orchestration.
- *Interactive web UI* (`website`): settings and timetable workspaces for operational users.

Core technologies:

- Backend:
  - Python + uv,
  - FastAPI,
  - Microsoft Outlook for room-booking integration via exchangelib.
- Optimizer:
  - Python + uv,
  - Google OR-Tools CP-SAT #footnote[https://developers.google.com/optimization],
  - httpx.
- Frontend:
  - React + Vite,
  - TanStack Query, Tanstack Router,
  - TailwindCSS,
  - DaisyUI,
  - Yjs,
  - Valtio

== Data Pipeline Implementation

#heading(level: 3, numbering: none, outlined: false)[From heterogeneous spreadsheets to formal configuration]

The initial timetable source was a highly irregular Google Spreadsheet with many merged semantics, variable sections, and mixed manual conventions.

#figure(
  image("../../figures/core-courses-timetable-spreadsheet.png", width: 100%),
  caption: [Example of the original spreadsheet layout used by timetable planners before formal model integration.]
)

#figure(
  image("../../figures/core-courses-timetable-spreadsheet-large-view.png", width: 100%),
  caption: [Large-view fragment of the weekly core-courses spreadsheet used in manual planning workflow.]
)

To operationalize optimization, the data pipeline was implemented in two steps:

1. parse spreadsheet structures into normalized machine-readable objects;
2. map normalized objects into a structured CB-CTT data model.

This conversion made scheduling constraints explicit and checkable, replacing implicit spreadsheet semantics.

#heading(level: 3, numbering: none, outlined: false)[Conflict-checking plugin during migration]

A spreadsheet plugin was implemented as an intermediate migration step before the final assistant UI. It checked teacher occupancy, room occupancy, and structural inconsistencies directly in the spreadsheet workflow and returned actionable feedback to planners.

#figure(
  image("../../figures/spreadsheet-plugin-input-token.png", width: 100%),
  caption: [Authentication and run flow of the spreadsheet conflict-checking plugin.]
)

#figure(
  image("../../figures/spreadsheet-plugin-conflicts-capacity-exceeded.png", width: 100%),
  caption: [Conflict output example: room capacity exceeded.]
)

#figure(
  image("../../figures/spreadshett-plugin-conflicts-teacher-is-busy.png", width: 100%),
  caption: [Conflict output example: instructor overlap.]
)

#figure(
  image("../../figures/spreadsheet-plugin-room-conflicts-go-to-cell.png", width: 100%),
  caption: [Conflict output with direct navigation back to source cells.]
)

This plugin stage reduced migration risk in three ways:

- it provided immediate conflict detection in the legacy environment;
- it validated parser outputs against real operational spreadsheet data;
- it revealed practical limits of further development inside Google Sheets (complex parsing, limited interaction model, constrained extensibility).

For these reasons, the final implementation moved to a dedicated integrated assistant instead of extending spreadsheet tooling.

== Optimizer Implementation

#heading(level: 3, numbering: none, outlined: false)[Curriculum-Based model and domain entities]

The optimizer accepts a structured model with strict validation rules. Implemented entities include:

- term with date interval, weekdays, and slot starts;
- rooms and capacities;
- instructors;
- programs/tracks and group selectors;
- student groups with estimated/enumerated membership;
- courses with component-level requirements.

For instructors, the configuration includes preference windows used as soft penalties in optimization. Preference penalties are priority-weighted by instructor role, so violations for critical instructors can be penalized more strongly than violations for lower-priority roles.

The model supports:

- shared and per-group meetings;
- direct group IDs and selector expansion (`@program`, `@program/track`);
- instructor pools and co-teaching options;
- explicit `per_week` teaching frequency;
- component relations (`relates_to`) for ordering and coupling preferences.

This flexibility covers real curriculum patterns: core triplets (lecture/tutorial/lab), English groups, elective buckets, and mixed audience classes.

Illustrative configuration fragment:

```yaml
courses:
  - id: calculus
    components:
      - kind: lecture
        groups: "@BS_Y1_EN"
        per_week: 1
      - kind: lab
        groups: "@BS_Y1_EN"
        per_group: true
        per_week: 1
        instructors: ["ta_pool_a", "ta_pool_b"]
        relates_to:
          - kind: lecture
            relation: after
```

#heading(level: 3, numbering: none, outlined: false)[Meeting expansion and decision model]

The solver transforms course components into concrete meeting instances over the planning horizon. For each meeting, the model creates variables for:

- day index,
- local slot index and absolute timeline index,
- room selection,
- instructor option.

Table-level mapping between design and implementation:

- `x_(m,d,t,r,i)` - assignment decision for meeting/date-slot/room/instructor alternative - binary;
- `int_room_(m,r)` - optional room interval activated by room choice - interval;
- `int_inst_(m,i)` - optional instructor interval activated by instructor choice - interval;
- `y_(m,d,t)` - selected temporal placement - binary.

Resource usage is represented via interval variables and optional intervals for room/instructor alternatives. Hard no-overlap constraints are applied to:

- each student group,
- each shared student (for cross-group memberships),
- each room,
- each instructor.

In the reference weekly solve, instructor and room availability are not enforced as hard constraints. These constraints are handled later at calendar-level adaptation, where date/week conflicts are diagnosed and resolved in user-driven workflow with optional solver assistance.
For dual-role persons (instructor and student), the model also enforces no-overlap between their teaching assignments and their own student timetable.

Overlap detection is interval-based and therefore also captures partial overlaps between heterogeneous slot grids (for example, 12:10-13:40 intersecting 12:40-14:10), not only identical slot labels. This direct interval modeling ensures strict feasibility before optimization quality is considered.

#heading(level: 3, numbering: none, outlined: false)[Room-capacity handling]

Room feasibility is implemented with practical fallback logic:

- default: room must fit expected attendance;
- if full fit is unavailable or attendance is large, a thresholded fallback is allowed;
- strong penalties discourage oversized rooms.

This mechanism avoids frequent infeasibility in real institutional datasets while still prioritizing appropriate room assignment.

#heading(level: 3, numbering: none, outlined: false)[Multi-phase objective solving]

The CP-SAT solve is implemented as a multi-phase process:

- phase 1: pedagogical structure quality (ordering, adjacency/coherence),
- phase 2: timetable comfort and resource quality.

In phase 2, instructor preferences are optimized as soft terms together with timetable comfort terms (late slots, Saturday load, and distribution quality). Instructor-preference penalties are scaled by priority weights. Date-specific availability is handled in the post-generation adaptation flow, not in the weekly reference solve. After each phase, the achieved objective value is fixed as a bound for subsequent phases. The solver also stores hints from the previous phase, improving continuity and practical runtime behavior.

Solver logs are persisted per phase and included in run artifacts, enabling post-hoc audit.

#heading(level: 3, numbering: none, outlined: false)[Output artifacts]

Each solve run writes a timestamped result directory containing:

- `output.yaml` with schedule payload,
- phase log files,
- status and structured statistics.

This design makes experiments reproducible and supports external analysis scripts.

== Verification Checks and Validation Implementation

The implemented validation module computes verification outputs from both configuration and solution data. It reports:

- hard conflict list and count;
- unmet required meeting counts;
- lecture-tutorial adjacency and same-day coherence checks;
- order violations (lab before tutorial, tutorial before lecture, etc.);
- room overflow and room oversize checks;
- workload checks (groups, instructors, weekdays, late slots, Saturdays);
- instructor preference checks (scheduled in preferred vs non-preferred slots);
- dual-role conflict checks (teaching vs own student attendance overlaps);
- room usage checks (time utilization, capacity utilization, room swaps);
- room-feature compatibility checks (capacity plus required equipment/layout constraints);
- support for external booking consistency checks from Outlook provider data (including room-booking conflicts and large-event room occupancy windows), with conflict-resolution actions on concrete dates/weeks.

This validation layer is used both as a debugging instrument and as an acceptance dashboard for schedulers.

In operational workflow, Outlook is treated as booking/conflict provider and synchronization endpoint, not as an internal optimization source model. The assistant supports one-click booking synchronization for approved timetable events (with instructor identity in booking payload), which reduces manual communication failures.

Operational governance is supported in the workflow layer: changes can be routed through curator-owned streams, and booking actions can include delegated-flow steps for rooms with restricted booking permissions.

== Booking Integration Implementation

Booking integration is implemented as a separate workflow component connected to the scheduling assistant. It consumes room-booking provider data for conflict checks and writes synchronized reservations for approved timetable events.

The implementation supports:

- provider-side room occupancy lookup for conflict verification;
- one-click booking synchronization from timetable updates;
- instructor identity in booking metadata for operational communication;
- delegated booking handoff for restricted rooms;
- post-sync consistency checks to ensure timetable and bookings remain aligned.

The room-booking service and APIs are already available in the university ecosystem and are used as integration target for this feature.

== Interactive Assistant Frontend Implementation

#heading(level: 3, numbering: none, outlined: false)[Main workspace structure]

The web UI implements three user-visible workspaces:

- timetable,
- settings,
- checks.

Settings and timetable workspaces are fully implemented and integrated with configuration/schedule state.

#heading(level: 3, numbering: none, outlined: false)[Settings workspace]

The settings module provides dedicated tabs for:

- courses,
- programs and student groups,
- instructors,
- rooms,
- semester/global settings.

It includes:

- consistency-aware selection state,
- keyboard-friendly clearing/navigation behavior,
- sidebar context panel,
- config and output loading flow.

Design justification in operational terms:

- hierarchical programs/groups editor reduces ambiguity in audience definition;
- dedicated component editor makes course constraints explicit and auditable;
- sidebar context panel reduces cross-screen lookup during edits;
- stable tab separation reduces accidental mixing of unrelated configuration concerns.

#figure(
  image("../../figures/schedule-assistant-settings-general.png", width: 100%),
  caption: [General settings interface used to define term slot grid, active weekdays, and scheduling horizon.]
)

#figure(
  image("../../figures/schedule-assistant-settings-groups.png", width: 100%),
  caption: [Programs/groups editor supporting hierarchical audience definition and selector-based modeling.]
)

#figure(
  image("../../figures/schedule-assistant-settings-courses.png", width: 100%),
  caption: [Courses/components editor used to encode per-week requirements, shared/per-group meetings, and component relations.]
)

#figure(
  image("../../figures/schedule-assistant-settings-rooms.png", width: 100%),
  caption: [Room settings editor used to maintain capacity and room-constraint metadata for feasibility checks.]
)

#heading(level: 3, numbering: none, outlined: false)[Timetable workspace]

The timetable workspace implements:

- weekly navigation over computed date ranges,
- core/English/group-centric and resource-centric (room/instructor) views,
- merged-card rendering for repeated meetings in one cell,
- visual connectors for pedagogically related back-to-back sessions,
- dynamic highlighting for selected meetings, groups, programs, rooms, and instructors,
- a computed detail panel with contextual statistics and drill-down links.

Design justification in operational terms:

- room/instructor-centric views support targeted conflict investigation;
- merged-card rendering improves readability in dense timetable cells;
- contextual detail panel reduces manual reconstruction of local constraints;
- highlight and connectors support fast inspection of related sessions.

#figure(
  image("../../figures/schedule-assistant-timetable.png", width: 100%),
  caption: [Timetable workspace used for conflict inspection, view switching, and contextual diagnostics in weekly maintenance workflow.]
)

The view model computes normalized meetings, columns, room/group utilization labels, and per-cell signatures to keep rendering stable and responsive for large schedules.

== Operational Workflow Implementation

The implemented end-to-end workflow is:

1. edit configuration in settings (artifact: validated config snapshot);
2. run solve via backend-worker orchestration (artifact: solve task and phase logs);
3. inspect generated schedule in timetable workspace (artifact: schedule draft);
4. run checks and review diagnostics (artifact: checks report);
5. apply user adjustments and rerun if needed (artifact: revised schedule draft);
6. synchronize approved events to booking provider (artifact: booking updates + sync status);
7. approve operational schedule version for use.

User intervention is possible after configuration edits, after first draft inspection, and after checks review.

In practice, this loop also handles late updates: when curriculum plans, instructor windows, or elective assignments change, users manually adjust affected parts of the calendar with checks support and optional solver-assisted suggestions.

This loop supports both initial schedule generation and iterative maintenance after disturbances.

== Implementation of Acceptance Criteria

The implemented system evaluates generated schedules using explicit criteria:

- *feasibility criteria*: zero hard conflicts and zero unmet required meetings;
- *pedagogical criteria*: number of ordering violations and continuity coverage statistics;
- *operational criteria*: room-capacity overflow count, room-usage and overload indicators (late slots, Saturdays, weekday concentration);
- *maintenance criteria*: controlled change scope relative to accepted baseline schedule, supported by diagnostics and optional solver suggestions;
- *runtime criteria*: solve time and diagnostics completeness for representative scenarios;
- *usability criteria*: direct manipulation and transparent diagnostics in UI.

The criteria are auditable from run artifacts and verification outputs, which makes schedule quality discussion with planners evidence-based rather than subjective.

== Practical Outcome

The practical outcome can be stated as a concrete before/after transformation.

- *Before implementation:* scheduling relied on Google Sheets, ad hoc scripts, and manual Outlook conflict checks.
- *After implementation:* one integrated assistant combines a structured CB-CTT model, optimization, validation checks, and booking-aware workflow.

Newly enabled capabilities:

- reproducible validation reports and structured run artifacts;
- integrated diagnostics for conflicts and quality issues;
- calendar-aware maintenance with user-controlled edits and solver-assisted local repair;
- one-click booking synchronization for approved updates.

Out of scope at current stage:

- sports scheduling;
- full SIS integration across all educational processes;
- fully automated end-user notification pipeline.

== Implementation Limitations

The implemented system has practical boundaries that should be considered in deployment:

- weekly reference solve abstracts some date-specific availability to adaptation stage;
- room-feature inventories can be incomplete or outdated, affecting strict feature feasibility;
- booking flows depend on external provider availability and permissions;
- current data model and workflows are tailored to Innopolis operational context;
- selected governance processes remain curator/operator-mediated rather than fully automated;
- full SIS-level integration and fully automatic stakeholder notifications are out of scope, yet the system is designed to be easily extensible for future integrations.

== Chapter Summary

This chapter presented the concrete engineering implementation of the proposed assistant across the data pipeline, optimization engine, verification subsystem, and interactive web UI. The implemented system supports Curriculum-Based Course Timetabling (CB-CTT) modeling, conflict-safe optimization, transparent validation checks, and practical human-in-the-loop editing. Together, these components realize the design objective of reliable timetable maintenance under real educational constraints.
