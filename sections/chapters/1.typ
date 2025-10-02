= Introduction

Timetabling in educational institutions is a long-standing and challenging problem. A valid timetable must simultaneously satisfy a variety of hard and soft constraints, such as the availability of teachers, rooms, and student groups, while also considering preferences like minimizing idle time or aligning lectures and tutorials on the same day. The problem is NP-hard, which explains the abundance of heuristic, metaheuristic, and optimization-based approaches proposed in the literature @Ceschia_2023.

In practice, most institutions employ a hybrid process: an initial draft is prepared using software or spreadsheets, and human schedulers manually refine it to meet real-world requirements. However, timetables are rarely static. Once published, they must be updated regularly due to unforeseen events such as teacher illness, changes in preferences, or sudden room reservations for events. Studies report that over 60% of institutions modify at least 10% of lessons after the official schedule is released @coursedog2023. This demonstrates a gap: while much research focuses on generating timetables from scratch, the real-world challenge often lies in *editing and maintaining timetables under changing conditions* @veenstra2016.

== Motivating Example

Imagine a week before classes start, a lecturer falls ill and two major events suddenly block the largest lecture halls. The scheduler must manually reshuffle dozens of sessions in Google Sheets, re-check Outlook bookings, and notify teachers and students. Even small changes can cascade into conflicts: a class moved to another slot collides with a teaching assistant’s own studies, or a group ends up with three long gaps in one day. Such cases occur multiple times every semester at Innopolis University, taking hours of manual work. 

This example illustrates the real challenge: not generating a timetable from scratch, but efficiently adapting it to new conditions with minimal disruption. A system that could automatically detect conflicts, suggest minimally invasive changes, and integrate seamlessly with existing tools would significantly reduce the workload of Department of Education staff.

== Research Questions

This thesis addresses the above gap by focusing on interactive timetable editing and minimally disruptive rescheduling. The research is guided by the following questions:

- How can optimization methods be adapted to efficiently handle timetable modifications while preserving most of the original structure?
- How can natural language interfaces (LLMs) support human schedulers in formulating and applying changes?
- What user interface and workflow integrations are necessary to make such a system truly useful in daily operations?

The goal is to develop and evaluate an interactive assistant that not only supports academic research but also provides real utility to the Department of Education staff at Innopolis University. The assistant will be integrated into existing workflows, operate directly in Google Sheets, and synchronize changes with Microsoft Outlook calendars. By combining optimization techniques, conflict detection, and natural language assistance, this work aims to contribute both scientifically and practically.
