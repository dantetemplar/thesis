= Introduction

Timetabling in educational institutions is a long-standing and challenging problem. A valid timetable must satisfy a variety of hard and soft constraints, such as the availability of teachers, rooms, and student groups, while also considering preferences like minimizing idle time or aligning lectures and tutorials on the same day. The problem is NP-hard, which explains the abundance of heuristic, metaheuristic, and optimization-based approaches proposed over the last six decades @Gotlieb2003 @Schaerf1999 @Ceschia_2023.

Despite significant algorithmic progress, practical adoption of automated timetabling systems remains limited. Oude Vrielink et al. @oude-vrielink2019 found that most higher education institutions still rely on spreadsheets and manual coordination, citing poor usability, lack of workflow integration, and difficulty in making incremental adjustments as key barriers. This gap between academic prototypes and operational practice is a central motivation for this thesis.

In practice, most institutions employ a hybrid process: an initial draft is prepared using software or spreadsheets, and human schedulers then refine it manually to meet real-world requirements. However, timetables are rarely static. Once published, they must be updated regularly because of unforeseen events such as teacher illness, changes in preferences, or sudden room reservations for events. Studies report that over 60% of institutions modify at least 10% of lessons after the official schedule is released @coursedog2023. This makes post-publication timetable maintenance a central operational task that requires minimal disruption to students and teachers @veenstra2016 @Babaei2015.

== Motivating Example

Imagine a week before classes start, a lecturer falls ill and two major events suddenly block the largest lecture halls. The scheduler must manually reshuffle dozens of sessions in Google Sheets, re-check Outlook bookings, and notify teachers and students. Even small changes can cascade into conflicts: a class moved to another slot collides with a teaching assistant's own studies, or a group ends up with three long gaps in one day. Such cases occur multiple times every semester at Innopolis University, taking hours of manual work.

This scenario exemplifies what Kingston @Kingston2013 describes as the "full workflow" challenge: successful timetabling systems must support not just initial generation, but manual refinement, publication, and ongoing maintenance @Lindahl2018.

Similar challenges exist in other scheduling domains. Burke et al. @Burke2010 documented comparable disruption patterns in nurse rostering, where sick leave and shift swaps require rapid rescheduling. Ernst et al. @Ernst2004 identified that successful workforce scheduling systems prioritize interactive editing and integration with operational systems—principles equally applicable to educational timetabling. A system that automatically detects conflicts, supports minimally disruptive changes, and integrates with existing institutional tools would significantly reduce the workload of Department of Education staff.

== Engineering Objectives

This thesis addresses the above gap by focusing first on constructing a stable weekly timetable that satisfies real institutional requirements, and then on interactive maintenance with user-driven adaptations and solver assistance. Drawing on lessons from educational timetabling literature, user-centered design principles, and successful scheduling systems in other domains, the work is guided by the following engineering objectives:

#set par(first-line-indent: 0em)
*EO1: Engineer a Stable Weekly Baseline Schedule*

- Design and implement a solver workflow that produces a feasible weekly timetable for real institutional data.
- Encode core operational requirements (conflict-free allocation, required meetings, room feasibility, and pedagogical ordering) so the baseline schedule is usable in practice.
- Achieve practical solve times suitable for planning iterations.

*EO2: Support User-Driven Schedule Maintenance with Solver Assistance*

- Provide a maintenance workflow where planners manually decide concrete moves after publication.
- Integrate optional solver-assisted local repair and recommendations without removing user control.
- Keep updates operationally predictable by limiting unnecessary changes and preserving accepted structure where possible.

*EO3: Represent Curriculum and Constraints in a Formal Data Model*
- Transform heterogeneous institutional sources into a consistent, machine-validated data model.
- Encode constraints and resource semantics required for practical timetable generation and maintenance.

*EO4: Implement Transparent Verification and Acceptance Checks*
- Implement explicit checks for feasibility, timetable quality indicators, and booking consistency.
- Provide diagnostics that support evidence-based acceptance decisions by planners.

*EO5: Build an Integrated User Workflow*
- Build a user-centered workflow across settings, timetable, and checks workspaces.
- Integrate with existing institutional tools, including Google Sheets migration path and Outlook booking workflows.
#set par(first-line-indent: 1em)

The goal is to develop and evaluate an interactive assistant that bridges the gap between academic optimization approaches and operational practice. The system combines: (1) optimization techniques for constructing stable weekly schedules under real institutional constraints, (2) user-driven maintenance with optional solver assistance for post-publication updates, (3) Curriculum-Based Course Timetabling (CB-CTT) model specification and validation, and (4) user-centered workflow integration with existing institutional tools. By addressing baseline schedule construction, human-controlled maintenance, and practical integration together, this work aims to deliver a solution that is both technically sound and practically deployable at Innopolis University's Department of Education.
