#set page(paper: "a4", margin: (left: 2cm, right: 2cm, top: 1cm, bottom: 1cm))
#set text(font: "Liberation Serif", size: 12pt, lang: "en")
#set par(leading: 0.7em, justify: false, spacing: 0.55em)

#let slide(title, body, sticky: false) = {
  block(
    breakable: not sticky,
    above: 0.45em,
    below: 0pt,
    spacing: 0.35em,
  )[
    #body
    #v(0.2em)
    #grid(
      columns: (1fr, auto),
      column-gutter: 0.45em,
      align: horizon,
      line(length: 100%, stroke: 0.35pt + rgb("#ccc")),
      text(size: 9pt, style: "italic", fill: rgb("#777"))[#title],
    )
  ]
}

#slide(
  "Interactive Assistant for Timetable Editing and Optimization in Educational Institutions",
  [
    Good morning. My name is Ruslan Belkov. Today I present my bachelor's thesis on an interactive assistant for timetable editing and optimization. The thesis was supervised by Alexey Potyomkin and consulted by Alexander Gasnikov.
  ],
)

#slide(
  "Educational Timetabling",
  [
    My work is related to Curriculum-Based Course Timetabling: assigning courses, rooms, instructors, and student groups to timeslots under hard and soft constraints. The problem is NP-hard — which is why the literature leans on heuristics and powerful solvers. The case study is Innopolis University — roughly one thousand students on a single campus.
  ],
)

#slide(
  "What the Literature Actually Uses",
  [
    The literature is dominated by metaheuristics and integer programming on benchmark instances. Success is measured by initial schedule quality. Yet adoption studies show most institutions still work in spreadsheets.
  ],
)

#slide(
  "A Paradoxz: Universal Problem, Weak Solutions",
  [
    Every university builds timetables every term, but convenient tools are scarce. Planners patch spreadsheets by hand and reconcile room bookings separately. The real gap is not solver quality — it is the lack of usable, workflow-integrated tools. CP-SAT solvers are common in shift scheduling yet rarely appear in university timetabling papers, even though hard institutional constraints would suit them.
  ],
)

#slide(
  "Open Problems Identified",
  [
    Post-publication maintenance is far less studied than initial generation. Planners need lifecycle support — not a one-shot solve. Over sixty percent of institutions revise at least ten percent of lessons after publication.
  ],
)

#slide(
  "UniTime: Promising, but Not Enough",
  [
    We first evaluated UniTime, the best-known academic platform for scheduling. Setup consumed enormous time, daily use was inconvenient, and it missed our local rules — mixed audiences, instructors who are also students, Outlook booking. That is why we built a dedicated assistant.
  ],
)

#slide(
  "The Problem at Innopolis University",
  [
    Currently at Innopolis, scheduling still runs on Google Sheets and manual Outlook checks. After publication, timetables change constantly — teacher illness, room blackouts, late curriculum changes. One fix triggers the next: move a lecture, and the Outlook booking still points at the old room. Some errors surface only after someone reports them. Innopolis context also increases complexity of scheduling: we have instructors enrolled as students, burst-like availability for visiting lecturers, conference room blackouts, and overall lack of rooms.
  ],
  sticky: true,
)

#slide(
  "Engineering Objectives",
  [
    We've formulated five objectives: a CP-SAT solver producing a feasible weekly schedule; planner-driven post-publication edits; a formal data model; transparent diagnostics to confirm correctness; and an integrated workflow with Outlook booking.
  ],
)

#slide(
  "Human-in-the-Loop Scheduling Assistant",
  [
    The assistant has two phases. Weekly baseline generation builds a reference structure with CP-SAT. Calendar maintenance instantiates it on real dates — the planner edits manually and runs checks to see what broke.
  ],
)

#slide(
  "Problem Formulation (CB-CTT)",
  [
    We use the Curriculum-Based Course Timetabling (CB-CTT) model as input. The solver assigns day, slot, instructor, and room for each meeting. Hard constraints cover overlaps, capacity, and banned slots. The solver minimizes twelve soft penalties.
  ],
  sticky: true,
)

#slide(
  "Soft Objective Function",
  [
    Twelve soft terms are normalized to a zero-to-one range using worst-case bounds. This normalization improved solver convergence a lot. We also keep everything integer, as the solver requires. Planners rely on verification reports rather than objective scores.
  ],
)

#slide(
  "Same-day lec + tut + lab",
  [
    Pedagogical terms favor same-day components, tutorial right after lecture, and appropriately sized rooms. The slide lists all five criteria.
  ],
)

#slide(
  "Meetings overload",
  [
    Comfort terms limit overload for students and instructors, spread meetings across weekdays, and respect time preferences. Details are on the slide.
  ],
)

#slide(
  "Room Choice Refinement",
  [
    We also have an extra phase that optimizes rooms with everything else frozen — same room for lecture–tutorial pairs, smaller suitable rooms, fewer hops between labs.

    It is unsafe to do in the first phase because the solver can avoid these penalties by spreading meetings to different days, abusing the objective.

    That is how the optimization process works; now we move to the web interface.
  ],
)

#slide(
  "Settings",
  [
    We have three main workspaces: settings, timetable, and checks.

    Settings workspace holds explicit configuration for everything — courses, students, instructors, rooms — the same structured model used in the solver.
  ],
)

#slide(
  "Timetable",
  [
    Timetable workspace is for day-to-day maintenance: weekly views of the schedule, with edits on real calendar dates.
  ],
)

#slide(
  "Verification",
  [
    Checks workspace flags double-bookings, capacity issues, missing slots, and other rule violations — each issue is linked to the relevant item in the schedule or settings.
  ],
)

#slide(
  "Outlook Integration",
  [
    Outlook integration helps to keep bookings in sync with the schedule and highlights conflicts.
  ],
)

#slide(
  "System Architecture",
  [
    We use a three-part architecture:
    React frontend for the web interface,
    FastAPI backend to store configuration and connect to the optimizer,
    and a CP-SAT optimizer running as a separate process.
  ],
)

#slide(
  "Research Contribution",
  [
    The thesis brings together a scalable CP-SAT solver and a working product — weekly baselines, calendar edits, issue checks, and Outlook room sync. And it can be used at Innopolis University instead of Google Sheets and manual cross-checks.
  ],
)

#slide(
  "Early Exploration: Spreadsheet Parser & Plugin",
  [
    We started with early prototypes — a Sheets parser and a conflict plugin. They confirmed that automated checks are valuable and highlighted many issues with unstructured Google Sheets. That led us to build the full assistant.
  ],
)

#slide(
  "Limitations & Future Work",
  [
    Limitations: the approach was validated at one relatively small institution, the rules are tailored to Innopolis, and the system is still a prototype. Future work: AI-assisted edits from plain language, a plugin system to extend it for other universities, and open-source hardening.

    Thank you — I am happy to answer your questions.
  ],
  sticky: true,
)
