= Literature Review

This chapter surveys research and systems relevant to timetable optimization, dynamic rescheduling, and interactive scheduling tools. Sources include Google Scholar #footnote[https://scholar.google.com/], ACM Digital Library #footnote[https://dl.acm.org/], arXiv #footnote[https://arxiv.org/], and public blog posts. The review is organized around six themes: (1) timetabling methods and algorithms, (2) dynamic rescheduling and minimum perturbation, (3) multi-phase optimization and decomposition, (4) user-centered design and interactive timetabling, (5) real-world adoption, integration, and modular curricula, and (6) AI-assisted scheduling support.

== Timetabling methods and algorithms

Educational timetabling has been recognized as a combinatorial optimization problem since the early 1960s @Gotlieb2003. Schaerf's seminal survey @Schaerf1999 established the field's taxonomy, distinguishing between school timetabling, course timetabling, and examination timetabling. The problem's NP-hard nature has driven extensive research into both exact and heuristic approaches.

Early methods focused on graph coloring and integer programming formulations @Burke2007, but scalability limitations led to the dominance of metaheuristics. Lewis @Lewis2007 surveyed metaheuristic techniques including genetic algorithms, simulated annealing, tabu search, and ant colony optimization, demonstrating their effectiveness on benchmark instances. For school timetabling specifically, Pillay @Pillay2014 reviewed over 100 papers, noting that while metaheuristics achieve good solutions, they often lack the transparency and constraint expressiveness required by practitioners.

More recent work has emphasized hybrid approaches. MirHassani and Habibi @MirHassani2011 compared mathematical programming, constraint programming, and metaheuristics, finding that each excels in different problem variants. Kristiansen et al. @Kristiansen2015 developed integer programming models for high school timetabling with strong lower bounds, while Santos et al. @Santos2012 used cut and column generation for class-teacher timetabling. Bettinelli et al. @Bettinelli2015 provided a comprehensive overview of curriculum-based course timetabling, highlighting the importance of modeling flexibility.

The Third International Timetabling Competition @Post2016 demonstrated that no single algorithm dominates across all instances. Ceschia et al. @Ceschia_2023 recently benchmarked state-of-the-art solvers, confirming that real-world timetabling requires instance-specific tuning and hybrid methods. Constraint Programming (CP) with modern CP-SAT solvers (e.g., Google OR-Tools) has emerged as particularly expressive, though computational cost remains a challenge for large instances.

The existing literature on this topic is strong: timetabling is a mature research area with its own typology, competitions, standard formulations, and methodological schools. However, a structural limitation appears at this level. Most classical work measures success by the quality of *initial generation*—building a schedule from scratch—whereas real educational organizations make *maintenance after publication* the central operational task.

== Dynamic rescheduling and the minimum perturbation problem

While initial timetable generation is well-studied, the challenge of *maintaining* timetables under real-world disturbances has received less attention. Veenstra and Vis @veenstra2016 formalized the *Minimum Perturbation Problem (MPP)*, where new constraints (e.g., teacher unavailability, room closures) must be satisfied while minimizing changes to the published schedule. Their empirical study of Dutch schools found that over 60% of institutions modify at least 10% of lessons post-publication, confirming the practical importance of robust rescheduling.

The MPP differs fundamentally from initial generation: stability and minimal disruption take precedence over global optimality. Common approaches include local search restricted to affected lessons, constraint programming with distance metrics penalizing changes, and multi-objective optimization balancing feasibility against perturbation cost. However, research in this area remains limited, with most systems reverting to manual editing or full regeneration.

Kotas et al. @Kotas2020 strengthen this line of work by formulating an ILP model that simultaneously minimizes changes relative to an accepted plan and accounts for faculty preferences. This makes "minimally destructive" correction an explicit optimization criterion rather than an informal design goal. For post-publication maintenance, a globally "better" solution often loses to a locally more stable one, because the cost of change is distributed across students, teachers, and administrative processes. A successful scheduling system should therefore optimize not only the quality of the final plan, but also the cost of transitioning from the old plan to the new one.

Babaei et al. @Babaei2015 surveyed course timetabling approaches and noted that dynamic features (e.g., add/drop periods, instructor changes) are rarely modeled. Lindahl et al. @Lindahl2018 argued for a *strategic view* of timetabling that accounts for the entire lifecycle of a schedule, including maintenance and adaptation. This motivates research into interactive systems supporting incremental edits rather than batch regeneration.

== Multi-phase optimization and decomposition

The base literature already includes integer programming, cut-and-column generation, and curriculum-based course timetabling, but it rarely makes explicit that multi-phase solving can be a substantive research strategy rather than a mere engineering compromise. Burke et al. @Burke2009 show that decomposition, reformulation, and sequential diving into more specific neighbourhoods allow several families of soft constraints to be managed without destroying feasibility or collapsing under computational complexity.

