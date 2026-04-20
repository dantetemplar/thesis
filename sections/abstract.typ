#import "/lib.typ": todo

#align(center)[
  = Abstract
]

Academic timetabling is a complex combinatorial optimization problem that must satisfy diverse constraints, such as room availability, teacher schedules, and student group assignments. While much research has focused on generating complete timetables from scratch @Ceschia_2023, real-world practice shows that the greater challenge lies in editing and maintaining timetables after publication. Polls indicate that more than 60% of educational institutions must revise at least 10% of their schedules due to unforeseen disturbances @coursedog2023. Such revisions include teacher illness, room unavailability, or new course requirements, and are often performed manually, consuming significant time and effort.

This thesis addresses two connected tasks: constructing a stable weekly timetable for real institutional constraints and then supporting interactive editing for post-publication maintenance. The proposed system integrates with existing workflows used by the Department of Education at Innopolis University. It provides real-time conflict detection, automated constraint checking, and user-driven schedule adaptation, where planners decide concrete moves and can invoke solver assistance when needed. The implementation combines a Curriculum-Based Course Timetabling (CB-CTT) model, multi-phase CP-SAT optimization, verification checks for conflicts and constraints, and an interactive web interface for settings management and timetable analysis.

The novelty of this work lies in combining state-of-the-art optimization, interactive UI integration, and operational validation in a single practical tool. The system bridges the gap between optimization prototypes, which emphasize algorithms but neglect usability, and commercial solutions, which provide user-friendly interfaces but rely on less transparent optimization models @oude-vrielink2019. Through this work, we demonstrate that blending algorithmic efficiency, practical verification checks, and workflow integration can create a scheduling assistant that is both technically sound and practically valuable.
