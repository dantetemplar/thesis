= Literature Review

This chapter surveys research and systems relevant to timetable optimization, dynamic rescheduling, and interactive scheduling tools. Sources include Google Scholar #footnote[https://scholar.google.com/], ACM Digital Library #footnote[https://dl.acm.org/], arXiv #footnote[https://arxiv.org/], and public blogposts. The review is organized into four key areas: (1) timetabling methods, (2) dynamic rescheduling, (3) user interface and workflow integration, and (4) AI-assisted scheduling.

== Timetabling methods

Timetabling has been extensively studied as a combinatorial optimization problem. Early approaches relied on exact mathematical methods, such as Integer Linear Programming and graph coloring formulations. Due to computational complexity, modern systems often employ metaheuristics: tabu search, simulated annealing, genetic algorithms, ant colony optimization, and others @veenstra2016. Constraint Programming (CP) has emerged as a powerful paradigm, offering expressive modeling of constraints and efficient solving through CP-SAT solvers such as Google OR-Tools. Despite progress, no universal method exists: real-world timetabling instances remain highly heterogeneous, requiring hybrid and tailored solutions @Ceschia_2023.

== Dynamic rescheduling

A less studied but practically critical problem is *rescheduling under disturbances*. Once a timetable is fixed, changes must be incorporated with minimal disruption to students and teachers. This is formalized as the Minimum Perturbation Problem (MPP), which seeks to satisfy new constraints while minimizing the number of altered assignments @veenstra2016. Methods include local search, CP with distance metrics, and multi-objective optimization balancing stability against compactness. Studies of school timetabling under disturbances show that while gaps in student schedules can be reduced by reassignments, such changes must be limited to avoid confusion and excessive workload. This motivates the development of efficient algorithms for timetable repair rather than regeneration.

== User interface and workflow integration

The gap between academic prototypes and practical systems often lies in usability. Commercial products (e.g., aSc Timetables, Untis, Celcat) emphasize drag-and-drop editing, substitution management, and publishing schedules online or to mobile devices. Open-source tools such as UniTime and FET provide flexible constraint modeling and integration into institutional workflows. However, many rely on outdated algorithms. Research indicates that the combination of modern optimization with user-friendly interfaces is essential for adoption @oude-vrielink2019. Integration with widely used platforms (Google Sheets, Outlook) further reduces friction and improves collaboration across departments.

== AI-assisted scheduling

Recent advances in AI, particularly Large Language Models, have opened new opportunities for timetabling. LLMs can serve as natural language interfaces for expressing scheduling changes (e.g., “Move the math lecture to Wednesday morning”) and automatically translating them into formal constraints. Research prototypes (e.g., RAG-DyS) show promising results in combining LLMs with CP solvers for dynamic rescheduling, ensuring minimal deviations from the original schedule @tang2024automatedconversionstaticdynamic. Additionally, recent work such as ReEvo @hyperheuristic2024 demonstrates that LLMs can act as hyper-heuristics: the model itself generates or adapts heuristics for combinatorial optimisation problems via reflective evolution, exploring heuristic space in an automated fashion . Commercial applications have begun experimenting with AI-powered rescheduling assistants capable of real-time conflict resolution and automated notifications @virtosoftware2024.

== Summary

The literature demonstrates that while timetable generation has been deeply explored, the problem of interactive editing and adaptive rescheduling is still underdeveloped. Practical systems often prioritize usability at the cost of algorithmic sophistication, while research prototypes neglect workflow integration. There is clear space for innovation in combining optimization, dynamic repair algorithms, natural language assistance, and integration with everyday tools like Google Sheets and Outlook. This thesis positions itself precisely at this intersection.