For interactive scheduling assistants, this matters for two reasons. First, a multi-phase architecture aligns with the workflow of building a stable weekly baseline and then locally repairing calendar-level exceptions. Second, it makes the solver more interpretable: when the system proceeds in phases, schedulers can understand which quality layer is currently being optimized and why some trade-offs are acceptable while others are not. Staging thus becomes part of model explainability rather than a purely technical detail.

== User-centered design and interactive timetabling

Despite algorithmic advances, adoption of automated timetabling systems remains limited. Oude Vrielink et al. @oude-vrielink2019 conducted a systematic review of timetabling practices in 52 higher education institutions, finding that most still rely on spreadsheets and manual coordination. Key barriers include: (1) lack of integration with existing workflows, (2) inflexibility in constraint modeling, (3) poor transparency in how solutions are generated, and (4) difficulty in making small manual adjustments.

User-centered design principles @Norman2013 emphasize that systems must fit users' mental models and workflows. Shneiderman's direct manipulation paradigm @Shneiderman1983 advocates for immediate visual feedback, reversible actions, and user control—principles rarely applied in academic timetabling prototypes. Commercial systems (e.g., aSc Timetables, Untis, Celcat) prioritize usability features such as drag-and-drop editing, visual conflict highlighting, and undo/redo, often at the expense of algorithmic sophistication.

A key gap in many reviews is the treatment of interactivity as a theoretical mode of solving rather than as a UX feature. Müller and Barták @MullerBartak2001 describe interactive timetabling as a setting in which the user observes the assignment process and can intervene in it, making black-box automation methodologically weaker than a transparent interactive scheme. In educational scheduling systems, the interface is not merely a wrapper around the solver; it participates in defining what counts as a quality solution. Drag-and-drop editing, visual conflict detection, reversible actions, and recommendation-based repair are therefore not cosmetic additions but operationalizations of solution quality.

Dimopoulou and Miliotis @Dimopoulou2009 described the implementation of a university timetabling system in Greece, noting that adoption required extensive customization, training, and ongoing support. Their experience highlights that technical feasibility is insufficient; systems must align with institutional culture and administrative processes. Müller and Murray @Muller2009 developed the UniTime system with a focus on collaborative editing, allowing multiple stakeholders to contribute constraints and view the evolving schedule in real-time.

Kingston @Kingston2013 emphasized that successful timetabling software must support the full workflow: initial generation, manual refinement, publication, and ongoing maintenance. He argued that purely automated approaches fail because real-world constraints are often implicit, context-dependent, and negotiable. Interactive systems that augment rather than replace human schedulers are more likely to succeed.

== Real-world adoption, integration, and modular curricula

A critical gap exists between academic benchmarks and operational deployment. The International Timetabling Competition instances @Post2016 are valuable for algorithmic comparison but abstract away many real-world complexities: integration with student information systems, calendar synchronization, stakeholder communication, and regulatory compliance.

Lindahl et al. @Lindahl2018 studied university timetabling from a strategic perspective, identifying integration with institutional systems as a top priority. Modern institutions use diverse platforms: Google Workspace for collaboration, Microsoft Outlook for calendaring, student information systems for enrollment data, and room booking systems for space management. A timetabling solution that requires manual data entry or exports static PDFs cannot compete with the flexibility of spreadsheets.

Coursedog @coursedog2023, a commercial scheduling platform, identified four major challenges with Excel-based scheduling: (1) difficulty in detecting conflicts, (2) lack of version control, (3) inability to propagate changes across multiple views, and (4) poor support for collaboration. Their solution emphasizes cloud-based editing, automatic conflict detection, and integration with campus systems via APIs. This underscores the shift from standalone optimization tools to *integrated scheduling platforms*. Such vendor literature is useful as empirical background for deployment problems, but the theoretical core of this review rests primarily on academic sources.

Recent industry trends show adoption of platforms offering: calendar synchronization (e.g., Google Calendar, Outlook), notifications via email/SMS, mobile access for students and faculty, and integration with learning management systems (e.g., Canvas, Moodle). These features are often more valued by end-users than algorithmic optimality, suggesting that usability and integration are prerequisites for adoption.

Beyond integration, the educational environment itself is becoming more complex. Ruiz-Torrubiano et al. @RuizTorrubiano2024 show that as educational programs become more modular, the number of electives grows, and students gain more freedom of choice, scheduling changes not only in scale but in structure. Demand and supply of teaching events become more tightly coupled across overlapping trajectories and mixed groups, so a weekly template no longer fully describes real workload. Part of timetabling complexity is therefore generated not by the solver but by the curricular architecture of the program itself. Scheduling research must account not only for constraint sets but also for curricular design, modularity, choice configurations, and the associated enrolment uncertainty.

== Insights from broader scheduling domains

Educational timetabling shares structural similarities with scheduling problems in healthcare, workforce management, and transportation. Cross-domain insights can inform system design and algorithmic choices.

Burke et al. @Burke2010 surveyed nurse rostering, a problem involving shift assignments, skill requirements, and regulatory constraints. Like educational timetabling, nurse rostering exhibits high variability, frequent disruptions (e.g., sick leave), and the need for rapid rescheduling. Successful systems emphasize interactive editing, allowing managers to manually adjust generated rosters and propagate changes automatically.

Ernst et al. @Ernst2004 reviewed staff scheduling across industries, identifying common success factors: (1) constraint flexibility, (2) what-if scenario analysis, (3) integration with payroll and HR systems, and (4) mobile access. Van den Bergh et al. @VandenBergh2013 extended this review, noting that the most successful systems combine optimization with decision support, providing users with multiple options and trade-off analysis rather than a single "optimal" solution.

These parallels suggest that educational timetabling systems should adopt similar principles: support for interactive editing, integration with institutional systems, transparency in constraint satisfaction, and decision support rather than full automation. The emphasis on usability and workflow integration in workforce scheduling provides a model for improving timetabling adoption in education.

== AI-assisted scheduling and adaptive optimization support

Recent advances in AI, particularly Large Language Models (LLMs), have opened new opportunities for timetabling support. In current practice, these opportunities are strongest for auxiliary decision support, adaptation heuristics, and iterative optimization guidance rather than as autonomous replacements for formal solvers.

Tang et al. @tang2024automatedconversionstaticdynamic developed RAG-DyS, which combines retrieval-augmented generation with constraint programming solvers for dynamic rescheduling. Their results show that AI-assisted components can improve the responsiveness of schedule adaptation pipelines, though scalability to complex institutions remains an open question.

Ye et al. @hyperheuristic2024 demonstrated that LLMs can act as *hyper-heuristics*, generating and refining optimization heuristics via reflective evolution. Their ReEvo framework uses LLMs to explore heuristic design spaces for combinatorial problems, including scheduling. While not yet applied to full institutional educational timetabling workflows, this suggests potential for AI-driven algorithm customization tailored to specific contexts.

Wu et al. @Wu2025 extend this direction toward a recommendation-oriented, digital-twin-driven approach in which the system ranks feasible alternatives by occupancy, mobility, and user-centric factors rather than returning a single optimum. A new compromise is emerging in the literature: hard constraints and correctness guarantees remain the domain of formal optimization, while the AI layer increasingly handles explanation generation, option prioritization, what-if exploration, and reduction of user cognitive load. For an interactive assistant, this balance is especially productive: the solver ensures correctness and feasibility, while AI and the interface help navigate the space of admissible changes.

Commercial applications have begun experimenting with AI-powered scheduling assistants. Virtosoftware @virtosoftware2024 describes an AI scheduler for schools that automatically detects conflicts, suggests resolutions, and sends notifications to affected parties. While details are proprietary, such tools illustrate industry movement toward intelligent, semi-automated scheduling support.

The integration of AI components with optimization solvers remains an active research area. Open questions include reliability, verifiability, and how to balance user control with automation in operational scheduling.

== Summary

The literature demonstrates that while timetable generation algorithms have matured significantly, interactive editing, adaptive rescheduling, and deployment-oriented integration remain comparatively underdeveloped. Academic research often neglects usability, integration, and the full scheduling lifecycle, while commercial systems prioritize user experience at the expense of algorithmic transparency.

At the intersection of classical optimization, minimum perturbation, interactive timetabling, workflow integration, and AI-assisted recommendation, a distinct research niche emerges. The field remains split between benchmark-driven algorithmics and deployment-oriented pragmatics; minimum perturbation is studied less thoroughly than initial generation; interactivity is more often described as a desirable feature than as a theoretical mode of solving; and the AI layer remains more prospective than standardized practice.

Key insights from this review include:
- The necessity of constructing a stable weekly baseline under real constraints before applying user-driven maintenance with optional solver-assisted local adaptation.
- Minimum perturbation as an explicit optimization criterion, not only an informal design preference.
- Multi-phase decomposition as a way to balance feasibility, quality, and explainability.
- The importance of user-centered design and interactive timetabling: direct manipulation, transparency, and reversibility as part of solution quality.
- The critical role of integration with existing platforms (Google Sheets, Outlook, student information systems) in driving adoption.
- Growing complexity from modular curricula and elective-heavy programs.
- Lessons from workforce and healthcare scheduling emphasizing decision support over full automation.
- Emerging potential of AI-assisted methods for adaptive scheduling support, recommendation, and heuristic tuning.

Together, these findings define the design requirements used in the next chapter: stable weekly schedule construction, user-driven maintenance with optional solver assistance, transparent constraints and verification checks, user-centered interaction, and integration with institutional workflows.
